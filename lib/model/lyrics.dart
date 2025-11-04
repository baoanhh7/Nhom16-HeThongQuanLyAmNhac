import 'package:http/http.dart' as http;
import 'lyricline.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class Lyrics {
  final List<LyricLine> lines;
  final String? error;

  Lyrics({required this.lines, this.error});

  factory Lyrics.fromJson(Map<String, dynamic> json) {
    final List<dynamic> linesJson = json['lines'] as List<dynamic>;
    return Lyrics(
      lines: linesJson.map((line) => LyricLine.fromJson(line)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'lines': lines.map((line) => line.toJson()).toList()};
  }

  static Future<Lyrics> fromUrl(String? url) async {
    if (url == null || url.isEmpty || url == "null") {
      return Lyrics(lines: [], error: "No lyrics URL provided");
    }

    try {
      debugPrint("Loading LRC from URL: $url");
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Convert response body to UTF-8
        final String decodedBody = utf8.decode(response.bodyBytes);
        // debugPrint("LRC content: $decodedBody");

        final lyrics = LyricLine.parseLrc(decodedBody);
        debugPrint("Parsed ${lyrics.length} lyric lines");
        return Lyrics(lines: lyrics);
      } else {
        debugPrint("Failed to load LRC: ${response.statusCode}");
        return Lyrics(
          lines: [],
          error: "Failed to load lyrics: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("Error loading LRC: $e");
      return Lyrics(lines: [], error: "Error loading lyrics: $e");
    }
  }

  String? getCurrentLyric(Duration currentPosition) {
    if (lines.isEmpty) return null;

    // Find the last lyric line that is before or at the current position
    for (int i = lines.length - 1; i >= 0; i--) {
      if (lines[i].timestamp <= currentPosition) {
        return lines[i].text;
      }
    }
    return null;
  }
}
