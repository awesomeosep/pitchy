class DataFile {
  String fileId;
  String fileName;
  String dataPath;
  List<String> songPaths;
  String splitType;
  DateTime uploadedDate;
  SongSettings settings;

  DataFile(this.fileId, this.fileName, this.dataPath, this.songPaths, this.splitType, this.uploadedDate, this.settings);

  static DataFile classFromTxt(dynamic json) {
    print(json["settings"]);
    return DataFile(
      json["fileId"],
      json["fileName"],
      json["dataPath"],
      List.from(json["songPaths"].map((item) => item.toString())),
      json["splitType"],
      DateTime.parse(json["uploadedDate"]),
      SongSettings.classFromTxt(json["settings"]),
    );
  }

  Map jsonFromClass() {
    Map settingsJson = settings.jsonFromClass();
    return {
      "fileId": fileId,
      "fileName": fileName,
      "dataPath": dataPath,
      "songPaths": songPaths,
      "splitType": splitType,
      "uploadedDate": uploadedDate.toString(),
      "settings": settingsJson,
    };
  }
}

class SongSettings {
  double pitch;
  double volume;

  SongSettings(this.pitch, this.volume);

  static SongSettings classFromTxt(dynamic json) {
    return SongSettings(json["pitch"], json["volume"]);
  }

  Map jsonFromClass() {
    return {"pitch": pitch, "volume": volume};
  }
}
