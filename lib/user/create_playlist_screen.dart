import 'dart:convert';
import 'package:flutter_music_app/model/createplaylistrequest.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/song.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../config/config.dart';

class CreatePlaylistScreen extends StatefulWidget {
  const CreatePlaylistScreen({super.key});
  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  int _step = 0;
  List<Song>? _songs = [];
  String _playlistName = '';
  Set<int> _selectedSongIndexes = {};
  Set<int> _songID = {};

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo danh sách phát')),
      body: _step == 0 ? _buildNameStep() : _buildSongSelectionStep(),
    );
  }

  @override
  void initState() {
    super.initState();
    debugPrint("Initializing...");
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

  Future<bool> createPlaylist(CreatePlaylistRequest request) async {
    final url = Uri.parse('${ip}PlaylistUsers/CreateWithSongs');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    return response.statusCode == 201;
  }

  Future<List<Song>> fetchSongs() async {
    debugPrint("Starting API call...");
    try {
      final response = await http.get(
        Uri.parse('${ip}Songs'),
        //Uri.parse('http://192.168.29.101:5207/api/Songs'),
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
      debugPrint("LibraryTab: Error in fetchSongs: $e");
      throw Exception('Failed to load songs: $e');
    }
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Đặt tên cho danh sách phát của bạn',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Tên danh sách phát',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _playlistName = value),
              validator:
                  (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Vui lòng nhập tên danh sách phát'
                          : null,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _step = 1);
                  }
                },
                child: const Text('Tiếp tục'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongSelectionStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Chọn bài hát cho "$_playlistName"',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _songs?.length,
            itemBuilder: (context, index) {
              final song = _songs![index];
              final selected = _selectedSongIndexes.contains(index);
              return ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      image: NetworkImage(song.songImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(song.songName),
                subtitle: Text(song.artistName!),
                trailing: Checkbox(
                  value: selected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedSongIndexes.add(index);
                        _songID.add(song.songId);
                      } else {
                        _selectedSongIndexes.remove(index);
                        _songID.remove(song.songId);
                      }
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedSongIndexes.remove(index);
                      _songID.remove(song.songId);
                    } else {
                      _selectedSongIndexes.add(index);
                      _songID.add(song.songId);
                    }
                  });
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _selectedSongIndexes.isNotEmpty
                      ? () async {
                        final userId = await getUserIdFromToken();
                        final selectedSongs =
                            _selectedSongIndexes
                                .map((i) => _songs![i])
                                .toList();

                        final request = CreatePlaylistRequest(
                          name: _playlistName,
                          userId: userId!, // hoặc lấy từ tài khoản đăng nhập
                          songIds: _songID.toList(),
                        );

                        final success = await createPlaylist(request);
                        if (!mounted) return;
                        if (success) {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Tạo thành công!'),
                                  content: Text(
                                    'Đã tạo playlist "$_playlistName" với ${selectedSongs.length} bài hát.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context); // đóng dialog
                                        Navigator.pop(
                                          context,
                                          true,
                                        ); // quay về trang trước
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                          );
                        } else {
                          // lỗi tạo
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tạo playlist thất bại'),
                            ),
                          );
                        }
                      }
                      : null,
              child: const Text('Tạo danh sách phát'),
            ),
          ),
        ),
      ],
    );
  }
}
