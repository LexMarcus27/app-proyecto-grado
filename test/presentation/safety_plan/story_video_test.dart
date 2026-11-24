// Verificación en Android, sesión 4 (G3 y G5), hallazgo S4-H01: al terminar
// un video del relato o de la guía, el botón de reproducir debe reaparecer.
import 'dart:async';

import 'package:contigo/presentation/safety_plan/widgets/story_video.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Reproductor simulado: se inicializa con un clip de 2 s y permite emitir el
/// evento de fin de reproducción como lo hace el complemento nativo.
class _FakeVideoPlatform extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> streams = {};
  final List<String> calls = [];
  int _next = 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = _next++;
    final stream = StreamController<VideoEvent>();
    streams[id] = stream;
    stream.add(VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 2),
      size: const Size(320, 180),
    ));
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => streams[playerId]!.stream;

  void complete(int playerId) =>
      streams[playerId]!.add(VideoEvent(eventType: VideoEventType.completed));

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> play(int playerId) async => calls.add('play');
  @override
  Future<void> pause(int playerId) async => calls.add('pause');
  @override
  Future<void> seekTo(int playerId, Duration position) async =>
      calls.add('seek ${position.inMilliseconds}');
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
  @override
  Future<void> dispose(int playerId) async {}
}

void main() {
  late _FakeVideoPlatform platform;

  setUp(() {
    platform = _FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 30),
          ));
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('al terminar el video reaparece «Reproducir video» (S4-H01)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StoryVideo(asset: 'assets/video/prueba.mp4', title: 'Prueba'),
        ),
      ),
    ));
    await settle(tester);

    Finder button(String label) => find.byIcon(
        label == 'Reproducir video' ? Icons.play_arrow : Icons.pause);
    double opacityOf(String label) => tester
        .widget<AnimatedOpacity>(find
            .ancestor(of: button(label), matching: find.byType(AnimatedOpacity))
            .first)
        .opacity;

    expect(button('Reproducir video'), findsOneWidget);
    await tester.tap(button('Reproducir video'));
    await settle(tester);
    expect(button('Pausar video'), findsOneWidget);
    expect(opacityOf('Pausar video'), 0, reason: 'mientras se reproduce');

    // El complemento avisa que el clip terminó.
    platform.complete(0);
    await settle(tester);

    expect(button('Reproducir video'), findsOneWidget,
        reason: 'al terminar debe volver a ofrecer reproducir');
    expect(opacityOf('Reproducir video'), 1);

    // Reproducir de nuevo reinicia desde el principio.
    platform.calls.clear();
    await tester.tap(button('Reproducir video'));
    await settle(tester);
    expect(platform.calls, containsAllInOrder(['seek 0', 'play']));
  });
}
