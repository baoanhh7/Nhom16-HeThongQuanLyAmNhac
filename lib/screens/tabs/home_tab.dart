import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/config.dart';
import '../../model/artist.dart';
import '../../library/artist_user_lib.dart';
import '../../model/song.dart';
import '../../model/album.dart';
import 'album_songs_screen.dart';
import '../../music/play_music/playing_music.dart';
import '../../model/playlist.dart';
import '../../library/playlist_user_lib.dart';
import 'playlist_songs_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Artist> _artists = [];
  bool _isLoadingArtists = true;

  List<Song> _suggestedSongs = [];
  bool _isLoadingSongs = true;

  List<Album> _albums = [];
  bool _isLoadingAlbums = true;
  int? userId;

  List<Playlist> _playlists = [];
  bool _isLoadingPlaylists = true;

  @override
  void initState() {
    super.initState();
    fetchArtists();
    fetchSuggestedSongs();
    fetchAlbums();
    fetchPlaylists();
  }

  Future<int?> getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || JwtDecoder.isExpired(token)) return null;

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    final userId = decodedToken['nameid'];

    return int.tryParse(userId.toString());
  }

  Future<void> fetchArtists() async {
    try {
      final response = await http.get(Uri.parse('${ip}Artists'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _artists = data.map((json) => Artist.fromJson(json)).toList();
          _isLoadingArtists = false;
        });
      } else {
        setState(() {
          _isLoadingArtists = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingArtists = false;
      });
    }
  }

  Future<void> fetchSuggestedSongs() async {
    try {
      final response = await http.get(Uri.parse('${ip}Songs/top?limit=10'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<Song> songs = data.map((json) => Song.fromJson(json)).toList();
        setState(() {
          _suggestedSongs = songs;
          _isLoadingSongs = false;
        });
      } else {
        setState(() {
          _isLoadingSongs = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingSongs = false;
      });
    }
  }

  Future<void> fetchAlbums() async {
    try {
      final response = await http.get(Uri.parse('${ip}Albums/top?limit=3'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _albums = data.map((json) => Album.fromJson(json)).toList();
          _isLoadingAlbums = false;
        });
      } else {
        setState(() {
          _isLoadingAlbums = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingAlbums = false;
      });
    }
  }

  Future<void> fetchPlaylists() async {
    setState(() {
      _isLoadingPlaylists = true;
    });
    try {
      final response = await http.get(Uri.parse('${ip}Playlists'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final playlists = data.map((json) => Playlist.fromJson(json)).toList();
        setState(() {
          _playlists = playlists;
          _isLoadingPlaylists = false;
        });
      } else {
        setState(() {
          _isLoadingPlaylists = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingPlaylists = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.background,
          title: const Text(
            'Good a nice day',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
            IconButton(icon: const Icon(Icons.history), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {},
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Nghệ sĩ phổ biến ---
                const Text(
                  'Nghệ sĩ nổi bật',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // làm title sáng hơn
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child:
                      _isLoadingArtists
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _artists.length,
                            itemBuilder: (context, index) {
                              final artist = _artists[index];
                              return Container(
                                width: 90, // tăng width để đủ chỗ cho 2 dòng
                                margin: const EdgeInsets.only(right: 16),
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => ArtistUserLib(
                                                  artistID: artist.artistId,
                                                  userId: userId,
                                                ),
                                          ),
                                        );
                                      },
                                      child: CircleAvatar(
                                        radius: 44,
                                        backgroundImage: NetworkImage(
                                          artist.artistImage,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      artist.artistName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2, // cho phép 2 dòng
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Danh sách phát',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                _isLoadingPlaylists
                    ? const Center(child: CircularProgressIndicator())
                    : _playlists.isEmpty
                    ? const Text(
                      'Bạn chưa có danh sách phát nào.',
                      style: TextStyle(color: Colors.white70),
                    )
                    : GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 12,
                            childAspectRatio: 2.7,
                          ),
                      itemCount: _playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = _playlists[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => PlaylistSongsScreen(
                                      playlistId: playlist.playlistId,
                                      playlistName: playlist.playlistName,
                                      playlistImage: playlist.playlistImage,
                                    ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.network(
                                    playlist.playlistImage,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (ctx, _, __) => Container(
                                          color: Colors.grey[800],
                                          child: const Icon(
                                            Icons.queue_music,
                                            color: Colors.white,
                                            size: 36,
                                          ),
                                        ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.6),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      playlist.playlistName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 4,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                const SizedBox(height: 32),
                const Text(
                  'Album phổ biến',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2), // giảm khoảng cách sát hơn nữa
                _isLoadingAlbums
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _albums.length,
                      itemBuilder: (context, index) {
                        final album = _albums[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            top:
                                index == 0
                                    ? 0
                                    : 6, // Dòng đầu không padding top
                            bottom: 6,
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AlbumSongsScreen(
                                            albumId: album.albumId,
                                            albumName: album.albumName,
                                            albumImage: album.albumImage,
                                            artistName: album.artistName,
                                          ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    album.albumImage,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (ctx, _, __) => const Icon(
                                          Icons.album,
                                          size: 32,
                                          color: Colors.white,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      album.albumName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      album.artistName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                const SizedBox(height: 32),
                const Text(
                  'Top 10 bài hát lượt nghe nhiều nhất',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child:
                      _isLoadingSongs
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                _suggestedSongs.length > 10
                                    ? 10
                                    : _suggestedSongs.length,
                            itemBuilder: (context, index) {
                              final song = _suggestedSongs[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => PlayingMusicInterface(
                                            songs: _suggestedSongs,
                                            currentIndex: index,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                        child: Image.network(
                                          song.songImage,
                                          width: 140,
                                          height: 140,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (ctx, _, __) => const Icon(
                                                Icons.music_note,
                                                size: 40,
                                                color: Colors.white,
                                              ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          song.songName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          song.artistName ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
