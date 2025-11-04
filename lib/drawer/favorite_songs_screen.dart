import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import '../../config/config.dart';
import '../../model/song.dart';
import '../../music/play_music/playing_music.dart';
import '../../main.dart'; // import routeObserver
import '../constants/app_colors.dart';

class FavoriteSongsScreen extends StatefulWidget {
  const FavoriteSongsScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteSongsScreen> createState() => _FavoriteSongsScreenState();
}

class _FavoriteSongsScreenState extends State<FavoriteSongsScreen>
    with RouteAware {
  List<Song> _songs = [];
  bool _isLoading = true;
  int? userId;

  @override
  void initState() {
    super.initState();
    fetchUserIdAndSongs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back to this screen
    fetchUserIdAndSongs();
  }

  Future<void> fetchUserIdAndSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null || JwtDecoder.isExpired(token)) return;
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    userId = int.tryParse(decodedToken['nameid'].toString());
    await fetchFavoriteSongs();
  }

  Future<void> fetchFavoriteSongs() async {
    setState(() => _isLoading = true);
    final response = await http.get(
      Uri.parse('${ip}Users/$userId/favorite-songs'),
    );
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

  Future<void> removeFavorite(int songId) async {
    final response = await http.delete(
      Uri.parse('${ip}Users/$userId/favorite-songs/$songId'),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      setState(() {
        _songs.removeWhere((s) => s.songId == songId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài hát yêu thích'),
        backgroundColor: AppColors.primaryDark,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _songs.isEmpty
              ? Center(
                child: Text(
                  'Bạn chưa có bài hát yêu thích nào!',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              )
              : ListView.separated(
                itemCount: _songs.length,
                separatorBuilder: (_, __) => SizedBox.shrink(),
                itemBuilder: (context, index) {
                  final song = _songs[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
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
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          song.songImage,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (ctx, _, __) => const Icon(
                                Icons.music_note,
                                color: AppColors.primaryColor,
                              ),
                        ),
                      ),
                      title: Text(
                        song.songName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artistName ?? '',
                        style: const TextStyle(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.favorite,
                          color: AppColors.primaryColor,
                        ),
                        onPressed: () => removeFavorite(song.songId),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      tileColor: Colors.transparent,
                    ),
                  );
                },
              ),
      backgroundColor: AppColors.background,
    );
  }
}
