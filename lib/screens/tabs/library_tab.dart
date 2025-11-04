import 'package:flutter/material.dart';
import 'package:flutter_music_app/library/artist_user_lib.dart';
import 'package:flutter_music_app/library/playlist_user_lib.dart';
import 'package:flutter_music_app/model/artist.dart';
import 'package:flutter_music_app/model/playlist_user.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../user/create_playlist_screen.dart';
import '../../config/config.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  int _selectedFilter = 0;
  List<PlaylistUser> _playlists = [];
  List<Artist> _artists = [];
  bool _isLoading = true;
  late int? userId;

  @override
  void initState() {
    super.initState();
    debugPrint("LibraryTab: Initializing...");
    fetchUserLibrary();
  }

  Future<int?> getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || JwtDecoder.isExpired(token)) return null;

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    final userId = decodedToken['nameid'];

    return int.tryParse(userId.toString());
  }

  Future<void> fetchUserLibrary() async {
    setState(() {
      _isLoading = true;
    });

    userId = await getUserIdFromToken();
    debugPrint('UserId: $userId');

    try {
      final response = await http.get(Uri.parse('${ip}Users/$userId/lib'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final playlists =
            (data['playlists'] as List)
                .map((e) => PlaylistUser.fromJson(e))
                .toList();
        final artists =
            (data['favoriteArtists'] as List)
                .map((e) => Artist.fromJson(e))
                .toList();

        debugPrint('Playlists count: ${playlists.length}');
        debugPrint('Artists count: ${artists.length}');

        setState(() {
          _playlists = playlists;
          _artists = artists;
          _isLoading = false;
        });
      } else {
        debugPrint('Error fetching library: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Exception fetching library: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredItems {
    switch (_selectedFilter) {
      case 0:
        return _playlists;
      case 1:
        return _artists;
      default:
        return [];
    }
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedFilter) {
      case 0:
        message =
            'Bạn chưa có danh sách phát nào\nTạo danh sách phát đầu tiên của bạn!';
        icon = Icons.queue_music;
        break;
      case 1:
        message =
            'Bạn chưa theo dõi nghệ sĩ nào\nHãy khám phá và theo dõi nghệ sĩ yêu thích!';
        icon = Icons.person;
        break;
      default:
        message = 'Không có dữ liệu';
        icon = Icons.inbox;
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistTile(PlaylistUser playlist) {
    return ListTile(
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.queue_music, size: 28, color: Colors.black54),
      ),
      title: Text(
        playlist.name,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Danh sách phát',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PlaylistUserLib(
                  playlistID: playlist.id,
                  playlistName: playlist.name,
                ),
          ),
        );
        if (result == true) {
          // Xoá playlist khỏi danh sách trong state
          setState(() {
            _playlists.removeWhere((p) => p.id == playlist.id);
          });
        }
      },
    );
  }

  Widget _buildArtistTile(Artist artist) {
    return ListTile(
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28), // Tròn cho artist
          image: DecorationImage(
            image: NetworkImage(artist.artistImage),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        artist.artistName,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Nghệ sĩ',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ArtistUserLib(artistID: artist.artistId, userId: userId),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.background,
          title: const Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage('https://picsum.photos/32/32'),
              ),
              SizedBox(width: 16),
              Text(
                'Your Library',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppColors.background,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[700],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.music_note,
                              color: Colors.white,
                            ),
                            title: const Text(
                              'Danh sách phát',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: const Text(
                              'Tạo danh sách phát gồm bài hát hoặc tập',
                              style: TextStyle(color: Colors.grey),
                            ),
                            onTap: () async {
                              Navigator.pop(context);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreatePlaylistScreen(),
                                ),
                              );
                              if (result == true) {
                                fetchUserLibrary();
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.group,
                              color: Colors.white,
                            ),
                            title: const Text(
                              'Danh sách phát cộng tác',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: const Text(
                              'Mời bạn bè cùng sáng tạo',
                              style: TextStyle(color: Colors.grey),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.link,
                              color: Colors.white,
                            ),
                            title: const Text(
                              'Giai điệu chung',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: const Text(
                              'Kết hợp các gu nghe nhạc trong một danh sách phát chia...',
                              style: TextStyle(color: Colors.grey),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text('Playlists (${_playlists.length})'),
                  selected: _selectedFilter == 0,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = 0;
                      });
                    }
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primaryColor.withOpacity(0.15),
                  shape: const StadiumBorder(),
                  showCheckmark: false,
                  side: BorderSide(
                    color:
                        _selectedFilter == 0
                            ? AppColors.primaryColor
                            : Colors.grey.shade400,
                    width: 1.5,
                  ),
                  labelStyle: TextStyle(
                    color:
                        _selectedFilter == 0
                            ? AppColors.primaryColor
                            : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Artists (${_artists.length})'),
                  selected: _selectedFilter == 1,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = 1;
                      });
                    }
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primaryColor.withOpacity(0.15),
                  shape: const StadiumBorder(),
                  showCheckmark: false,
                  side: BorderSide(
                    color:
                        _selectedFilter == 1
                            ? AppColors.primaryColor
                            : Colors.grey.shade400,
                    width: 1.5,
                  ),
                  labelStyle: TextStyle(
                    color:
                        _selectedFilter == 1
                            ? AppColors.primaryColor
                            : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          )
        else if (_filteredItems.isEmpty)
          _buildEmptyState()
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = _filteredItems[index];

              Widget tile;
              if (item is PlaylistUser) {
                tile = _buildPlaylistTile(item);
              } else if (item is Artist) {
                tile = _buildArtistTile(item);
              } else {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 4.0,
                ),
                child: tile,
              );
            }, childCount: _filteredItems.length),
          ),
      ],
    );
  }
}
