class PlaylistUser {
  final int id;
  final String name;

  PlaylistUser({required this.id, required this.name});

  factory PlaylistUser.fromJson(Map<String, dynamic> json) =>
      PlaylistUser(id: json['id'], name: json['name']);
}
