import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cine_devinette/l10n/app_localizations.dart';
import 'package:cine_devinette/screens/settings_screen.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/cloud_sync_service.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/progress_leaderboard.dart';
import 'package:cine_devinette/services/save_service.dart';

/// Compte Google simulé : lié ou non, suppression qui répond [next].
class _FakeCloudSync extends CloudSyncService {
  bool linked;
  AccountDeletionReport next;
  int deleteCalls = 0;
  _FakeCloudSync({this.linked = true, this.next = const AccountDeletionReport(AccountDeletionOutcome.deleted)});

  @override
  bool get isLinked => linked;

  @override
  String? get linkedEmail => linked ? 'bob@example.com' : null;

  @override
  Future<AccountDeletionReport> deleteAccount({Future<bool> Function()? leaveLeaderboard}) async {
    deleteCalls++;
    // Comme le vrai : le retrait du classement passe avant le compte.
    if (leaveLeaderboard != null) await leaveLeaderboard();
    if (next.accountDeleted) linked = false;
    return next;
  }
}

/// Classement en mémoire : note les suppressions.
class _Backend implements ProgressLeaderboardBackend {
  final List<String> deletes = [];
  @override
  bool get supported => true;
  @override
  String? get uid => 'moi';
  @override
  Future<bool?> fetchEnabled() async => true;
  @override
  Future<void> writeEntry({required String lang, required String pseudo, required int score}) async {}
  @override
  Future<void> deleteEntry(String lang) async => deletes.add(lang);
  @override
  Future<({String pseudo, int score})?> fetchMine(String lang) async => null;
  @override
  Future<ProgressBoardData> fetchBoard({required String lang, required int? myScore}) async =>
      const ProgressBoardData(top: [], above: [], total: 0, myRank: null);
}

Future<void> _pump(WidgetTester tester,
    {CloudSyncService? cloudSync, ProgressLeaderboard? leaderboard, String locale = 'fr'}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final saveService = SaveService();
  final settings = AppSettings(saveService: saveService);
  if (locale != settings.locale) settings.setLocale(locale);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(
          value: GameState(adService: AdService(), saveService: saveService, settings: settings)),
      Provider.value(value: saveService),
      Provider<CloudSyncService>.value(value: cloudSync ?? CloudSyncService()),
      if (leaderboard != null) ChangeNotifierProvider<ProgressLeaderboard>.value(value: leaderboard),
    ],
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SettingsScreen()),
    ),
  ));
  await tester.pump();
}

const _deleteFr = 'Supprimer ma sauvegarde et me déconnecter';
const _keepsWorkingFr = 'Le jeu continue de fonctionner normalement et ta partie reste sur ce téléphone.';

