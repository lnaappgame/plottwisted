// Fake minimal de VideoPlayerPlatform pour les tests widget — sans backend
// plateforme réel (aucun canal natif en environnement de test), toute
// méthode non surchargée lève UnimplementedError par défaut, ce qui casse
// tout écran utilisant VideoPlayerController (voir IntroTeaserScreen).
// Repris du fixture de test officiel du package video_player (mêmes
// signatures que l'interface 6.9.0 utilisée par ce projet).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart'
    hide VideoAudioTrack, VideoTrack;
import 'package:video_player_platform_interface/video_player_platform_interface.dart'
    as platform_interface
    show VideoAudioTrack, VideoTrack;

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  Completer<bool> initialized = Completer<bool>();
  List<String> calls = <String>[];
  List<DataSource> dataSources = <DataSource>[];
  final Map<int, StreamController<VideoEvent>> streams = <int, StreamController<VideoEvent>>{};
  bool forceInitError = false;
  int nextPlayerId = 0;
  final Map<int, Duration> _positions = <int, Duration>{};

  @override
  Future<int?> create(DataSource dataSource) async {
    calls.add('create');
    final stream = StreamController<VideoEvent>();
    streams[nextPlayerId] = stream;
    if (forceInitError) {
      stream.addError(PlatformException(code: 'VideoError', message: 'Video player had error XYZ'));
    } else {
      stream.add(VideoEvent(
        eventType: VideoEventType.initialized,
        size: const Size(100, 100),
        duration: const Duration(seconds: 1),
      ));
    }
    dataSources.add(dataSource);
    return nextPlayerId++;
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    calls.add('createWithOptions');
    final stream = StreamController<VideoEvent>();
    streams[nextPlayerId] = stream;
    if (forceInitError) {
      stream.addError(PlatformException(code: 'VideoError', message: 'Video player had error XYZ'));
    } else {
      stream.add(VideoEvent(
        eventType: VideoEventType.initialized,
        size: const Size(100, 100),
        duration: const Duration(seconds: 1),
      ));
    }
    dataSources.add(options.dataSource);
    return nextPlayerId++;
  }

  @override
  Future<void> dispose(int playerId) async => calls.add('dispose');

  @override
  Future<void> init() async {
    calls.add('init');
    initialized.complete(true);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => streams[playerId]!.stream;

  @override
  Future<void> pause(int playerId) async => calls.add('pause');

  @override
  Future<void> play(int playerId) async => calls.add('play');

  @override
  Future<Duration> getPosition(int playerId) async {
    calls.add('position');
    return _positions[playerId] ?? Duration.zero;
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    calls.add('seekTo');
    _positions[playerId] = position;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async => calls.add('setLooping');

  @override
  Future<void> setVolume(int playerId, double volume) async => calls.add('setVolume');

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async => calls.add('setPlaybackSpeed');

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async => calls.add('setMixWithOthers');

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(int playerId, bool preventsDisplaySleepDuringVideoPlayback) async =>
      calls.add('setPreventsDisplaySleepDuringVideoPlayback');

  @override
  Widget buildView(int playerId) => Texture(textureId: playerId);

  @override
  Future<void> setWebOptions(int playerId, VideoPlayerWebOptions options) async => calls.add('setWebOptions');

  @override
  Future<List<platform_interface.VideoTrack>> getVideoTracks(int playerId) async {
    calls.add('getVideoTracks');
    return <platform_interface.VideoTrack>[];
  }

  @override
  Future<void> selectVideoTrack(int playerId, platform_interface.VideoTrack? track) async =>
      calls.add('selectVideoTrack');

  @override
  bool isVideoTrackSupportAvailable() => true;

  @override
  Future<List<platform_interface.VideoAudioTrack>> getAudioTracks(int playerId) async {
    calls.add('getAudioTracks');
    return <platform_interface.VideoAudioTrack>[];
  }

  @override
  Future<void> selectAudioTrack(int playerId, String trackId) async => calls.add('selectAudioTrack');

  @override
  bool isAudioTrackSupportAvailable() => true;
}
