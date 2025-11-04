import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer player = AudioPlayer();

  // Callback functions để giao tiếp với UI
  VoidCallback? onNext;
  VoidCallback? onPrevious;
  VoidCallback? onShuffle;
  VoidCallback? onRepeat;

  // State variables
  bool _isShuffled = false;
  LoopMode _loopMode = LoopMode.off;

  MyAudioHandler() {
    _init();
  }

  // Set callback functions từ UI
  void setCallbacks({
    VoidCallback? onNext,
    VoidCallback? onPrevious,
    VoidCallback? onShuffle,
    VoidCallback? onRepeat,
  }) {
    this.onNext = onNext;
    this.onPrevious = onPrevious;
    this.onShuffle = onShuffle;
    this.onRepeat = onRepeat;
  }

  // Update shuffle state
  void updateShuffleState(bool isShuffled) {
    _isShuffled = isShuffled;
    _notifyAudioHandlerOfDataChange();
  }

  // Update repeat state
  void updateRepeatState(LoopMode loopMode) {
    _loopMode = loopMode;
    player.setLoopMode(loopMode);
    _notifyAudioHandlerOfDataChange();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Listen to playback events
    player.playbackEventStream.listen((event) {
      _notifyAudioHandlerOfDataChange();
    });

    // Listen to current index changes
    player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        mediaItem.add(queue.value[index]);
      }
    });

    // Listen to sequence state changes
    player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState != null) {
        final currentItem = sequenceState.currentSource?.tag as MediaItem?;
        if (currentItem != null) {
          mediaItem.add(currentItem);
        }
      }
    });
  }

  void _notifyAudioHandlerOfDataChange() {
    final playing = player.playing;
    final processingState = player.processingState;
    final position = player.position;
    final bufferedPosition = player.bufferedPosition;
    final speed = player.speed;
    final currentIndex = player.currentIndex;

    // Tạo danh sách controls dựa trên state
    final controls = <MediaControl>[
      MediaControl.skipToPrevious,
      playing ? MediaControl.pause : MediaControl.play,
      MediaControl.skipToNext,
    ];

    // Thêm controls tùy chọn
    final customActions = <MediaAction>{
      MediaAction.seek,
      MediaAction.setShuffleMode,
      MediaAction.setRepeatMode,
    };

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: customActions,
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapProcessingState(processingState),
        playing: playing,
        updatePosition: position,
        bufferedPosition: bufferedPosition,
        speed: speed,
        queueIndex: currentIndex,
        shuffleMode:
            _isShuffled
                ? AudioServiceShuffleMode.all
                : AudioServiceShuffleMode.none,
        repeatMode: _mapRepeatMode(_loopMode),
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  AudioServiceRepeatMode _mapRepeatMode(LoopMode loopMode) {
    switch (loopMode) {
      case LoopMode.off:
        return AudioServiceRepeatMode.none;
      case LoopMode.one:
        return AudioServiceRepeatMode.one;
      case LoopMode.all:
        return AudioServiceRepeatMode.all;
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    try {
      // Tạo AudioSource với MediaItem tag
      final audioSource = AudioSource.uri(
        Uri.parse(mediaItem.id),
        tag: mediaItem,
      );

      await player.setAudioSource(audioSource);

      // Update queue
      final newQueue = List<MediaItem>.from(queue.value)..add(mediaItem);
      queue.add(newQueue);

      // Update current media item
      this.mediaItem.add(mediaItem);

      await player.play();
      // Cập nhật notification
      _notifyAudioHandlerOfDataChange();
    } catch (e) {
      debugPrint("Lỗi khi phát bài hát: $e");
    }
  }

  // Thêm method mới để set toàn bộ queue
  Future<void> setQueue(List<MediaItem> mediaItems, int initialIndex) async {
    try {
      final audioSources =
          mediaItems
              .map((item) => AudioSource.uri(Uri.parse(item.id), tag: item))
              .toList();

      await player.setAudioSource(
        ConcatenatingAudioSource(children: audioSources),
        initialIndex: initialIndex,
      );

      queue.add(mediaItems);
      if (mediaItems.isNotEmpty) {
        mediaItem.add(mediaItems[initialIndex]);
      }

      _notifyAudioHandlerOfDataChange();
    } catch (e) {
      debugPrint("Lỗi khi set queue: $e");
    }
  }

  // Thêm method để chuyển bài mà không thay đổi queue
  Future<void> skipToIndex(int index) async {
    if (index >= 0 && index < queue.value.length) {
      await player.seek(Duration.zero, index: index);
      mediaItem.add(queue.value[index]);
      _notifyAudioHandlerOfDataChange();
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    try {
      final audioSources =
          mediaItems
              .map((item) => AudioSource.uri(Uri.parse(item.id), tag: item))
              .toList();

      await player.setAudioSource(
        ConcatenatingAudioSource(children: audioSources),
        initialIndex: 0,
      );

      queue.add(mediaItems);
      if (mediaItems.isNotEmpty) {
        mediaItem.add(mediaItems.first);
      }
    } catch (e) {
      debugPrint("Lỗi khi thêm danh sách bài hát: $e");
    }
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (player.audioSource is ConcatenatingAudioSource) {
      final concatenatingAudioSource =
          player.audioSource as ConcatenatingAudioSource;
      await concatenatingAudioSource.removeAt(index);

      final newQueue = List<MediaItem>.from(queue.value)..removeAt(index);
      queue.add(newQueue);
    }
  }

  @override
  Future<void> play() async {
    await player.play();
  }

  @override
  Future<void> pause() async {
    await player.pause();
  }

  @override
  Future<void> stop() async {
    await player.stop();
    await player.dispose();
  }

  @override
  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (onNext != null) {
      onNext!();
    } else {
      await player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (onPrevious != null) {
      onPrevious!();
    } else {
      await player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < queue.value.length) {
      await player.seek(Duration.zero, index: index);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    _isShuffled = enabled;
    if (onShuffle != null) {
      onShuffle!();
    }
    _notifyAudioHandlerOfDataChange();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        _loopMode = LoopMode.off;
        break;
      case AudioServiceRepeatMode.one:
        _loopMode = LoopMode.one;
        break;
      case AudioServiceRepeatMode.all:
        _loopMode = LoopMode.all;
        break;
      case AudioServiceRepeatMode.group:
        _loopMode = LoopMode.all;
        break;
    }

    await player.setLoopMode(_loopMode);
    if (onRepeat != null) {
      onRepeat!();
    }
    _notifyAudioHandlerOfDataChange();
  }

  @override
  Future<void> setSpeed(double speed) async {
    await player.setSpeed(speed);
  }

  @override
  Future<void> setVolume(double volume) async {
    await player.setVolume(volume);
  }

  // Custom actions
  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'toggleLyrics':
        // Handle toggle lyrics
        break;
      case 'openQueue':
        // Handle open queue
        break;
      case 'addToFavorites':
        // Handle add to favorites
        break;
      default:
        super.customAction(name, extras);
    }
  }

  // Dispose method
  Future<void> dispose() async {
    await player.dispose();
  }
}
