import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spleeter_flutter_app/types/ListenArguments.dart';
import 'package:spleeter_flutter_app/types/Settings.dart';
import 'package:spleeter_flutter_app/types/SongData.dart';

class HomeList extends StatefulWidget {
  const HomeList({super.key});

  @override
  State<HomeList> createState() => _HomeListState();
}

class _HomeListState extends State<HomeList> {
  bool gotFiles = false;
  List<FileSystemEntity> splitSongFiles = [];
  List<DataFile> splitSongData = [];
  String viewMode = "uploads";
  AppSettings? settings = null;

  Future<void> deleteSong(String fileId) async {
    final dataFile = File(splitSongData.where((i) => i.fileId == fileId).toList()[0].dataPath);
    if (await dataFile.exists()) {
      await dataFile.delete();
      print('Data file deleted successfully');
      getFiles();
    } else {
      print('Data file does not exist');
    }
    final songFiles = splitSongData.where((i) => i.fileId == fileId).toList()[0].songPaths.map((p) => File(p)).toList();
    for (int i = 0; i < songFiles.length; i++) {
      bool fileExists = await songFiles[i].exists();
      if (fileExists) {
        await songFiles[i].delete();
      }
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final directory = await getApplicationDocumentsDirectory();
    final appSettingsPath = "${directory.path}/app/settings.txt";
    AppSettings newSettings = settings!;
    newSettings.playlists = newSettings.playlists.where((item) => item.playlistId != playlistId).toList();
    final newSettingsJson = newSettings.jsonFromClass();
    await File(appSettingsPath).writeAsString(jsonEncode(newSettingsJson));
  }

  Future<void> deleteAll() async {
    final directory = await getApplicationDocumentsDirectory();
    final dataDirectoryPath = "${directory.path}/songs/data";
    final dataDirectory = Directory(dataDirectoryPath);
    if (await dataDirectory.exists()) {
      await for (FileSystemEntity entity in dataDirectory.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
      print('All files in the folder deleted successfully!');
      getFiles();
    } else {
      print('Folder does not exist.');
    }

    final fileDirectoryPath = "${directory.path}/songs/audio_files";
    final fileDirectory = Directory(fileDirectoryPath);
    if (await fileDirectory.exists()) {
      await for (FileSystemEntity entity in fileDirectory.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
      print('All files in the folder deleted successfully! 2');
    } else {
      print('Folder does not exist. 2');
    }
  }

  Future<void> deleteAllPlaylists() async {
    final directory = await getApplicationDocumentsDirectory();
    final appSettingsPath = "${directory.path}/app/settings.txt";
    AppSettings newSettings = settings!;
    newSettings.playlists = [];
    final newSettingsJson = newSettings.jsonFromClass();
    print(newSettingsJson);
    await File(appSettingsPath).writeAsString(jsonEncode(newSettingsJson));
  }

  Future<void> getFiles() async {
    setState(() {
      splitSongData = [];
      splitSongFiles = [];
    });

    // get song dat
    final directory = await getApplicationDocumentsDirectory();
    final dataDirectoryPath = "${directory.path}/songs/data";
    final dataDirectory = Directory(dataDirectoryPath);
    final List<FileSystemEntity> files = dataDirectory.listSync(recursive: true);
    setState(() {
      splitSongFiles = files.where((entity) => entity is File && entity.path.endsWith(".txt")).toList();
    });
    for (int i = 0; i < splitSongFiles.length; i++) {
      File thisFile = File(splitSongFiles[i].path);
      String dataString = await thisFile.readAsString();
      dynamic dataJson = jsonDecode(dataString);
      print(dataJson);
      DataFile fileData = DataFile.classFromTxt(dataJson);
      setState(() {
        splitSongData.add(fileData);
      });
    }

    // get playlists
    final appSettingsPath = "${directory.path}/app/settings.txt";
    final appSettingsDirectory = Directory("${directory.path}/app");
    final appSettingsFile = File(appSettingsPath);
    final appSettingsExists = await appSettingsFile.exists();
    if (appSettingsExists) {
      print("settings exists");
      String settingsDataString = await appSettingsFile.readAsString();
      dynamic settingsDataJson = jsonDecode(settingsDataString);
      AppSettings settingsData = AppSettings.classFromTxt(settingsDataJson);
      setState(() {
        settings = settingsData;
      });
    } else {
      print("settings does not exist");
      if (!(await appSettingsDirectory.exists())) {
        await appSettingsDirectory.create(recursive: true);
      }
      final newSettings = AppSettings([]).jsonFromClass();
      await File(appSettingsPath).writeAsString(jsonEncode(newSettings));
    }

    setState(() {
      gotFiles = true;
    });
    print(splitSongData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome to pitchy!"),
                  Text(
                    "Here you can navigate to your uploaded songs, playlists, and groups!",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text("Uploads"),
              onTap: () {
                setState(() {
                  viewMode = "uploads";
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Playlists"),
              onTap: () {
                setState(() {
                  viewMode = "playlists";
                });
                Navigator.pop(context);
              },
            ),
            ListTile(title: const Text("Settings"), onTap: () {}),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            child: Icon(Icons.upload),
            onPressed: () async {
              Navigator.pushNamed(context, '/split');
            },
          ),
        ],
      ),
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Home"),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.all(16.0),
        child: SingleChildScrollView(
          child: viewMode == "uploads"
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Uploaded Songs", style: TextStyle(fontSize: 18.0)),
                    SizedBox(height: 16),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      direction: Axis.horizontal,
                      children: [
                        FilledButton.tonalIcon(
                          style: ButtonStyle(
                            padding: WidgetStatePropertyAll(EdgeInsetsGeometry.fromLTRB(10, 0, 10, 0)),
                          ),
                          label: Text("Refresh"),
                          onPressed: () async {
                            await getFiles();
                          },
                          icon: Icon(Icons.refresh),
                        ),
                        FilledButton.tonalIcon(
                          style: ButtonStyle(
                            padding: WidgetStatePropertyAll(EdgeInsetsGeometry.fromLTRB(10, 0, 10, 0)),
                          ),
                          label: Text("Delete All"),
                          onPressed: () async {
                            await deleteAll();
                          },
                          icon: Icon(Icons.delete),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    (gotFiles)
                        ? (splitSongData.isNotEmpty
                              ? Column(
                                  children: splitSongData.map((file) {
                                    return ListTile(
                                      leading: Icon(Icons.music_note),
                                      title: Text(file.fileName),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () {
                                          deleteSong(file.fileId);
                                        },
                                      ),
                                      onTap: () => {Navigator.pushNamed(context, '/listen', arguments: file.fileId)},
                                    );
                                  }).toList(),
                                )
                              : Text("No songs found"))
                        : Text("Refresh to load songs"),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Playlists", style: TextStyle(fontSize: 18.0)),
                    SizedBox(height: 16),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      direction: Axis.horizontal,
                      children: [
                        FilledButton.tonalIcon(
                          style: ButtonStyle(
                            padding: WidgetStatePropertyAll(EdgeInsetsGeometry.fromLTRB(10, 0, 10, 0)),
                          ),
                          label: Text("New Playlist"),
                          onPressed: () async {
                            Navigator.pushNamed(context, "/newPlaylist");
                          },
                          icon: Icon(Icons.add),
                        ),
                        FilledButton.tonalIcon(
                          style: ButtonStyle(
                            padding: WidgetStatePropertyAll(EdgeInsetsGeometry.fromLTRB(10, 0, 10, 0)),
                          ),
                          label: Text("Refresh"),
                          onPressed: () async {
                            await getFiles();
                          },
                          icon: Icon(Icons.refresh),
                        ),
                        FilledButton.tonalIcon(
                          style: ButtonStyle(
                            padding: WidgetStatePropertyAll(EdgeInsetsGeometry.fromLTRB(10, 0, 10, 0)),
                          ),
                          label: Text("Delete All"),
                          onPressed: () async {
                            await deleteAllPlaylists();
                          },
                          icon: Icon(Icons.delete),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    (gotFiles)
                        ? (settings!.playlists.isNotEmpty
                              ? Column(
                                  children: settings!.playlists.map((playlist) {
                                    return ListTile(
                                      leading: Icon(Icons.playlist_play),
                                      title: Text(playlist.playlistName),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () {
                                          deletePlaylist(playlist.playlistId);
                                        },
                                      ),
                                      onTap: () => {
                                        Navigator.pushNamed(
                                          context,
                                          '/listen',
                                          arguments: ListenArguments("playlist", playlist.playlistId),
                                        ),
                                      },
                                    );
                                  }).toList(),
                                )
                              : Text("No playlists found"))
                        : Text("Refresh to load songs"),
                  ],
                ),
        ),
      ),
    );
  }
}
