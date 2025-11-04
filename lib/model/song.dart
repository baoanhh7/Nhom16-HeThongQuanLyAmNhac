class Song {
  // final String id;
  // final String title;
  // final String album;
  // final String artist;
  // final String source;
  // final String image;
  // final int duration;
  // final bool favorite;
  // final int counter;
  // final int replay;
  // final String? lyricsUrl; // URL to fetch lyrics
  final int songId;
  final String songName;
  final String songImage;
  final String? linkSong;
  final String? linkLrc;
  final int? views;
  final String? artistName;

  // bool favorite;
  // int counter;
  // int replay;

  // Song({
  //   required this.id,
  //   required this.title,
  //   required this.album,
  //   required this.artist,
  //   required this.source,
  //   required this.image,
  //   required this.duration,
  //   this.favorite = false,
  //   this.counter = 0,
  //   this.replay = 0,
  //   this.lyricsUrl,
  // });
  Song({
    required this.songId,
    required this.songName,
    required this.songImage,
    this.linkSong,
    this.linkLrc,
    this.views,
    this.artistName,
  });
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      songId: json['songId'],
      songName: json['songName'] ?? '',
      songImage: json['songImage'] ?? '',
      linkSong: json['linkSong'] ?? '',
      linkLrc: json['linkLrc'] ?? '',
      views: json['views'] ?? 0,
      artistName: json['artistName'] ?? 'Unknown Artist',
    );
  }

  // factory Song.fromJson(Map<String, dynamic> json) {
  //   return Song(
  //     id: json['id'] as String,
  //     title: json['title'] as String,
  //     album: json['album'] as String,
  //     artist: json['artist'] as String,
  //     source: json['source'] as String,
  //     image: json['image'] as String,
  //     duration: json['duration'] as int,
  //     favorite: json['favorite'] == 'true',
  //     counter: json['counter'] as int,
  //     replay: json['replay'] as int,
  //     lyricsUrl: json['lyricsUrl'] as String?,
  //   );
  // }

  // Map<String, dynamic> toJson() {
  //   return {
  //     'id': id,
  //     'title': title,
  //     'album': album,
  //     'artist': artist,
  //     'source': source,
  //     'image': image,
  //     'duration': duration,
  //     'favorite': favorite.toString(),
  //     'counter': counter,
  //     'replay': replay,
  //     'lyricsUrl': lyricsUrl,
  //   };
  // }

  // @override
  // bool operator ==(Object other) =>
  //     identical(this, other) ||
  //     other is Song && runtimeType == other.runtimeType && id == other.id;

  // @override
  // int get hashCode => id.hashCode;

  // @override
  // String toString() {
  //   return 'Song{id: $id, title: $title, album: $album, artist: $artist, source: $source, image: $image, duration: $duration}';
  // }
}
