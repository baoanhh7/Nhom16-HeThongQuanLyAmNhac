import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:logging/logging.dart';

class AudioPlayerManager {
  AudioPlayerManager({required this.songUrl}) {
    _initLogger();
  }

  final AudioPlayer player = AudioPlayer();
  late final Stream<DurationState> durationState;
  final String songUrl;
  final Logger _logger = Logger('AudioPlayerManager');

  Future<void> init() async {
    durationState = Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
      player.positionStream,
      player.playbackEventStream,
      (position, playbackEvent) => DurationState(
        progess: position,
        buffered: playbackEvent.bufferedPosition,
        total: playbackEvent.duration,
      ),
    );

    try {
      _logger.info('Loading song: $songUrl');
      await player.setUrl(songUrl);
      _logger.info('Song loaded successfully!');
    } catch (e, stackTrace) {
      _logger.severe('Error loading song', e, stackTrace);
    }
  }

  Future<void> playNewSong(String url) async {
    await player.stop();
    await player.setUrl(url);
    await player.play();
  }

  void dispose() {
    player.dispose();
    _logger.info('AudioPlayer disposed');
  }

  void _initLogger() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // In ra console
    });
  }
}

class DurationState {
  const DurationState({
    required this.progess,
    required this.buffered,
    this.total,
  });

  final Duration progess;
  final Duration buffered;
  final Duration? total;
}
