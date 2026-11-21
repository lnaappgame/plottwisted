import 'dart:async';

import 'package:flutter/widgets.dart';

/// Règle C7 du studio (`notes/studio/mesure-commune-spec.md`), reprise du Clos
/// (commits 3845025 et d17a7b3) : le moment de la fenêtre de consentement.
///
/// Au lancement, la mise à jour UMP se fait sans fenêtre et le statut est lu.
/// Statut déjà réglé (accord donné, ou pays où rien n'est demandé) : la mesure
/// et les pubs démarrent tout de suite. Sinon la fenêtre s'ouvre à la première
/// des trois choses suivantes :
///  - la première énigme réussie, à la sortie de son écran de réussite ;
///  - la première vidéo demandée (la vidéo se charge après la réponse) ;
///  - le secours : [kConsentFallbackSeconds] secondes de jeu au premier plan.
///
/// Sur iPhone, la demande de suivi (ATT) fait partie du même parcours UMP :
/// elle vient donc après le formulaire, comme avant.

/// Secours de la règle C7, en secondes de jeu au premier plan. PT n'utilise
/// pas Remote Config : constante, à régler sur le p90 du temps de la première
/// réussite (`tutorial_complete {seconds}`, `consent_prompt {seconds}`).
const int kConsentFallbackSeconds = 180;

/// Ce qui a ouvert la fenêtre : paramètre `trigger` de `consent_prompt`.
const kConsentAlreadySet = 'already_set',
    kConsentFirstSuccess = 'first_success',
    kConsentVideo = 'video',
    kConsentFallback = 'fallback';

/// Temps de jeu au premier plan, en secondes : une appli en arrière-plan
/// n'avance pas.
class ForegroundClock with WidgetsBindingObserver {
  int _seconds = 0;
  bool _foreground = true;
  Timer? _timer;

  int get seconds => _seconds;

  /// Celle de l'appli ; les tests en posent une neuve.
  static ForegroundClock instance = ForegroundClock();

  void start() {
    if (_timer != null) return;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_foreground) _seconds++;
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;
  }
}

/// La porte du consentement : une vidéo demandée avant la réponse ouvre la
/// fenêtre tout de suite ([askNow]), puis attend que la réponse soit traitée
/// ([decided]) avant de charger la vidéo. La première réussite l'ouvre aussi
/// ([firstSuccess]).
class ConsentGate {
  ConsentGate();

  /// Celle de l'appli ; les tests en posent une neuve.
  static ConsentGate instance = ConsentGate();

  bool _started = false;
  final Completer<void> _asked = Completer<void>();
  final Completer<void> _success = Completer<void>();
  final Completer<void> _decided = Completer<void>();

  /// Le consentement est en route ([consentFlow] lancé) et sa réponse n'est
  /// pas encore traitée.
  bool get waiting => _started && !_decided.isCompleted;
  bool get decidedAlready => _decided.isCompleted;
  Future<void> get asked => _asked.future;
  Future<void> get success => _success.future;
  Future<void> get decided => _decided.future;

  /// Une vidéo est demandée : ouvre la fenêtre maintenant.
  void askNow() {
    if (!_asked.isCompleted) _asked.complete();
  }

  /// Une énigme vient d'être réussie et son écran de réussite quitté.
  void firstSuccess() {
    if (!_success.isCompleted) _success.complete();
  }
}

/// Renvoie ce qui a ouvert la fenêtre, pour `consent_prompt {trigger}`.
///
/// [alreadySucceeded] : le joueur a déjà réussi une énigme (joueur existant) ;
/// [playSeconds] : temps de jeu au premier plan ; [fallbackSeconds] : secours
/// en secondes de jeu ; [fallback] : un délai d'horloge à la place (tests).
Future<String> consentMoment({
  required ConsentGate gate,
  required int Function() playSeconds,
  int fallbackSeconds = kConsentFallbackSeconds,
  bool alreadySucceeded = false,
  Duration? fallback,
  Duration pollEvery = const Duration(seconds: 1),
}) async {
  if (alreadySucceeded) return kConsentFirstSuccess;
  final ready = Completer<String>();
  Timer? poll;
  if (fallback == null) {
    final start = playSeconds();
    poll = Timer.periodic(pollEvery, (_) {
      if (playSeconds() - start >= fallbackSeconds && !ready.isCompleted) ready.complete(kConsentFallback);
    });
  }
  try {
    return await Future.any<String>([
      ready.future,
      gate.success.then((_) => kConsentFirstSuccess),
      gate.asked.then((_) => kConsentVideo),
      if (fallback != null) Future<String>.delayed(fallback, () => kConsentFallback),
    ]);
  } finally {
    poll?.cancel();
  }
}

/// Règle C7 en entier. Dans tous les cas, la porte est marquée « réponse
/// traitée » à la fin.
///
/// [settled] lit le statut UMP sans fenêtre ([settledTimeout] au plus) ;
/// [finish] ouvre la fenêtre si besoin, puis démarre la mesure et les pubs ;
/// [log] reçoit `consent_prompt {trigger, seconds}` juste avant la fenêtre.
Future<void> consentFlow({
  required Future<bool> Function() settled,
  required Future<void> Function() finish,
  required void Function(String trigger, int seconds) log,
  required int Function() playSeconds,
  ConsentGate? gate,
  bool alreadySucceeded = false,
  int fallbackSeconds = kConsentFallbackSeconds,
  Duration settledTimeout = const Duration(seconds: 5),
  Duration pollEvery = const Duration(seconds: 1),
}) async {
  final g = gate ?? ConsentGate.instance;
  g._started = true;
  try {
    var ok = false;
    try {
      ok = await Future<bool>.sync(settled)
          .timeout(settledTimeout, onTimeout: () => false)
          .catchError((Object _) => false);
    } catch (_) {}
    final trigger = ok
        ? kConsentAlreadySet
        : await consentMoment(
            gate: g,
            playSeconds: playSeconds,
            fallbackSeconds: fallbackSeconds,
            alreadySucceeded: alreadySucceeded,
            pollEvery: pollEvery,
          );
    log(trigger, playSeconds());
    await finish();
  } finally {
    if (!g._decided.isCompleted) g._decided.complete();
  }
}
