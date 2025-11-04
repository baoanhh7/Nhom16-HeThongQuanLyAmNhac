import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import '../../config/config.dart';
import '../model/song.dart';
import '../../music/play_music/playing_music.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;
  int? userId;

  @override
  void initState() {
    super.initState();
    fetchUserIdAndHistory();
  }

  Future<void> fetchUserIdAndHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null || JwtDecoder.isExpired(token)) return;
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    userId = int.tryParse(decodedToken['nameid'].toString());
    await fetchHistorySongs();
  }

  Future<void> fetchHistorySongs() async {
    setState(() => _isLoading = true);
    final response = await http.get(Uri.parse('${ip}Users/$userId/history'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _songs = data.map((json) => Song.fromJson(json)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> clearHistory() async {
    final response = await http.delete(Uri.parse('${ip}Users/$userId/history'));
    if (response.statusCode == 200 || response.statusCode == 204) {
      setState(() {
        _songs.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử nghe nhạc'),
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed:
                _songs.isEmpty
                    ? null
                    : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              backgroundColor: AppColors.primaryDark,
                              title: const Text(
                                'Xóa lịch sử?',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                'Bạn có chắc muốn xóa toàn bộ lịch sử nghe nhạc?',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text(
                                    'Hủy',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                ),
                                TextButton(
                                  child: const Text(
                                    'Xóa',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        await clearHistory();
                      }
                    },
            tooltip: 'Xóa lịch sử',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _songs.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      color: AppColors.primaryColor,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa có lịch sử nghe nhạc',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  final song = _songs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Material(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(16),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
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
                            vertical: 10,
                            horizontal: 10,
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child:
                                    song.songImage.isNotEmpty
                                        ? Image.network(
                                          song.songImage,
                                          width: 54,
                                          height: 54,
                                          fit: BoxFit.cover,
                                        )
                                        : Container(
                                          width: 54,
                                          height: 54,
                                          color: const Color.fromARGB(
                                            255,
                                            33,
                                            62,
                                            43,
                                          ).withAlpha((0.18 * 255).round()),
                                          child: const Icon(
                                            Icons.music_note,
                                            color: Color.fromARGB(
                                              255,
                                              47,
                                              78,
                                              58,
                                            ),
                                            size: 32,
                                          ),
                                        ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.songName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      song.artistName ?? '',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      backgroundColor: AppColors.primaryDark,
    );
  }
}
