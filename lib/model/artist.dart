class Artist {
  final int artistId;
  final String artistName;
  final String artistImage;

  Artist({
    required this.artistId,
    required this.artistName,
    required this.artistImage,
  });

  factory Artist.fromJson(Map<String, dynamic> json) => Artist(
    artistId: json['artistId'],
    artistName: json['artistName'],
    artistImage: json['artistImage'],
  );
}
