class LyricLine {
  final Duration timestamp;
  final String text;

  LyricLine({required this.timestamp, required this.text});

  factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      timestamp: Duration(milliseconds: json['timestamp'] as int),
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'timestamp': timestamp.inMilliseconds, 'text': text};
  }

  static List<LyricLine> parseLrc(String lrcContent) {
    final List<LyricLine> lyrics = [];
    final lines = lrcContent.split('\n');

    for (var line in lines) {
      if (line.trim().isEmpty) continue;

      // Parse timestamp [mm:ss.xx]
      final timeRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');
      final match = timeRegex.firstMatch(line);

      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!.padRight(3, '0'));

        final timestamp = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        // Get the text after the timestamp
        final text = line.substring(match.end).trim();
        if (text.isNotEmpty) {
          lyrics.add(LyricLine(timestamp: timestamp, text: text));
        }
      }
    }

    // Sort lyrics by timestamp
    lyrics.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lyrics;
  }
}
