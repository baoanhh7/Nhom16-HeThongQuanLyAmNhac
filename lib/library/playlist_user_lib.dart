import 'dart:convert';
import 'package:flutter_music_app/constants/app_colors.dart';
import 'package:flutter_music_app/music/play_music/playing_music.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_music_app/model/song.dart';
import '../../config/config.dart';

class PlaylistUserLib extends StatefulWidget {
  final int playlistID;
  final String playlistName;
  const PlaylistUserLib({
    super.key,
    required this.playlistID,
    required this.playlistName,
  });
  @override
  State<PlaylistUserLib> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistUserLib> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _showStickyHeader = false;
  List<Song>? _songs = [];
  late String _playlistName;
  List<Song> _removedSongs = [];
  List<Song> suggestedSongs = [];
  List<Song> _filteredSongs = [];
  bool isLoadingSongs = true;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

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
          loadSuggestedSongs();
        })
        .catchError((e) {
          debugPrint("Error occurred while fetching songs");
        });
    _playlistName = widget.playlistName;
    debugPrint('🟩 Danh sách _songs đã có trong playlist:');
  }

  void _scrollListener() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      _showStickyHeader = _scrollOffset > 300;
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

  Future<List<Song>> fetchSongs() async {
    debugPrint("Starting API call...");
    try {
      final response = await http.get(
        Uri.parse('${ip}PlaylistUsers/playlists/${widget.playlistID}/songs'),
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

  List<String> _getPlaylistCoverImages() {
    if (_songs == null || _songs!.isEmpty) {
      return [];
    }

    // Lấy 4 bức ảnh cuối của danh sách
    List<String> images = [];
    int startIndex = _songs!.length >= 4 ? _songs!.length - 4 : 0;

    for (int i = startIndex; i < _songs!.length; i++) {
      images.add(_songs![i].songImage);
    }

    // Nếu không đủ 4 bức ảnh, lặp lại để đủ 4
    while (images.length < 4 && images.isNotEmpty) {
      images.addAll(images.take(4 - images.length));
    }

    return images.take(4).toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true, // Thêm dòng này
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F23),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildActionButtons()),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildTrackItem(_songs![index], index);
                  }, childCount: _songs?.length ?? 0),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            _buildStickyHeader(),
            _buildBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    double opacity = (1.0 - (_scrollOffset / 400)).clamp(0.0, 1.0);
    double scale = (1.0 - (_scrollOffset / 800)).clamp(0.8, 1.0);

    return AnimatedOpacity(
      opacity: opacity,
      duration: Duration(milliseconds: 100),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: MediaQuery.of(context).size.width, // Đảm bảo width đúng
          height: MediaQuery.of(context).size.height * 0.80,
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              _buildPlaylistCover(),
              SizedBox(height: 20),
              _buildPlaylistInfo(),
              SizedBox(height: 20),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistCover() {
    List<String> coverImages = _getPlaylistCoverImages();

    return Container(
      width: 280, // Giảm kích thước từ 300 xuống 280
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
          BoxShadow(
            color: Color(0xFF4C1D95).withOpacity(0.3),
            blurRadius: 50,
            offset: Offset(0, 25),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child:
            coverImages.isEmpty
                ? _buildDefaultCover()
                : _buildImageGrid(coverImages),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF4C1D95)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 80,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<String> images) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 1,
      crossAxisSpacing: 1,
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true, // Thêm shrinkWrap
      children:
          images.map((imageUrl) {
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.1)],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildPlaylistInfo() {
    return Container(
      width: MediaQuery.of(context).size.width, // Đảm bảo width đúng
      padding: EdgeInsets.symmetric(horizontal: 16), // Thêm padding
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF1DB954).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFF1DB954).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              "PLAYLIST",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1DB954),
                letterSpacing: 1,
              ),
            ),
          ),
          SizedBox(height: 16),
          ShaderMask(
            shaderCallback:
                (bounds) => LinearGradient(
                  colors: [Colors.white, Color(0xFFE0E7FF)],
                ).createShader(bounds),
            child: Text(
              _playlistName,
              style: TextStyle(
                fontSize: 28, // Giảm từ 32 xuống 28
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // Thêm overflow handling
              maxLines: 2, // Giới hạn số dòng
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note,
                size: 16,
                color: Colors.white.withOpacity(0.6),
              ),
              SizedBox(width: 6),
              Text(
                "${_songs?.length ?? 0} bài hát",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(Icons.shuffle, 48, false),
          SizedBox(width: 24),
          _buildPlayButton(),
          SizedBox(width: 24),
          _buildControlButton(
            Icons.more_horiz,
            48,
            false,
            onTap: () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.background,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                        // Thanh kéo
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Các tùy chọn
                        ListTile(
                          leading: const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                          ),
                          title: const Text(
                            'Chia sẻ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Chức năng chia sẻ
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.download_outlined,
                            color: Colors.white,
                          ),
                          title: const Text(
                            'Tải xuống',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Chức năng tải playlist
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.playlist_add_check,
                            color: Colors.white,
                          ),
                          title: const Text(
                            'Thêm vào danh sách phát này',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          onTap: () async {
                            final result = await showAddSongsToPlaylistModal(
                              context,
                              widget.playlistID,
                            );
                            // showAddSongsToPlaylistModal(
                            //   context,
                            //   widget.playlistID,
                            // );
                            if (result == true) {
                              // Load lại danh sách bài hát trong playlist
                              fetchSongs()
                                  .then((data) {
                                    debugPrint("Fetch successful");
                                    setState(() {
                                      _songs = data;
                                      debugPrint(
                                        "Songs loaded successfully: ${data.length} songs",
                                      );
                                    });
                                    loadSuggestedSongs();
                                  })
                                  .catchError((e) {
                                    debugPrint(
                                      "Error occurred while fetching songs",
                                    );
                                  }); //cập nhật UI
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.playlist_add,
                            color: Colors.white,
                          ),
                          title: const Text(
                            'Thêm vào danh sách phát khác',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Chọn playlist khác
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                          ),
                          title: const Text(
                            'Chỉnh sửa',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          onTap: () async {
                            final result = await showEditPlaylistModal(
                              context,
                              playlistID: widget.playlistID,
                              songs: _songs!,
                              initialName: _playlistName,
                              removedSongs: _removedSongs,
                              onNameChanged: (newName) {
                                setState(() {
                                  _playlistName = newName;
                                });
                              },
                              listKey: _listKey,
                              buildImageGrid: _buildImageGrid,
                              buildSongItem: _buildSongItem,
                              getPlaylistCoverImages: _getPlaylistCoverImages,
                            );

                            if (result == true) {
                              // Load lại danh sách bài hát trong playlist
                              fetchSongs()
                                  .then((data) {
                                    debugPrint("Fetch successful");
                                    setState(() {
                                      _songs = data;
                                      debugPrint(
                                        "Songs loaded successfully: ${data.length} songs",
                                      );
                                    });
                                    loadSuggestedSongs();
                                  })
                                  .catchError((e) {
                                    debugPrint(
                                      "Error occurred while fetching songs",
                                    );
                                  }); //cập nhật UI
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          title: const Text(
                            'Xoá playlist',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          onTap: () {
                            final rootContext =
                                context; // lưu context gốc trước async

                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text("Xác nhận xoá"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("Huỷ"),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context); // đóng dialog

                                          await Future.delayed(
                                            Duration(milliseconds: 100),
                                          );

                                          final url = Uri.parse(
                                            '${ip}PlaylistUsers/${widget.playlistID}',
                                          );
                                          final response = await http.delete(
                                            url,
                                          );

                                          if (!mounted) return;

                                          if (response.statusCode == 204) {
                                            // Dùng rootContext đã lưu
                                            Navigator.pop(
                                              rootContext,
                                              true,
                                            ); // ✅ an toàn
                                            ScaffoldMessenger.of(
                                              rootContext,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Xoá playlist thành công',
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              rootContext,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Xoá playlist thất bại',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Text(
                                          "Xoá",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            );
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
    );
  }

  Widget _buildSongItem(Song song, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Icon xoá bài hát
          GestureDetector(
            onTap: () {
              _removeSong(index);
            },
            child: const Icon(Icons.remove_circle, color: Colors.white),
          ),
          const SizedBox(width: 12),

          // Thông tin bài hát
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.songName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  song.artistName ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // Icon kéo/sắp xếp
          const Icon(Icons.drag_handle, color: Colors.white),
        ],
      ),
    );
  }

  void _removeSong(int index) {
    final removedSong = _songs![index];

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: _buildSongItem(removedSong, index),
      ),
      duration: const Duration(milliseconds: 300),
    );

    setState(() {
      _removedSongs.add(removedSong);
      _songs!.removeAt(index);
    });
  }

  Widget _buildPlayButton() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1ED760), Color(0xFF1DB954)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1DB954).withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            if (_songs != null && _songs!.isNotEmpty) {
              _playSong(_songs![0], 0);
            }
          },
          borderRadius: BorderRadius.circular(36),
          child: Center(
            child: Icon(Icons.play_arrow, color: Colors.white, size: 36),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(
    IconData icon,
    double size,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
            isActive
                ? Color(0xFF1DB954).withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color:
              isActive
                  ? Color(0xFF1DB954).withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => HapticFeedback.lightImpact(),
          borderRadius: BorderRadius.circular(size / 2),
          child: Center(
            child: Icon(
              icon,
              color: isActive ? Color(0xFF1DB954) : Colors.white,
              size: size * 0.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Flexible(
            // Thay đổi để tránh overflow
            child: _buildActionButton("Thêm bài hát", Icons.add_circle_outline),
          ),
          SizedBox(width: 12),
          Flexible(
            // Thay đổi để tránh overflow
            child: _buildActionButton("Chỉnh sửa", Icons.edit_outlined),
          ),
          Spacer(),
          _buildControlButton(Icons.download_outlined, 40, false),
          SizedBox(width: 12),
          _buildControlButton(Icons.share_outlined, 40, false),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ), // Giảm padding
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          SizedBox(width: 8),
          Flexible(
            // Thêm Flexible để tránh overflow
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackItem(Song song, int index) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _playSong(song, index);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Song Cover
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      song.songImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4C1D95), Color(0xFF667EEA)],
                            ),
                          ),
                          child: Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.songName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        song.artistName ?? 'Unknown Artist',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // More Options
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        // Show options menu
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Center(
                        child: Icon(
                          Icons.more_vert,
                          color: Colors.white.withOpacity(0.7),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyHeader() {
    List<String> coverImages = _getPlaylistCoverImages();

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      transform: Matrix4.translationValues(0, _showStickyHeader ? 0 : -100, 0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 90,
        decoration: BoxDecoration(
          color: Color(0xFF0F0F23).withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Mini Cover
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        coverImages.isEmpty
                            ? Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF4C1D95),
                                    Color(0xFF667EEA),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 24,
                              ),
                            )
                            : GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 0.5,
                              crossAxisSpacing: 0.5,
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              children:
                                  coverImages.map((imageUrl) {
                                    return Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: Color(0xFF4C1D95),
                                        );
                                      },
                                    );
                                  }).toList(),
                            ),
                  ),
                ),
                SizedBox(width: 16),

                // Playlist Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _playlistName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Controls
                _buildControlButton(Icons.shuffle, 40, false),
                SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1ED760), Color(0xFF1DB954)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (_songs != null && _songs!.isNotEmpty) {
                          _playSong(_songs![0], 0);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> showAddSongsToPlaylistModal(
    BuildContext context,
    int playlistId,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          // 👉 Dùng ở đây
          builder: (context, setStateModal) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.95,
              builder: (_, controller) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(
                                context,
                                true,
                              ); //  Trả về true nếu muốn load lại
                            },
                          ),

                          SizedBox(width: 12),
                          Text(
                            'Thêm vào danh sách phát này',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setStateModal(() {
                            _filteredSongs =
                                suggestedSongs.where((song) {
                                  return song.songName.toLowerCase().contains(
                                    value.toLowerCase(),
                                  );
                                }).toList();
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Danh sách bài hát
                      Expanded(
                        child:
                            isLoadingSongs
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : ListView.builder(
                                  controller: controller,
                                  itemCount: _filteredSongs.length,
                                  itemBuilder: (context, index) {
                                    final song = _filteredSongs[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          song.songImage,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (ctx, _, __) => const Icon(
                                                Icons.music_note,
                                                color: Colors.white,
                                              ),
                                        ),
                                      ),
                                      title: Text(
                                        song.songName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(
                                        song.artistName ?? '',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                        onPressed: () async {
                                          try {
                                            await addSongToPlaylist(
                                              playlistId,
                                              song.songId,
                                            );

                                            setStateModal(() {
                                              suggestedSongs.removeWhere(
                                                (s) => s.songId == song.songId,
                                              );
                                              _filteredSongs.removeAt(index);
                                            });

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Đã thêm "${song.songName}"',
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('Lỗi: $e'),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> loadSuggestedSongs() async {
    final allSuggested = await fetchSuggestedSongs();
    final songs = List<Song>.from(allSuggested);
    songs.removeWhere((s) => _songs!.any((p) => p.songId == s.songId));

    setState(() {
      suggestedSongs = songs;
      _filteredSongs = List.from(songs);
      isLoadingSongs = false;
    });
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    final response = await http.post(
      Uri.parse('${ip}PlaylistUsers/$playlistId/songs/$songId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Thêm bài hát thất bại');
    }
  }

  Future<List<Song>> fetchSuggestedSongs() async {
    final response = await http.get(Uri.parse('${ip}Songs'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => Song.fromJson(item)).toList();
    } else {
      throw Exception('Lỗi tải bài hát');
    }
  }

  Future<bool?> showEditPlaylistModal(
    BuildContext context, {
    required int playlistID,
    required List<Song> songs,
    required String initialName,
    required List<Song> removedSongs,
    required Function(String) onNameChanged,
    required GlobalKey<AnimatedListState> listKey,
    required Widget Function(List<String>) buildImageGrid,
    required Widget Function(Song, int) buildSongItem,
    required List<String> Function() getPlaylistCoverImages,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String editedName = initialName;
        return DraggableScrollableSheet(
          initialChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context, false);
                              },
                              child: const Text(
                                'Huỷ',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const Text(
                              'Chỉnh sửa Playlist',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                try {
                                  // Cập nhật tên playlist
                                  debugPrint('Tên Playlist: ${editedName}');
                                  final updateResponse = await http.put(
                                    Uri.parse(
                                      '${ip}PlaylistUsers/PLaylistUsersName/$playlistID',
                                    ),
                                    headers: {
                                      'Content-Type': 'application/json',
                                    },
                                    body: jsonEncode({
                                      'playlistName': editedName,
                                    }),
                                  );
                                  if (updateResponse.statusCode != 200) {
                                    throw Exception(
                                      'Không thể cập nhật playlist',
                                    );
                                  }
                                  debugPrint(
                                    'Status code: ${updateResponse.statusCode}',
                                  );
                                  debugPrint(
                                    'Response body: ${updateResponse.body}',
                                  );

                                  // Xoá các bài hát đã remove
                                  for (var song in removedSongs) {
                                    final deleteResponse = await http.delete(
                                      Uri.parse(
                                        '${ip}PlaylistUsers/playlists/$playlistID/songs/${song.songId}',
                                      ),
                                    );
                                    if (deleteResponse.statusCode != 200) {
                                      throw Exception(
                                        'Xoá bài hát thất bại: ${song.songName}',
                                      );
                                    }
                                  }
                                  if (!mounted) return;
                                  Navigator.pop(context, true); // ✅ Trả về true
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Đã cập nhật playlist thành công',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  debugPrint(e.toString());
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lỗi: ${e.toString()}'),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Lưu',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Ảnh playlist
                        Center(
                          child: Column(
                            children: [
                              SizedBox(
                                width: 160,
                                height: 160,
                                child: buildImageGrid(getPlaylistCoverImages()),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Thay đổi hình ảnh',
                                style: TextStyle(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Tên playlist
                        Center(
                          child: Column(
                            children: [
                              TextFormField(
                                initialValue: initialName,
                                onChanged: (value) {
                                  editedName = value;
                                  onNameChanged(value);
                                },
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Nhập tên playlist',
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Text(
                                  'Thêm phần mô tả',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  // Danh sách bài hát
                  SliverToBoxAdapter(
                    child: AnimatedList(
                      key: listKey,
                      initialItemCount: songs.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index, animation) {
                        final song = songs[index];
                        return SizeTransition(
                          sizeFactor: animation,
                          child: buildSongItem(song, index),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBackButton() {
    return SafeArea(
      child: Positioned(
        top: 20,
        left: 20,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(22),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
