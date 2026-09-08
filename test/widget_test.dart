import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'fake_video_player_platform.dart';
import 'package:cine_devinette/main.dart';
import 'package:cine_devinette/services/ad_service.dart';
import 'package:cine_devinette/services/app_settings.dart';
import 'package:cine_devinette/services/cloud_sync_service.dart';
import 'package:cine_devinette/services/defi_state.dart';
import 'package:cine_devinette/services/enigme_state.dart';
import 'package:cine_devinette/services/game_state.dart';
import 'package:cine_devinette/services/leaderboard_service.dart';
import 'package:cine_devinette/services/multiplayer_matchmaking_service.dart';
import 'package:cine_devinette/services/multiplayer_state.dart';
import 'package:cine_devinette/services/notification_service.dart';
import 'package:cine_devinette/services/purchase_service.dart';
import 'package:cine_devinette/services/save_service.dart';
import 'package:cine_devinette/services/streak_state.dart';

void main() {
  testWidgets('App démarre et affiche l\'écran de chargement', (WidgetTester tester) async {
    VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
    final saveService = SaveService();
    final adService = AdService();
    final appSettings = AppSettings(saveService: saveService);
    final gameState = GameState(adService: adService, saveService: saveService, settings: appSettings);
    await tester.pumpWidget(CineDevinetteApp(
      adService: adService,
      gameState: gameState,
      purchaseService: PurchaseService(),
      appSettings: appSettings,
      enigmeState: EnigmeState(saveService: saveService, settings: appSettings),
      defiState: DefiState(saveService: saveService),
      leaderboardService: LeaderboardService(),
      multiplayerState: MultiplayerState(
        saveService: saveService,
        matchmaking: MultiplayerMatchmakingService(),
        settings: appSettings,
      ),
      notificationService: NotificationService(),
      streakState: StreakState(saveService: saveService),
      saveService: saveService,
      cloudSyncService: CloudSyncService(),
    ));
    // L'écran de lancement (vidéo intro_teaser.mp4) n'a pas de backend
    // plateforme réel en test — on vérifie juste qu'il s'affiche sans
    // exception grâce au FakeVideoPlayerPlatform ci-dessus.
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 1000));
  });
}
