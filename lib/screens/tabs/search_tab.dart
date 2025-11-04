import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/app_colors.dart';
import '../../model/song.dart';
import '../../model/artist.dart';
import '../../model/album.dart';
import '../../model/playlist_user.dart';
import '../../music/play_music/playing_music.dart';
import '../../config/config.dart';
import '../tabs/album_songs_screen.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({Key? key}) : super(key: key);

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _controller = TextEditingController();
  List<Song> filteredSongs = [];
  List<Artist> filteredArtists = [];
  List<Album> filteredAlbums = [];
  List<PlaylistUser> filteredPlaylists = [];
  List<Song> allSongs = [];
  List<Song> topSongs = [];
  bool _isLoading = false;
  Timer? _debounce;

  final List<Map<String, dynamic>> categories = [
    {"title": "Nhạc", "color": Color(0xFFE040FB), "icon": Icons.music_note},
    {"title": "Podcasts", "color": Color(0xFF26A69A), "icon": Icons.podcasts},
    {
      "title": "Sự kiện trực tiếp",
      "color": Color(0xFF7C4DFF),
      "icon": Icons.event,
    },
    {
      "title": "Dành Cho Bạn",
      "color": Color(0xFFB39DDB),
      "icon": Icons.favorite,
    },
    {
      "title": "Bản phát hành mới",
      "color": Color(0xFF43A047),
      "icon": Icons.fiber_new,
    },
    {
      "title": "Mới phát hành",
      "color": Color(0xFFFBC02D),
      "icon": Icons.new_releases,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
    fetchAllSongs();
    fetchTopSongs();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final keyword = _controller.text;
      if (keyword.isEmpty) {
        setState(() {
          filteredSongs = [];
          filteredArtists = [];
          filteredAlbums = [];
          filteredPlaylists = [];
        });
      } else {
        fetchSearchResults(keyword);
      }
    });
  }

  Future<void> fetchSearchResults(String keyword) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${ip}Search?keyword=$keyword'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          filteredSongs =
              (data['songs'] as List).map((e) => Song.fromJson(e)).toList();
          filteredArtists =
              (data['artists'] as List).map((e) => Artist.fromJson(e)).toList();
          filteredAlbums =
              (data['albums'] as List).map((e) => Album.fromJson(e)).toList();
          filteredPlaylists =
              (data['playlists'] as List)
                  .map((e) => PlaylistUser.fromJson(e))
                  .toList();
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> fetchAllSongs() async {
    try {
      final response = await http.get(Uri.parse('${ip}Songs'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          allSongs = (data as List).map((e) => Song.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Fetch all songs error: $e');
    }
  }

  Future<void> fetchTopSongs() async {
    try {
      final response = await http.get(Uri.parse('${ip}Songs/top?limit=3'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          topSongs = (data as List).map((e) => Song.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Fetch top songs error: $e');
    }
  }

  Widget _buildSection<T>(
    String title,
    List<T> items,
    Widget Function(T) itemBuilder,
  ) {
    if (items.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        ...items.map(itemBuilder).toList(),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _controller.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Tìm kiếm', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Bạn muốn nghe gì?',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (!isSearching)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Khám phá nội dung mới mẻ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final song in topSongs)
                            _DiscoverSongCard(song: song),
                          if (topSongs.length < 3)
                            for (int i = 0; i < 3 - topSongs.length; i++)
                              SizedBox(width: 110, height: 140),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Text(
                          'Duyệt tìm tất cả',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children:
                            categories
                                .map((cat) => _CategoryCard(cat: cat))
                                .toList(),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection<Song>(
                        'Bài hát',
                        filteredSongs,
                        (song) => _SongTile(song: song),
                      ),
                      if (filteredArtists.isNotEmpty)
                        _buildSection<Artist>(
                          'Nghệ sĩ',
                          filteredArtists,
                          (artist) => _ArtistTile(artist: artist),
                        ),
                      if (filteredAlbums.isNotEmpty)
                        _buildSection<Album>(
                          'Album',
                          filteredAlbums,
                          (album) => _AlbumTile(album: album),
                        ),
                      if (filteredPlaylists.isNotEmpty)
                        _buildSection<PlaylistUser>(
                          'Playlist',
                          filteredPlaylists,
                          (playlist) => _PlaylistTile(playlist: playlist),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final Song song;
  const _SongTile({required this.song});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        PlayingMusicInterface(songs: [song], currentIndex: 0),
              ),
            );
          },
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  song.songImage != null && song.songImage.isNotEmpty
                      ? Image.network(
                        song.songImage,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[800],
                      ),
            ),
            title: Text(
              song.songName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              song.artistName ?? '',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(Icons.music_note, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}

class _ArtistTile extends StatelessWidget {
  final Artist artist;
  const _ArtistTile({required this.artist});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {}, // TODO: Navigate to artist detail
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[700],
              backgroundImage:
                  artist.artistImage != null && artist.artistImage.isNotEmpty
                      ? NetworkImage(artist.artistImage)
                      : null,
              child:
                  artist.artistImage == null || artist.artistImage.isEmpty
                      ? const Icon(Icons.person, color: Colors.white70)
                      : null,
            ),
            title: Text(
              artist.artistName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Nghệ sĩ',
              style: TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.person, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  final Album album;
  const _AlbumTile({required this.album});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => AlbumSongsScreen(
                      albumId: album.albumId,
                      albumName: album.albumName,
                      albumImage: album.albumImage ?? '',
                      artistName: album.artistName ?? '',
                    ),
              ),
            );
          },
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  album.albumImage != null && album.albumImage.isNotEmpty
                      ? Image.network(
                        album.albumImage,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[800],
                      ),
            ),
            title: Text(
              album.albumName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Album',
              style: TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.album, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final PlaylistUser playlist;
  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {}, // TODO: Navigate to playlist detail
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.queue_music, color: Colors.white54),
            ),
            title: Text(
              playlist.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Playlist',
              style: TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.queue_music, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}

class _DiscoverSongCard extends StatelessWidget {
  final Song song;
  const _DiscoverSongCard({required this.song});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => PlayingMusicInterface(songs: [song], currentIndex: 0),
          ),
        );
      },
      child: Container(
        width: 110,
        height: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child:
                    song.songImage != null && song.songImage.isNotEmpty
                        ? Image.network(song.songImage, fit: BoxFit.cover)
                        : Container(color: Colors.grey[800]),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Text(
                    song.songName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> cat;
  const _CategoryCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cat["color"].withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(width: 12),
          Icon(cat["icon"], color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cat["title"],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
