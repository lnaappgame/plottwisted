import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/defis_data.dart';
import '../models/defi.dart';
import 'analytics_service.dart';
import 'defi_service.dart';
import 'save_service.dart';
import 'streak_state.dart';

/// État du mode "Défi du jour" : un "commun" officiel par jour (ancré GMT,
/// propre au parcours de ce joueur — voir defiIndexFor()), des
/// cases-réponses toutes visibles dès le début, un indice dédié par case
/// révélé un par un. Bonne réponse = la case tapée
/// flashe en vert puis disparaît ; mauvaise réponse = pénalité de 5s, la
/// case tapée flashe en rouge et la vraie bonne réponse clignote avant de
/// disparaître elle aussi (un indice raté n'est jamais rejoué). Le joueur
/// peut, via une pub, rejouer le même défi (le meilleur temps est conservé)
/// ou piocher un autre commun au hasard parmi ceux jamais encore joués.
/// Aucun classement : juste le meilleur temps personnel par commun, stocké
/// localement.
class DefiState extends ChangeNotifier {
  final SaveService saveService;
  final AnalyticsService analytics;
  // Optionnel (contrairement à saveService/analytics) : câblé depuis
  // main.dart, jamais depuis les tests, qui n'ont pas besoin de la série.
  StreakState? streakState;
  final Random _rng = Random();
  DefiState({required this.saveService, AnalyticsService? analytics}) : analytics = analytics ?? AnalyticsService();

