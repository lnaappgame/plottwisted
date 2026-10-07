import 'package:flutter/foundation.dart';
import 'save_service.dart';

/// Suivi de la série de jours consécutifs joués — indépendant du contenu
/// (jeu principal, Défi du jour, L'énigme de la semaine, Multijoueur
/// comptent tous pour la même série).
///
/// Le calendrier de série et ses récompenses ont été retirés pour être
/// repensés : seul le compteur reste, invisible pour le joueur, afin que la
/// future version puisse repartir des séries en cours. [onDayCounted] est
/// câblé au démarrage (main.dart) pour la demande d'avis du store.
class StreakState extends ChangeNotifier {
  final SaveService saveService;
  StreakState({required this.saveService});

  /// Appelé avec la série à jour, une fois par jour, juste après le premier
  /// [recordAction] de la journée.
  void Function(int currentStreak)? onDayCounted;

  int currentStreak = 0;
  DateTime? lastActionDay;

  bool _restoring = false;

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (!_restoring) saveService.saveStreak(toJson());
  }

  DateTime _utcDate(DateTime now) {
    final u = now.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// À appeler dès qu'une action significative vient d'être accomplie
  /// (niveau/défi/énigme/match terminé). Incrémente la série si c'est le
  /// jour consécutif suivant, la réinitialise à 1 si un jour a été sauté,
  /// ne fait rien si une action a déjà été comptée aujourd'hui (une seule
  /// incrémentation par jour, quel que soit le nombre d'actions).
  void recordAction() {
    final today = _utcDate(DateTime.now());
    if (lastActionDay != null && _sameDay(lastActionDay!, today)) return;

    final hier = today.subtract(const Duration(days: 1));
    currentStreak = (lastActionDay != null && _sameDay(lastActionDay!, hier)) ? currentStreak + 1 : 1;
    lastActionDay = today;
    onDayCounted?.call(currentStreak);
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'lastActionDay': lastActionDay?.toIso8601String(),
      };

  Future<void> restore() async {
    final data = await saveService.loadStreak();
    if (data == null) return;
    _restoring = true;
    currentStreak = data['currentStreak'] as int? ?? 0;
    final lad = data['lastActionDay'] as String?;
    lastActionDay = lad != null ? DateTime.tryParse(lad) : null;
    _restoring = false;
  }
}