Future<void> _tapDeleteAndConfirm(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey('settingsDeleteAccount')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('settingsDeleteAccount')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('settingsDeleteAccountConfirm')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  testWidgets('Android : la sauvegarde Google est proposée', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await _pump(tester);
    expect(find.text('🔗 Sauvegarder avec Google'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('iPhone : pas de connexion Google (règle 4.8 d\'Apple)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await _pump(tester);
    expect(find.text('🔗 Sauvegarder avec Google'), findsNothing);
    expect(find.textContaining('Google'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  group('suppression du compte (règle Google Play)', () {
    testWidgets('compte non lié : pas de bouton de suppression, lien vers la page web', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await _pump(tester, cloudSync: _FakeCloudSync(linked: false));
      expect(find.text(_deleteFr), findsNothing);
      expect(find.text('Supprimer mon compte et mes données (page web)'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('compte lié : bouton visible ; annuler ne supprime rien', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final cloud = _FakeCloudSync();
      await _pump(tester, cloudSync: cloud);
      expect(find.text(_deleteFr), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('settingsDeleteAccount')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settingsDeleteAccount')));
      await tester.pumpAndSettle();
      expect(find.text('⚠️ Supprimer ta sauvegarde ?'), findsOneWidget);
      expect(find.textContaining('ton compte lié à Google (bob@example.com)'), findsOneWidget);
      expect(find.textContaining(_keepsWorkingFr), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('settingsDeleteAccountCancel')));
      await tester.pumpAndSettle();
      expect(cloud.deleteCalls, 0);
      expect(find.text(_deleteFr), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('confirmé : retrait du classement, compte supprimé, retour à « Sauvegarder avec Google »',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final backend = _Backend();
      final lb = ProgressLeaderboard(
        backend: backend,
        saveService: SaveService(),
        scoreSource: () => 0,
        langSource: () => 'fr',
        pseudoSource: () => '#123456',
      );
      final cloud = _FakeCloudSync();
      await _pump(tester, cloudSync: cloud, leaderboard: lb);
      await _tapDeleteAndConfirm(tester);

      expect(cloud.deleteCalls, 1);
      expect(backend.deletes.toSet(), {'fr', 'en'}, reason: 'entrée du classement retirée dans les deux langues');
      expect(find.text('✅ C\'est fait : ta sauvegarde en ligne et ton compte sont supprimés. '
          'Ta partie reste sur ce téléphone.'), findsOneWidget);
      expect(find.text(_deleteFr), findsNothing);
      expect(find.text('🔗 Sauvegarder avec Google'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Google n\'a pas reconfirmé : le joueur est prévenu, avec la page web', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final cloud = _FakeCloudSync(next: const AccountDeletionReport(AccountDeletionOutcome.needsRecentLogin));
      await _pump(tester, cloudSync: cloud);
      await _tapDeleteAndConfirm(tester);

      expect(find.text('⚠️ Confirmation de Google nécessaire'), findsOneWidget);
      expect(find.byKey(const ValueKey('settingsDeleteAccountOpenPage')), findsOneWidget);
      await tester.tap(find.text('COMPRIS'));
      await tester.pumpAndSettle();
      expect(find.text(_deleteFr), findsOneWidget, reason: 'compte toujours lié : on peut réessayer');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('échec (hors ligne) et suppression incomplète : message adapté', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final cloud = _FakeCloudSync(next: const AccountDeletionReport(AccountDeletionOutcome.failed));
      await _pump(tester, cloudSync: cloud);
      await _tapDeleteAndConfirm(tester);
      expect(find.text('⚠️ Suppression impossible'), findsOneWidget);
      await tester.tap(find.text('COMPRIS'));
      await tester.pumpAndSettle();

      cloud.next = const AccountDeletionReport(AccountDeletionOutcome.deletedWithLeftovers, ['multiplayer_players']);
      await _tapDeleteAndConfirm(tester);
      expect(find.text('Compte supprimé'), findsOneWidget);
      expect(find.byKey(const ValueKey('settingsDeleteAccountOpenPage')), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('anglais : textes du bouton et de la confirmation', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await _pump(tester, cloudSync: _FakeCloudSync(), locale: 'en');
      expect(find.text('Delete my backup and sign out'), findsOneWidget);
      expect(find.text('Delete my account and data (web page)'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('settingsDeleteAccount')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settingsDeleteAccount')));
      await tester.pumpAndSettle();
      expect(find.text('⚠️ Delete your backup?'), findsOneWidget);
      expect(find.textContaining('The game keeps working normally and your progress stays on this phone.'),
          findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('iPhone : jamais de bouton de suppression Google, le lien web reste', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await _pump(tester, cloudSync: _FakeCloudSync());
      expect(find.text(_deleteFr), findsNothing);
      expect(find.text('Supprimer mon compte et mes données (page web)'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    test('adresse de la page web : français et anglais', () {
      expect(accountDeletionPageUrl('fr'), 'https://lnaappgame.github.io/plottwisted/suppression/');
      expect(accountDeletionPageUrl('en'), 'https://lnaappgame.github.io/plottwisted/en/suppression/');
    });
  });
}
