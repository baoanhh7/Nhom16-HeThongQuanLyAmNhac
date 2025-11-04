import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_music_app/config/config.dart';
import 'package:flutter_music_app/main.dart';
import 'package:flutter_music_app/music/handle/audio_handler.dart';
import 'package:flutter_music_app/music/service/downloadsongmanager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/song.dart';
import '../../model/lyrics.dart';
import 'package:http/http.dart' as http;
// import '../service/lyrics_service.dart';
import 'dart:async';

class PlayingMusicInterface extends StatefulWidget {
  const PlayingMusicInterface({
    super.key,
    required this.songs,
    required this.currentIndex,
  });

  final List<Song> songs;
  final int currentIndex;

  @override
  State<PlayingMusicInterface> createState() => _PlayingMusicInterfaceState();
}

class _PlayingMusicInterfaceState extends State<PlayingMusicInterface>
    with TickerProviderStateMixin {
  bool _isShuffled = false;
  // bool _isPlaying = false;
  LoopMode _loopMode = LoopMode.off;
  Lyrics? _lyrics;
  int _currentLyricIndex = 0;
  bool _showLyrics = false;
  late AnimationController _imageAnimationController;
  late AnimationController _pageAnimationController;
  late Animation<double> pageAnimation;
  PaletteGenerator? paletteGenerator;
  Color defaultColor = Colors.black;
  double volume = 1.0;
  final ScrollController _lyricsScrollController = ScrollController();
  late List<Song> songs;
  late List<Song> shuffledList;
  late int currentIndex;
  late Song currentSong;
  bool _isNexting = false;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<MediaItem?>? _mediaItemSub;
  bool isPremium = false;
  int _songPlayCount = 0;
  bool _isShowingAd = false;
  Timer? _adTimer;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _imageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat();

    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    pageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pageAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    songs = widget.songs;
    currentIndex = widget.currentIndex;
    currentSong = songs[currentIndex];
    addSongToHistory(currentSong); // Ghi nhận lịch sử ngay khi mở player
    _initPlayer();
    _generateColors();
    _setupNotificationCallbacks();
    fetchUserProfile();
    _checkAndShowAd();
    checkFavorite();
  }

  Future<int?> getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || JwtDecoder.isExpired(token)) return null;

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

    // Dựa theo cách bạn tạo token bằng ClaimTypes.NameIdentifier:
    // => nó sẽ lưu trong key "nameid"
    final userId = decodedToken['nameid']; // hoặc 'sub' nếu bạn đổi claim

    return int.tryParse(userId.toString());
  }

  Future<void> fetchUserProfile() async {
    final userId = await getUserIdFromToken();
    debugPrint('UserId: $userId');

    final response = await http.get(Uri.parse('${ip}Users/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final String role = data['role'];

      debugPrint('Role: $role');

      // Gán vào biến state nếu muốn hiển thị ra giao diện
      if (mounted) {
        setState(() {
          isPremium = (role == 'premium');
          debugPrint('isPremium: $isPremium');
        });
      }
    } else {
      debugPrint('Error fetching profile: ${response.statusCode}');
    }
  }

  Future<void> checkFavorite() async {
    final userId = await getUserIdFromToken();
    final response = await http.get(
      Uri.parse('${ip}Users/$userId/favorite-songs'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        isFavorite = data.any((json) => json['songId'] == currentSong.songId);
      });
    }
  }

  Future<void> toggleFavorite() async {
    final userId = await getUserIdFromToken();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final url = Uri.parse(
      '${ip}Users/$userId/favorite-songs/${currentSong.songId}',
    );
    final headers = token != null ? {'Authorization': 'Bearer $token'} : null;
    debugPrint(
      'Toggle favorite: userId=$userId, songId=${currentSong.songId}, isFavorite=$isFavorite',
    );
    final response =
        isFavorite
            ? await http.delete(url, headers: headers)
            : await http.post(url, headers: headers);
    debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      setState(() {
        isFavorite = !isFavorite;
      });
    }
  }

  @override
  void dispose() {
    _lyricsScrollController.dispose();
    _pageAnimationController.dispose();
    _imageAnimationController.dispose();
    _playerStateSub?.cancel();
    _mediaItemSub?.cancel();
    _adTimer?.cancel();
    super.dispose();
  }

  void _setupNotificationCallbacks() {
    // Setup callbacks for notification controls
    (globalAudioHandler as MyAudioHandler).setCallbacks(
      onNext: () async {
        debugPrint("Next from notification");
        await _playNextSong();
      },
      onPrevious: () async {
        debugPrint("Previous from notification");
        await _playPreviousSong();
      },
      onShuffle: () {
        _toggleShuffle();
      },
      onRepeat: () {
        _toggleRepeat();
      },
    );
  }

  void _toggleView() {
    if (_showLyrics) {
      _pageAnimationController.reverse();
    } else {
      _pageAnimationController.forward();
    }
    setState(() {
      _showLyrics = !_showLyrics;
    });
  }

  void _handleSwipe(DragEndDetails details) {
    if (details.primaryVelocity! < 0 && !_showLyrics) {
      // Swipe left
      _pageAnimationController.forward();
      setState(() {
        _showLyrics = true;
      });
    } else if (details.primaryVelocity! > 0 && _showLyrics) {
      // Swipe right
      _pageAnimationController.reverse();
      setState(() {
        _showLyrics = false;
      });
    }
  }

  // Hàm kiểm tra và hiển thị quảng cáo
  void _checkAndShowAd() {
    if (!isPremium) {
      _songPlayCount++;
      debugPrint('Song play count: $_songPlayCount');

      // Hiển thị quảng cáo sau mỗi 3 bài hát
      if (_songPlayCount % 3 == 0) {
        _showInterstitialAd();
      }
    }
  }

  void _showInterstitialAd() {
    setState(() {
      _isShowingAd = true;
    });

    // Tạm dừng nhạc khi hiển thị quảng cáo
    (globalAudioHandler as MyAudioHandler).player.pause();

    // Tự động đóng quảng cáo sau 5 giây (hoặc có thể để user tự đóng)
    _adTimer = Timer(const Duration(seconds: 8), () {
      _hideAd();
    });
  }

  void _hideAd() {
    setState(() {
      _isShowingAd = false;
    });
    _adTimer?.cancel();

    // Tiếp tục phát nhạc sau khi đóng quảng cáo
    (globalAudioHandler as MyAudioHandler).player.play();
  }

  Future<void> _initPlayer() async {
    await _loadLyrics();
    await _generateColors();
    final audioHandler = globalAudioHandler as MyAudioHandler;
    final currentQueue = audioHandler.queue.value;
    final currentIdx = audioHandler.player.currentIndex ?? 0;
    final mediaItems =
        songs
            .map(
              (song) => MediaItem(
                id: song.linkSong!,
                title: song.songName,
                artist: song.artistName,
                artUri: Uri.parse(song.songImage),
                duration: null,
                extras: {'songId': song.songId},
              ),
            )
            .toList();
    bool isSameQueue =
        currentQueue.length == mediaItems.length &&
        List.generate(
          currentQueue.length,
          (i) => currentQueue[i].id == mediaItems[i].id,
        ).every((e) => e);
    if (!isSameQueue || currentIdx != currentIndex) {
      await audioHandler.setQueue(mediaItems, currentIndex);
      await audioHandler.play();
    }
    audioHandler.player.positionStream.listen(_updateCurrentLyric);
    _playerStateSub?.cancel();
    _playerStateSub = audioHandler.player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && !_isNexting) {
        _isNexting = true;
        _playNextSong().then((_) => _isNexting = false);
      }
    });
    _mediaItemSub?.cancel();
    _mediaItemSub = globalAudioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null && mounted) {
        final newSongIndex = songs.indexWhere(
          (song) => song.linkSong == mediaItem.id,
        );
        if (newSongIndex != -1 && newSongIndex != currentIndex) {
          debugPrint("Media item changed: " + mediaItem.title);
          setState(() {
            currentIndex = newSongIndex;
            currentSong = songs[currentIndex];
          });
          _loadLyrics();
          _generateColors();
          checkFavorite(); // Gọi lại khi đổi bài
          addSongToHistory(currentSong); // Lưu lịch sử nghe nhạc
        }
      }
    });
  }

  Future<void> _playNextSong() async {
    if (_isNexting) return;
    _isNexting = true;

    try {
      int nextIndex;
      if (_isShuffled) {
        nextIndex = shuffledList.indexOf(currentSong);
        if (nextIndex < shuffledList.length - 1) {
          nextIndex++;
        } else if (_loopMode == LoopMode.all) {
          nextIndex = 0;
        } else {
          return;
        }
        currentSong = shuffledList[nextIndex];
        currentIndex = songs.indexOf(currentSong);
      } else {
        if (currentIndex < songs.length - 1) {
          currentIndex++;
        } else if (_loopMode == LoopMode.all) {
          currentIndex = 0;
        } else {
          return;
        }
        currentSong = songs[currentIndex];
      }

      setState(() {});
      // Sử dụng skipToIndex thay vì addQueueItem
      await (globalAudioHandler as MyAudioHandler).skipToIndex(currentIndex);
      await _loadLyrics();
      await _generateColors();
      _checkAndShowAd();
    } finally {
      _isNexting = false;
    }
  }

  Future<void> _playPreviousSong() async {
    if (_isNexting) return;
    _isNexting = true;

    try {
      int prevIndex;
      if (_isShuffled) {
        prevIndex = shuffledList.indexOf(currentSong);
        if (prevIndex > 0) {
          prevIndex--;
          currentSong = shuffledList[prevIndex];
          currentIndex = songs.indexOf(currentSong);
        } else {
          await (globalAudioHandler as MyAudioHandler).player.seek(
            Duration.zero,
          );
          await (globalAudioHandler as MyAudioHandler).player.play();
          return;
        }
      } else {
        if (currentIndex > 0) {
          currentIndex--;
          currentSong = songs[currentIndex];
        } else {
          await (globalAudioHandler as MyAudioHandler).player.seek(
            Duration.zero,
          );
          await (globalAudioHandler as MyAudioHandler).player.play();
          return;
        }
      }

      setState(() {});

      // Sử dụng skipToIndex thay vì addQueueItem
      await (globalAudioHandler as MyAudioHandler).skipToIndex(currentIndex);
      await _loadLyrics();
      await _generateColors();
      _checkAndShowAd();
    } finally {
      _isNexting = false;
    }
  }

  // Future<void> _playSong(Song song) async {
  //   final mediaItem = MediaItem(
  //     id: song.linkSong!,
  //     title: song.songName,
  //     artist: song.artistName,
  //     artUri: Uri.parse(song.songImage),
  //   );

  //   await globalAudioHandler.addQueueItem(mediaItem);
  //   await _loadLyrics();
  //   await _generateColors();
  // }

  void _toggleShuffle() {
    setState(() {
      _isShuffled = !_isShuffled;
      if (_isShuffled) {
        shuffledList = List.from(songs);
        shuffledList.shuffle();
        // Đảm bảo bài hiện tại vẫn đang phát
        final currentSongInShuffled = shuffledList.indexOf(currentSong);
        if (currentSongInShuffled != -1) {
          // Đưa bài hiện tại lên đầu danh sách shuffle
          shuffledList.removeAt(currentSongInShuffled);
          shuffledList.insert(0, currentSong);
        }
      }
    });

    (globalAudioHandler as MyAudioHandler).updateShuffleState(_isShuffled);
  }

  void _toggleRepeat() {
    setState(() {
      _loopMode = _getNextLoopMode();
    });

    (globalAudioHandler as MyAudioHandler).updateRepeatState(_loopMode);
  }

  Future<void> _loadLyrics() async {
    try {
      debugPrint("Loading lyrics for song: ${currentSong.songName}");
      debugPrint("LRC URL: ${currentSong.linkLrc}");

      if (currentSong.linkLrc == null || currentSong.linkLrc == "null") {
        debugPrint("No LRC URL provided for this song");
        setState(() {
          _lyrics = Lyrics(
            lines: [],
            error: "No lyrics available for this song",
          );
        });
        return;
      }

      final lyrics = await Lyrics.fromUrl(currentSong.linkLrc);

      if (lyrics.error != null) {
        debugPrint("Error loading lyrics: ${lyrics.error}");
      } else {
        debugPrint("Successfully loaded ${lyrics.lines.length} lyric lines");
        if (lyrics.lines.isEmpty) {
          debugPrint("Warning: No lyric lines found in the LRC file");
        }
      }

      setState(() {
        _lyrics = lyrics;
      });
    } catch (e) {
      debugPrint("Error in _loadLyrics: $e");
      setState(() {
        _lyrics = Lyrics(lines: [], error: "Failed to load lyrics: $e");
      });
    }
  }

  Future<void> _generateColors() async {
    try {
      final imageProvider = NetworkImage(currentSong.songImage);
      final Completer<Size> completer = Completer<Size>();

      final imageStream = imageProvider.resolve(const ImageConfiguration());
      final listener = ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(
          Size(info.image.width.toDouble(), info.image.height.toDouble()),
        );
      });

      imageStream.addListener(listener);
      await completer.future;
      imageStream.removeListener(listener);

      paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(200, 200),
      );

      // print('Generated palette: ${paletteGenerator?.vibrantColor?.color}');

      setState(() {});
    } catch (e) {
      // print('Lỗi tạo palette: $e');
    }
  }

  Color getSafeBackgroundColor(PaletteGenerator? palette, Color fallback) {
    final List<Color?> candidates = [
      palette?.darkVibrantColor?.color,
      palette?.vibrantColor?.color,
      palette?.dominantColor?.color,
      palette?.lightMutedColor?.color,
    ];

    for (final color in candidates) {
      if (color != null && color.computeLuminance() < 0.8) {
        return color;
      }
    }

    return fallback; // fallback là màu đen hoặc màu mặc định bạn chọn
  }

  void _updateCurrentLyric(Duration position) {
    // debugPrint("current position: $position");
    if (_lyrics == null || _lyrics!.lines.isEmpty) return;

    for (int i = 0; i < _lyrics!.lines.length; i++) {
      if (i == _lyrics!.lines.length - 1 ||
          (position >= _lyrics!.lines[i].timestamp &&
              position < _lyrics!.lines[i + 1].timestamp)) {
        if (_currentLyricIndex != i) {
          if (!mounted) return;
          setState(() {
            _currentLyricIndex = i;
          });
          _scrollToCurrentLyric();
        }
        break;
      }
    }
  }

  void _scrollToCurrentLyric() {
    if (!_showLyrics || _lyrics == null || _lyrics!.lines.isEmpty) return;

    final itemHeight = 60.0; // Chiều cao của mỗi dòng lời bài hát
    final screenHeight = MediaQuery.of(context).size.height;
    final viewportHeight =
        screenHeight * 0.6; // Chiều cao vùng hiển thị lời bài hát

    // Tính toán vị trí cần cuộn đến
    final targetPosition =
        _currentLyricIndex * itemHeight - (viewportHeight / 2) + itemHeight;

    // Đảm bảo không cuộn quá giới hạn
    final maxScroll = _lyricsScrollController.position.maxScrollExtent;
    final minScroll = 0.0;
    final clampedPosition = targetPosition.clamp(minScroll, maxScroll);

    // Cuộn đến vị trí mới
    _lyricsScrollController.animateTo(
      clampedPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildAdOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.ads_click, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Quảng cáo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nâng cấp lên Premium để loại bỏ quảng cáo!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              // Có thể thêm banner quảng cáo thật ở đây
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Quảng cáo của bạn ở đây',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: _hideAd, child: const Text('Đóng')),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement upgrade to premium
                      _hideAd();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Nâng cấp Premium'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Building UI with song: ${currentSong.songName}");
    Color bgColor = getSafeBackgroundColor(paletteGenerator, defaultColor);

    return Container(
      decoration: BoxDecoration(color: bgColor),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            currentSong.songName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            // Xóa IconButton yêu thích ở AppBar actions (nếu có)
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child:
                      _showLyrics ? _buildLyricsView() : _buildAlbumArtView(),
                ),
                _buildSongInfo(),
                _buildPlaybackControls(),
                const SizedBox(height: 16),
                _buildAdditionalControls(),
                const SizedBox(height: 32),
              ],
            ),
            // Overlay quảng cáo
            if (_isShowingAd) _buildAdOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArtView() {
    return GestureDetector(
      onHorizontalDragEnd: _handleSwipe,
      child: Center(
        child: Hero(
          tag: 'album_art_${currentSong.songId}',
          child: Container(
            width: MediaQuery.of(context).size.width * 0.75,
            height: MediaQuery.of(context).size.width * 0.75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (paletteGenerator?.dominantColor?.color ??
                          defaultColor)
                      .withOpacity(0.6),
                  blurRadius: 50,
                  spreadRadius: 15,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: RotationTransition(
              turns: _imageAnimationController,
              child: ClipOval(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Image.network(
                    currentSong.songImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.music_note,
                          size: 64,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Future<void> _downloadSong() async {
  //   final filePath = await DownloadManager().downloadSong(currentSong);
  //   if (filePath != null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Đã tải xong: ${currentSong.songName}')),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Tải thất bại'), backgroundColor: Colors.red),
  //     );
  //   }
  // }

  Widget _buildSongInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSong.songName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  currentSong.artistName!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (isPremium)
                IconButton(
                  icon: Icon(Icons.download, color: Colors.white, size: 24),
                  onPressed: () {}, //_downloadSong,
                  tooltip: 'Tải xuống',
                ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.pink : Colors.white,
                  size: 24,
                ),
                onPressed: () async {
                  final userId = await getUserIdFromToken();
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('accessToken');
                  final url = Uri.parse(
                    '${ip}Users/$userId/favorite-songs/${currentSong.songId}',
                  );
                  final headers =
                      token != null ? {'Authorization': 'Bearer $token'} : null;
                  debugPrint(
                    'Toggle favorite: userId=$userId, songId=${currentSong.songId}, isFavorite=$isFavorite',
                  );
                  final response =
                      isFavorite
                          ? await http.delete(url, headers: headers)
                          : await http.post(url, headers: headers);
                  debugPrint(
                    'Status: ${response.statusCode}, Body: ${response.body}',
                  );
                  if (response.statusCode == 200 ||
                      response.statusCode == 201 ||
                      response.statusCode == 204) {
                    setState(() {
                      isFavorite = !isFavorite;
                    });
                  }
                },
                tooltip: isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsView() {
    if (_lyrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lyrics!.error != null) {
      return Center(
        child: Text(
          _lyrics!.error!,
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_lyrics!.lines.isEmpty) {
      return const Center(
        child: Text(
          'No lyrics available for this song',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: _handleSwipe,
      child: ListView.builder(
        controller: _lyricsScrollController,
        padding: EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 0),
        itemCount: _lyrics!.lines.length,
        itemBuilder: (context, index) {
          final line = _lyrics!.lines[index];
          final isCurrentLine = index == _currentLyricIndex;
          final isNextLine = index == _currentLyricIndex + 1;
          final isPreviousLine = index == _currentLyricIndex - 1;

          return Container(
            height: 60, // Chiều cao cố định cho mỗi dòng
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize:
                    isCurrentLine
                        ? 20
                        : (isNextLine || isPreviousLine ? 18 : 16),
                color:
                    isCurrentLine
                        ? Colors.white
                        : (isNextLine || isPreviousLine
                            ? Colors.white70
                            : Colors.grey),
                fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Roboto',
                height: 1.5,
              ),
              child: Text(
                line.text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Column(
      children: [
        StreamBuilder<Duration?>(
          stream: (globalAudioHandler as MyAudioHandler).player.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final duration =
                (globalAudioHandler as MyAudioHandler).player.duration ??
                Duration.zero;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 20,
                      ),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: position.inMilliseconds.toDouble().clamp(
                        0,
                        duration.inMilliseconds.toDouble(),
                      ),
                      max:
                          duration.inMilliseconds.toDouble() > 0
                              ? duration.inMilliseconds.toDouble()
                              : 1,
                      onChanged: (value) {
                        (globalAudioHandler as MyAudioHandler).player.seek(
                          Duration(milliseconds: value.toInt()),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                iconSize: 32,
                onPressed: () async {
                  await _playPreviousSong();
                },
              ),
            ),
            StreamBuilder<PlayerState>(
              stream:
                  (globalAudioHandler as MyAudioHandler)
                      .player
                      .playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                final playing = playerState?.playing;
                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering) {
                  return Container(
                    margin: const EdgeInsets.all(8.0),
                    width: 64.0,
                    height: 64.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  );
                } else if (playing != true) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      iconSize: 48,
                      onPressed: () {
                        (globalAudioHandler as MyAudioHandler).player.play();
                      },
                    ),
                  );
                } else {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.pause, color: Colors.white),
                      iconSize: 48,
                      onPressed: () {
                        (globalAudioHandler as MyAudioHandler).player.pause();
                      },
                    ),
                  );
                }
              },
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                iconSize: 32,
                onPressed: () async {
                  await _playNextSong();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _isShuffled
                      ? Colors.green.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
            ),
            child: IconButton(
              icon: Icon(
                Icons.shuffle,
                color: _isShuffled ? Colors.green : Colors.white,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _isShuffled = !_isShuffled;
                  if (_isShuffled) {
                    shuffledList = List.from(songs);
                    shuffledList.shuffle();
                    currentIndex = shuffledList.indexOf(currentSong);
                  } else {
                    currentIndex = songs.indexOf(currentSong);
                  }
                });
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _loopMode == LoopMode.one
                      ? Colors.green.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
            ),
            child: IconButton(
              icon: Icon(
                _getRepeatIcon(),
                color: _loopMode == LoopMode.one ? Colors.green : Colors.white,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _loopMode = _getNextLoopMode();
                  (globalAudioHandler as MyAudioHandler).player.setLoopMode(
                    _loopMode,
                  );
                });
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: IconButton(
              icon: Icon(
                _showLyrics ? Icons.album : Icons.lyrics,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _toggleView,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.playlist_play,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                // TODO: Implement playlist view
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRepeatIcon() {
    return _loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat;
  }

  LoopMode _getNextLoopMode() {
    return _loopMode == LoopMode.off ? LoopMode.one : LoopMode.off;
  }

  Future<void> addSongToHistory(Song song) async {
    // Gọi API backend để lưu lịch sử
    final userId = await getUserIdFromToken();
    if (userId != null) {
      try {
        await http.post(Uri.parse('${ip}Users/$userId/history/${song.songId}'));
      } catch (e) {
        debugPrint('Lỗi lưu lịch sử backend: $e');
      }
    }
    // (Có thể giữ lại đoạn lưu local nếu muốn)
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('music_history') ?? [];
    List<Song> history =
        historyJson
            .map((e) {
              try {
                return Song.fromJson(Map<String, dynamic>.from(jsonDecode(e)));
              } catch (_) {
                return null;
              }
            })
            .whereType<Song>()
            .toList();
    history.removeWhere((s) => s.songId == song.songId);
    history.insert(0, song);
    if (history.length > 50) history = history.sublist(0, 50);
    final newJson =
        history
            .map(
              (s) => jsonEncode({
                'songId': s.songId,
                'songName': s.songName,
                'songImage': s.songImage,
                'linkSong': s.linkSong,
                'linkLrc': s.linkLrc,
                'views': s.views,
                'artistName': s.artistName,
              }),
            )
            .toList();
    await prefs.setStringList('music_history', newJson);
  }
}
