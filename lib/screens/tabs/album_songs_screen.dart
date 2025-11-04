import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/config.dart';
import '../../model/song.dart';
import '../../music/play_music/playing_music.dart';

class AlbumSongsScreen extends StatefulWidget {
  final int albumId;
  final String albumName;
  final String albumImage;
  final String artistName;
  const AlbumSongsScreen({
    Key? key,
    required this.albumId,
    required this.albumName,
    required this.albumImage,
    required this.artistName,
  }) : super(key: key);

  @override
  State<AlbumSongsScreen> createState() => _AlbumSongsScreenState();
}

class _AlbumSongsScreenState extends State<AlbumSongsScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    try {
      final response = await http.get(
        Uri.parse('${ip}Albums/${widget.albumId}/songs'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _songs = data.map((json) => Song.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = Colors.deepPurpleAccent.shade100;
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 240,
                    backgroundColor: Colors.black,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentColor.withOpacity(0.5),
                                  Colors.black,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 24,
                            bottom: 32,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.4),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  widget.albumImage,
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (ctx, _, __) => const Icon(
                                        Icons.album,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 150,
                            bottom: 48,
                            right: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.albumName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        widget.artistName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _songs.isEmpty
                      ? SliverFillRemaining(
                        child: const Center(
                          child: Text(
                            'Không có bài hát nào trong album này.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                      : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final song = _songs[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PlayingMusicInterface(
                                          songs: _songs,
                                          currentIndex: index,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: accentColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        song.songImage,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (ctx, _, __) => const Icon(
                                              Icons.music_note,
                                              color: Colors.white,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            song.songName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            song.artistName ?? '',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
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
                                        color: Colors.white54,
                                      ),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }, childCount: _songs.length),
                      ),
                ],
              ),
    );
  }
}
