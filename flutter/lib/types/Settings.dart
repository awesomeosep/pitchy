import 'package:spleeter_flutter_app/types/Playlists.dart';

class AppSettings {
  List<PlaylistData> playlists;

  AppSettings(this.playlists);

  static AppSettings classFromTxt(dynamic json) {
    print(json["playlists"].length);
    List<PlaylistData> playlists = [];
    if (json["playlists"].length > 0) {
      for (int i = 0; i < json["playlists"].length; i++) {
        playlists.add(PlaylistData.classFromTxt(json["playlists"][i]));
      }
    }
    print(playlists);
    print(playlists.runtimeType);
    return AppSettings(playlists);
  }

  Map jsonFromClass() {
    List<Map> playlistsJson = playlists.map((item) => item.jsonFromClass()).toList();
    return {"playlists": playlistsJson};
  }
}
