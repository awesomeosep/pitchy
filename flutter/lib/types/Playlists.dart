class PlaylistData {
  String playlistId;
  String playlistName;
  String playlistDescription;
  List<String> songIds;

  PlaylistData(this.playlistId, this.playlistName, this.playlistDescription, this.songIds);

  static PlaylistData classFromTxt(dynamic json) {
    print(json);
    print(PlaylistData(
      json["playlistId"],
      json["playlistName"],
      json["playlistDescription"],
      json["songIds"].length > 0 ? List.from(json["songIds"].map((item) => item.toString())) : [],
    ));
    return PlaylistData(
      json["playlistId"],
      json["playlistName"],
      json["playlistDescription"],
      json["songIds"].length > 0 ? List.from(json["songIds"].map((item) => item.toString())) : [],
    );
  }

  Map jsonFromClass() {
    return {"playlistId": playlistId, "playlistName": playlistName, "playlistDescription": playlistDescription, "songIds": songIds};
  }
}
