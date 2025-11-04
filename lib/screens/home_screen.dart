import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_music_app/chatbox/chat_screen.dart';
import 'package:flutter_music_app/screens/offline/offline_music_screen.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import 'tabs/home_tab.dart';
import 'tabs/search_tab.dart';
import 'tabs/library_tab.dart';
import 'tabs/profile_tab.dart';
import '../drawer/favorite_songs_screen.dart';
import '../drawer/history_screen.dart';
import '../drawer/downloaded_songs_screen.dart';
import '../music/play_music/miniplayer.dart';
import '../model/song.dart';
import '../music/handle/audio_handler.dart';
import '../music/play_music/playing_music.dart';
import '../main.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_music_app/config/config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late List<Animation<double>> _tabIconAnimations;
  int? userId;
  bool isPremium = false;
  Song? _currentSong;
  bool _isPlaying = false;
  String token = "";
  final List<Widget> _screens = [
    const HomeTab(),
    const SearchTab(),
    const LibraryTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    // goToOfflineScreenIfEligible(context);
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _tabIconAnimations = List.generate(
      4,
      (index) => Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.1 * index,
            0.1 * index + 0.6,
            curve: Curves.easeOut,
          ),
        ),
      ),
    );
    fetchUser();
    // addAccount(userId: userId!, isPremium: isPremium, accessToken: token);
    // Lắng nghe trạng thái phát nhạc
    (globalAudioHandler as MyAudioHandler).mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        setState(() {
          _currentSong = Song(
            songId:
                int.tryParse(mediaItem.extras?['songId']?.toString() ?? '0') ??
                0,
            songName: mediaItem.title,
            songImage: mediaItem.artUri.toString(),
            artistName: mediaItem.artist,
            linkSong: mediaItem.id,
          );
        });
      }
    });
    (globalAudioHandler as MyAudioHandler).player.playerStateStream.listen((
      state,
    ) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  Future<Map<String, String>?> getCurrentUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final accountListJson = prefs.getString('accounts');
    final token = prefs.getString('accessToken');
    if (accountListJson != null && token != null) {
      final List<dynamic> list = jsonDecode(accountListJson);
      final user = list.cast<Map<String, dynamic>>().firstWhere(
        (acc) => acc['accessToken'] == token,
        orElse: () => {},
      );
      if (user.isNotEmpty) return Map<String, String>.from(user);
    }

    return null;
  }

  Future<bool> hasNetworkConnection() async {
    var result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> goToOfflineScreenIfEligible(BuildContext context) async {
    final hasNetwork = await hasNetworkConnection();
    final currentUser = await getCurrentUserInfo();

    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không tìm thấy tài khoản.')));
      return;
    }

    final isPremium = currentUser['isPremium'] == 'true';

    if (!hasNetwork && isPremium) {
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => OfflineMusicScreen()),
      // );
    } else {
      _pageController = PageController();
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );

      _tabIconAnimations = List.generate(
        4,
        (index) => Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              0.1 * index,
              0.1 * index + 0.6,
              curve: Curves.easeOut,
            ),
          ),
        ),
      );
      fetchUser();
      // addAccount(userId: userId!, isPremium: isPremium, accessToken: token);
      // Lắng nghe trạng thái phát nhạc
      (globalAudioHandler as MyAudioHandler).mediaItem.listen((mediaItem) {
        if (mediaItem != null) {
          setState(() {
            _currentSong = Song(
              songId:
                  int.tryParse(
                    mediaItem.extras?['songId']?.toString() ?? '0',
                  ) ??
                  0,
              songName: mediaItem.title,
              songImage: mediaItem.artUri.toString(),
              artistName: mediaItem.artist,
              linkSong: mediaItem.id,
            );
          });
        }
      });
      (globalAudioHandler as MyAudioHandler).player.playerStateStream.listen((
        state,
      ) {
        setState(() {
          _isPlaying = state.playing;
        });
      });
    }
  }

  Future<void> addAccount({
    required int userId,
    // required String username,
    required bool isPremium,
    required String accessToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString('accounts');
    List<Map<String, String>> accounts = [];

    if (existingJson != null) {
      final decoded = jsonDecode(existingJson);
      accounts = List<Map<String, String>>.from(
        decoded.map((item) => Map<String, String>.from(item)),
      );
    }

    // Check nếu đã tồn tại userId thì cập nhật
    final index = accounts.indexWhere(
      (acc) => acc['userId'] == userId.toString(),
    );
    if (index != -1) {
      accounts[index] = {
        'userId': userId.toString(),
        // 'username': username,
        'isPremium': isPremium.toString(),
        'accessToken': accessToken,
      };
    } else {
      accounts.add({
        'userId': userId.toString(),
        // 'username': username,
        'isPremium': isPremium.toString(),
        // 'accessToken': accessToken,
      });
    }

    await prefs.setString('accounts', jsonEncode(accounts));
  }

  Future<int?> getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('accessToken')!;

    if (token == null || JwtDecoder.isExpired(token)) return null;

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    final userId = decodedToken['nameid'];

    return int.tryParse(userId.toString());
  }

  Future<void> fetchUser() async {
    userId = await getUserIdFromToken();
    debugPrint('UserId: $userId');

    final response = await http.get(Uri.parse('${ip}Users/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final String role = data['role'];

      debugPrint('Role: $role');

      isPremium = (role == 'premium');
      debugPrint('isPremium: $isPremium');
    } else {
      debugPrint('Error fetching profile: ${response.statusCode}');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: AppColors.primaryDark,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 42, 16, 16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.music_note, size: 50, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      'Music App',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.white),
                title: const Text(
                  'Trang chủ',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _onTabTapped(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.white),
                title: const Text(
                  'Bài hát yêu thích',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoriteSongsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.white),
                title: const Text(
                  'Lịch sử',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.white),
                title: const Text(
                  'Bài hát đã tải',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DownloadedSongsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.white),
                title: const Text(
                  'Trợ lý AI (Chat)',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                  ); // Đóng drawer hoặc bottom sheet nếu có
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              MusicChatScreen(userId: userId), // 👈 Mở chatbox
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          _animationController.reset();
          _animationController.forward();
        },
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentSong != null)
            MiniPlayer(
              song: _currentSong!,
              isPlaying: _isPlaying,
              onTap: () {
                final queue =
                    (globalAudioHandler as MyAudioHandler).queue.value;
                final currentIndex =
                    (globalAudioHandler as MyAudioHandler)
                        .player
                        .currentIndex ??
                    0;
                final songs =
                    queue
                        .map(
                          (mediaItem) => Song(
                            songId:
                                int.tryParse(
                                  mediaItem.extras?['songId']?.toString() ??
                                      '0',
                                ) ??
                                0,
                            songName: mediaItem.title,
                            songImage: mediaItem.artUri.toString(),
                            artistName: mediaItem.artist,
                            linkSong: mediaItem.id,
                          ),
                        )
                        .toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PlayingMusicInterface(
                          songs: songs,
                          currentIndex: currentIndex,
                        ),
                  ),
                );
              },
              onPlayPause: () {
                if (_isPlaying) {
                  (globalAudioHandler as MyAudioHandler).pause();
                } else {
                  (globalAudioHandler as MyAudioHandler).play();
                }
              },
              onNext: null, // Có thể bổ sung logic next bài
            ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.divider, width: 0.5),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x20000000)],
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.primaryDark,
              selectedItemColor: AppColors.primaryColor,
              unselectedItemColor: AppColors.textSecondary,
              items: List.generate(4, (index) {
                final iconData =
                    [
                      Icons.home,
                      Icons.search,
                      Icons.library_music,
                      Icons.person,
                    ][index];

                final label = ['Home', 'Search', 'Library', 'Profile'][index];

                return BottomNavigationBarItem(
                  icon: ScaleTransition(
                    scale: _tabIconAnimations[index],
                    child: Icon(iconData),
                  ),
                  label: label,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
