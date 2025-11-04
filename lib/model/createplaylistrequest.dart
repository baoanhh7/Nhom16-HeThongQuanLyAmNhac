class CreatePlaylistRequest {
  final String name;
  final int userId;
  final List<int> songIds;

  CreatePlaylistRequest({
    required this.name,
    required this.userId,
    required this.songIds,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'userId': userId, 'songIds': songIds};
  }
}
