class Album {
  final int albumId;
  final String albumName;
  final String albumImage;
  final String artistName;

  Album({
    required this.albumId,
    required this.albumName,
    required this.albumImage,
    required this.artistName,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      albumId: json['albumId'],
      albumName: json['albumName'] ?? '',
      albumImage: json['albumImage'] ?? '',
      artistName: json['artistName'] ?? '',
    );
  }
}