  Timer? _saveDebounce;
  bool _restoring = false;

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (_restoring) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), flushSave);
  }

  Future<void> flushSave() async {
    _saveDebounce?.cancel();
    await saveService.saveDefi(toJson());
  }

  // ─── Défi officiel du jour (ancré GMT, propre à ce joueur — voir
  // defiIndexFor()) ───
  int currentIndex = -1;
  DateTime? currentDayStart;

  Defi get defiDuJour => kDefis[currentIndex.clamp(0, kDefis.length - 1)];

  /// À appeler à chaque ouverture de l'écran : détecte un changement de jour
  /// GMT et met à jour le défi officiel en conséquence. [firstLaunchDay] est
  /// l'ancrage personnel de ce joueur (voir AppSettings.firstLaunchDay) —
  /// jamais une date globale partagée entre joueurs.
  void ensureFresh(DateTime firstLaunchDay) {
    final now = DateTime.now();
    final dayStart = defiDayStart(now);
    final idx = defiIndexFor(now, firstLaunchDay);
    if (currentIndex != idx || currentDayStart != dayStart) {
      currentIndex = idx;
      currentDayStart = dayStart;
    }
    notifyListeners();
  }

  // ─── Historique local : communs déjà joués (jamais repiochés en bonus) et
  // meilleur temps personnel par commun (réel + pénalités, en secondes). ───
  List<String> playedDefiIds = [];
  Map<String, int> bestTimes = {};

  int? bestTimeFor(String defiId) => bestTimes[defiId];

  /// Un commun jamais joué, tiré au hasard parmi ceux qui restent (hors
  /// défi officiel du jour, accessible directement sans pub). Null si tout
  /// le contenu disponible a déjà été joué.
  Defi? piocherBonus() {
    final candidates = kDefis.where((d) => d.id != defiDuJour.id && !playedDefiIds.contains(d.id)).toList();
    if (candidates.isEmpty) return null;
    return candidates[_rng.nextInt(candidates.length)];
  }

  bool get peutPiocherBonus =>
      kDefis.any((d) => d.id != defiDuJour.id && !playedDefiIds.contains(d.id));

  // ─── Partie en cours (non persistée, comme le reste du jeu : redémarre
  // "propre" si l'app est fermée en cours de route) ───
  Defi? activeDefi;
  bool isBonus = false;
  // Ordre d'affichage des cases, mélangé : indices dans defi.cases (et non
  // les textes de réponse eux-mêmes, qui pourraient en théorie se répéter
  // dans un même défi — identifier par index évite tout risque de collision).
  List<int> displayOrder = [];
  final Set<int> hiddenCaseIndices = {};
  int currentCaseIndex = 0;
  DateTime? startTime;
  int penaltySeconds = 0;
  bool solved = false;
  int? realSeconds;
  int? totalSeconds;
  bool? isNewBest;

  // ─── Retour visuel après un tap (1 seconde) : la case tapée passe en
  // vert (bonne réponse) ou rouge (mauvaise réponse) ; en cas d'erreur, la
  // vraie bonne réponse clignote ailleurs sur le plateau pour la montrer au
  // joueur. Dans les deux cas, la case de l'indice résolu disparaît à la fin
  // de cette seconde. Un nouveau tap pendant ce court délai ne reste jamais
  // bloqué : il finalise d'abord immédiatement le retour visuel précédent
  // (la case correspondante disparaît sans attendre), pour ne jamais casser
  // le rythme de jeu.
  int? feedbackCaseIndex; // case tapée, pour le flash vert/rouge
  bool? feedbackCorrect;
  int? revealCaseIndex; // bonne case à faire clignoter (si le joueur s'est trompé)
  int? _pendingResolvedIndex; // case à masquer quand le délai se termine
  Timer? _feedbackTimer;

  DefiCase? get indiceActuel {
    final defi = activeDefi;
    if (defi == null || currentCaseIndex >= defi.cases.length) return null;
    return defi.cases[currentCaseIndex];
  }

  bool isCaseHidden(int index) => hiddenCaseIndices.contains(index);

  /// Démarre (ou relance) un défi — [bonus] indique s'il s'agit d'un commun
  /// piloché aléatoirement plutôt que du défi officiel du jour.
  void startDefi(Defi defi, {required bool bonus}) {
    _feedbackTimer?.cancel();
    activeDefi = defi;
    isBonus = bonus;
    displayOrder = List.generate(defi.cases.length, (i) => i)..shuffle(_rng);
    hiddenCaseIndices.clear();
    currentCaseIndex = 0;
    penaltySeconds = 0;
    solved = false;
    realSeconds = null;
    totalSeconds = null;
    isNewBest = null;
    feedbackCaseIndex = null;
    feedbackCorrect = null;
    revealCaseIndex = null;
    _pendingResolvedIndex = null;
    startTime = DateTime.now();
    notifyListeners();
  }

  /// Le joueur tape sur une case-réponse. Bonne réponse pour l'indice
  /// courant → la case tapée flashe en vert. Mauvaise réponse → pénalité de
  /// 5s, la case tapée flashe en rouge et la vraie bonne réponse clignote.
  /// Dans les deux cas, l'indice suivant s'affiche tout de suite, et la case
  /// de l'indice résolu disparaît après 1 seconde (un indice raté n'est
  /// jamais rejoué).
  void onCaseTapped(int tappedIndex) {
    final defi = activeDefi;
    if (defi == null || solved) return;
    if (currentCaseIndex >= defi.cases.length) return;
    if (hiddenCaseIndices.contains(tappedIndex)) return;

    _resolvePendingFeedback(); // finalise sans attendre le tap précédent, s'il y en a un

    final estCorrect = tappedIndex == currentCaseIndex;
    feedbackCaseIndex = tappedIndex;
    feedbackCorrect = estCorrect;
    revealCaseIndex = estCorrect ? null : currentCaseIndex;
    _pendingResolvedIndex = currentCaseIndex;
    if (!estCorrect) penaltySeconds += 5;
    currentCaseIndex++;
    notifyListeners();

    _feedbackTimer = Timer(const Duration(seconds: 1), _resolvePendingFeedback);
  }

  void _resolvePendingFeedback() {
    _feedbackTimer?.cancel();
    final resolved = _pendingResolvedIndex;
    if (resolved == null) return;
    hiddenCaseIndices.add(resolved);
    feedbackCaseIndex = null;
    feedbackCorrect = null;
    revealCaseIndex = null;
    _pendingResolvedIndex = null;
    final defi = activeDefi;
    if (defi != null && !solved && currentCaseIndex >= defi.cases.length) {
      _finish();
    }
    notifyListeners();
  }

  void _finish() {
    solved = true;
    final real = DateTime.now().difference(startTime!).inSeconds;
    realSeconds = real;
    totalSeconds = real + penaltySeconds;

    final id = activeDefi!.id;
    final prevBest = bestTimes[id];
    isNewBest = prevBest == null || totalSeconds! < prevBest;
    if (isNewBest!) bestTimes[id] = totalSeconds!;
    if (!playedDefiIds.contains(id)) playedDefiIds = [...playedDefiIds, id];
    analytics.logDefiCompleted(bonus: isBonus, seconds: totalSeconds!);
    streakState?.recordAction();
  }

  // ─── Persistance (uniquement l'historique — la partie en cours n'est pas
  // conservée, comme pour le reste du jeu) ───

  Map<String, dynamic> toJson() => {
        'currentIndex': currentIndex,
        'currentDayStart': currentDayStart?.toIso8601String(),
        'playedDefiIds': playedDefiIds,
        'bestTimes': bestTimes,
      };

  Future<void> restore() async {
    final data = await saveService.loadDefi();
    if (data == null) return;
    _restoring = true;
    currentIndex = data['currentIndex'] as int? ?? -1;
    final ds = data['currentDayStart'] as String?;
    currentDayStart = ds != null ? DateTime.tryParse(ds) : null;
    playedDefiIds = (data['playedDefiIds'] as List?)?.cast<String>() ?? [];
    final bt = data['bestTimes'] as Map?;
    bestTimes = bt != null ? bt.map((k, v) => MapEntry(k as String, v as int)) : {};
    _restoring = false;
  }
}
