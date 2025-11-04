import 'dart:convert';
import 'package:flutter_music_app/music/play_music/playing_music.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_music_app/model/song.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/config.dart';

class ArtistUserLib extends StatefulWidget {
  final int artistID;
  final int? userId;
  const ArtistUserLib({
    super.key,
    required this.artistID,
    required this.userId,
  });
  @override
  State<ArtistUserLib> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistUserLib> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _showStickyHeader = false;
  List<Song>? _songs = [];
  String? _artistImage;
  String? _artistName;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    fetchSongs()
        .then((data) {
          debugPrint("Fetch successful");
          setState(() {
            _songs = data;
            debugPrint("Songs loaded successfully: ${data.length} songs");
          });
        })
        .catchError((e) {
          debugPrint("Error occurred while fetching songs");
        });
    getImageArtist().then((value) {
      setState(() {
        _artistImage = value;
      });
    });
    getArtistName().then((value) {
      setState(() {
        _artistName = value;
      });
    });
    _checkFollow();
  }

  void _checkFollow() async {
    try {
      isFollowing = await checkUserFollowArtist(
        widget.userId!,
        widget.artistID,
      );
    } catch (e) {
      debugPrint('Lỗi: $e');
    }
  }

  void _scrollListener() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      _showStickyHeader = _scrollOffset > 200;
    });
  }

  void _playSong(Song song, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                PlayingMusicInterface(songs: _songs!, currentIndex: index),
      ),
    );
  }

  Future<bool> checkUserFollowArtist(int userId, int artistId) async {
    final uri = Uri.parse(
      '${ip}Artists/check?userId=$userId&artistId=$artistId',
    );
    // Lưu ý: dùng 10.0.2.2 nếu bạn chạy Flutter emulator để truy cập localhost

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['isFollowing'] == true;
    } else {
      throw Exception('Failed to check follow status');
    }
  }

  Future<List<Song>> fetchSongs() async {
    debugPrint("Starting API call...");
    try {
      final response = await http.get(
        Uri.parse('${ip}Artists/playlists/${widget.artistID}/songs'),
      );

      debugPrint("API Response Status: ${response.statusCode}");
      debugPrint("API Response Body length: ${response.body.length}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint("Parsed ${data.length} songs from API");

        final songs =
            data.map((json) {
              try {
                final song = Song.fromJson(json);
                debugPrint("Successfully parsed song: ${song.songName}");
                return song;
              } catch (e) {
                debugPrint("Error parsing song: $e");
                debugPrint("Problematic JSON: $json");
                rethrow;
              }
            }).toList();

        debugPrint("Total songs parsed: ${songs.length}");
        return songs;
      } else {
        throw Exception('Failed to load songs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load songs: $e');
    }
  }

  Future<String?> getImageArtist() async {
    final response = await http.get(
      Uri.parse('${ip}Artists/${widget.artistID}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['artistImage'] as String;
    } else {
      debugPrint("Lỗi: ${response.statusCode}");
      return null;
    }
  }

  Future<String?> getArtistName() async {
    final response = await http.get(
      Uri.parse('${ip}Artists/${widget.artistID}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['artistName'] as String;
    } else {
      debugPrint("Lỗi: ${response.statusCode}");
      return null;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background gradient từ ảnh artist
          if (_artistImage != null)
            Container(
              height: 350,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1DB954).withOpacity(0.8),
                    Color(0xFF1DB954).withOpacity(0.3),
                    Color(0xFF121212),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header với ảnh artist
              SliverAppBar(
                expandedHeight: 320,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Container(
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: EdgeInsets.only(top: 120, left: 20, right: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Artist image
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 30,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child:
                                _artistImage == null
                                    ? Container(
                                      color: Colors.grey[800],
                                      child: Icon(
                                        Icons.person,
                                        size: 100,
                                        color: Colors.grey[600],
                                      ),
                                    )
                                    : Image.network(
                                      _artistImage!,
                                      fit: BoxFit.cover,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Artist info và controls
              SliverToBoxAdapter(
                child: Container(
                  color: Color(0xFF121212),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Artist name
                      Text(
                        _artistName ?? 'Loading...',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Follower count (giả lập)
                      Text(
                        '${(_songs?.length ?? 0) * 12847} monthly listeners',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 32),

                      // Control buttons
                      Row(
                        children: [
                          // Follow button
                          Container(
                            height: 32,
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[600]!),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 16),

                          // More options
                          Container(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.more_horiz,
                                color: Colors.grey[400],
                                size: 24,
                              ),
                              onPressed: () {},
                            ),
                          ),

                          Spacer(),

                          // Shuffle button
                          Container(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.shuffle,
                                color: Colors.grey[400],
                                size: 24,
                              ),
                              onPressed: () {},
                            ),
                          ),

                          SizedBox(width: 16),

                          // Play button
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Color(0xFF1DB954),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.play_arrow,
                                color: Colors.black,
                                size: 28,
                              ),
                              onPressed: () {
                                if (_songs != null && _songs!.isNotEmpty) {
                                  _playSong(_songs![0], 0);
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 32),

                      // Popular section
                      Text(
                        'Popular',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Songs list
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (_songs == null || _songs!.isEmpty) {
                    return Container(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1DB954),
                        ),
                      ),
                    );
                  }

                  final song = _songs![index];
                  return _buildTrackItem(song, index);
                }, childCount: _songs?.length ?? 1),
              ),

              // Bottom padding
              SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // Sticky header khi scroll
          if (_showStickyHeader)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFF121212).withOpacity(0.95),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),

                        SizedBox(width: 16),

                        // Mini artist image
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(shape: BoxShape.circle),
                          child: ClipOval(
                            child:
                                _artistImage == null
                                    ? Container(color: Colors.grey[800])
                                    : Image.network(
                                      _artistImage!,
                                      fit: BoxFit.cover,
                                    ),
                          ),
                        ),

                        SizedBox(width: 16),

                        Expanded(
                          child: Text(
                            _artistName ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Mini controls
                        IconButton(
                          icon: Icon(Icons.shuffle, color: Colors.grey[400]),
                          onPressed: () {},
                        ),

                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(0xFF1DB954),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackItem(Song song, int index) {
    return Container(
      color: Color(0xFF121212),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _playSong(song, index);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                // Track number
                Container(
                  width: 32,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // Song image
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      image: NetworkImage(song.songImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // Song info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.songName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (song.artistName != null &&
                          song.artistName!.isNotEmpty)
                        Text(
                          song.artistName!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Play count (giả lập)
                Text(
                  '${(index + 1) * 1234567}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),

                SizedBox(width: 16),

                // More options
                IconButton(
                  icon: Icon(
                    Icons.more_horiz,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
