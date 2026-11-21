// Reprise au premier plan (1.0.16) : les rappels sont annulés puis reposés
// (mêmes identifiants, sans en créer de nouveaux) ; un rappel désactivé ou pas
// encore armé (tutoriel) n'est pas recréé.
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/advent_calendar.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/notification_service.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotifications extends NotificationService {
  final List<String> calls = [];
  bool enabled = true;
  bool grant = true;

  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => grant;
  @override
  Future<bool> notificationsEnabled() async => enabled;
  @override
  Future<void> cancelReminder(int id) async => calls.add('cancel:$id');
  @override
  Future<void> scheduleDailyDefiReminder({int heure = 18, String locale = 'fr'}) async => calls.add('defi');
  @override
  Future<void> scheduleWeeklyEnigmeReminder({int heure = 9, String locale = 'fr'}) async => calls.add('enigme');
  @override
  Future<void> scheduleAdventReminders(Map<int, DateTime> times, {String locale = 'fr'}) async =>
      calls.add('advent:${times.length}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late AdventCalendar advent;
  setUp(() {
    final save = SaveService();
    final game = GameState(adService: AdService(), saveService: save, settings: AppSettings(saveService: save));
    advent = game.advent;
  });

  test('la reprise annule puis repose les mêmes rappels', () async {
    final n = _FakeNotifications();
    await n.askAndSchedule(locale: 'fr', advent: advent);
    n.calls.clear();
    await n.refreshOnResume(locale: 'fr', advent: advent);
    expect(n.calls.take(2), ['cancel:1', 'cancel:2']);
    final firstSchedule = n.calls.indexWhere((c) => !c.startsWith('cancel'));
    expect(n.calls.sublist(firstSchedule).take(2), ['defi', 'enigme']);
    expect(n.calls.last, startsWith('advent:'));
    // Chaque annulation précède les poses.
    expect(n.calls.lastIndexWhere((c) => c.startsWith('cancel')), lessThan(firstSchedule));
  });

  test('rappels coupés dans les réglages du téléphone : rien n\'est recréé', () async {
    final n = _FakeNotifications();
    await n.askAndSchedule(locale: 'fr', advent: advent);
    n.calls.clear();
    n.enabled = false;
    await n.refreshOnResume(locale: 'fr', advent: advent);
    expect(n.calls, isEmpty);
    // Et même s'ils sont rallumés plus tard, la reprise ne les arme pas d'elle-même.
    n.enabled = true;
    await n.refreshOnResume(locale: 'fr', advent: advent);
    expect(n.calls, isEmpty);
  });

  test('nouveau joueur avant la fin du tutoriel (pas armé) : aucune reprogrammation', () async {
    final n = _FakeNotifications();
    await n.refreshOnResume(locale: 'fr', advent: advent);
    expect(n.calls, isEmpty);
  });

  test('permission refusée : jamais armé, jamais de rappel', () async {
    final n = _FakeNotifications()..grant = false;
    await n.askAndSchedule(locale: 'fr', advent: advent);
    await n.refreshOnResume(locale: 'fr', advent: advent);
    expect(n.calls, isEmpty);
  });
}
