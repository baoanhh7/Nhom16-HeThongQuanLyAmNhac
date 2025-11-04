import 'song.dart';

class Playlist {
  final int playlistId;
  final String playlistName;
  final String playlistImage;
  final List<Song> songs;

  Playlist({
    required this.playlistId,
    required this.playlistName,
    required this.playlistImage,
    required this.songs,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      playlistId: json['playlistId'],
      playlistName: json['playlistName'],
      playlistImage: json['playlistImage'] ?? '',
      songs:
          (json['songs'] as List? ?? []).map((e) => Song.fromJson(e)).toList(),
    );
  }
}
