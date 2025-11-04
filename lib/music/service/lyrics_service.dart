import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../model/lyrics.dart';

class LyricsService {
  static Future<Lyrics?> fetchLyrics(String? lyricsUrl) async {
    if (lyricsUrl == null) return null;

    try {
      final response = await http.get(Uri.parse(lyricsUrl));
      if (response.statusCode == 200) {
        return Lyrics.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching lyrics: $e');
    }
    return null;
  }
}
