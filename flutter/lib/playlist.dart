import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spleeter_flutter_app/types/ListenArguments.dart';
import 'package:spleeter_flutter_app/types/Playlists.dart';
import 'package:spleeter_flutter_app/types/Settings.dart';
import 'dart:io';

import 'package:spleeter_flutter_app/types/SongData.dart';

class OpenPlaylist extends StatefulWidget {
  const OpenPlaylist({super.key});

  @override
  State<OpenPlaylist> createState() => _OpenPlaylistState();
}

class _OpenPlaylistState extends State<OpenPlaylist> {
  late String? playlistId;
  AppSettings? settings;
  PlaylistData? thisPlaylistData;
  TextEditingController playlistNameController = TextEditingController();
  TextEditingController playlistDescriptionController = TextEditingController();
  // List<DataFile> songsData = [];
  bool gotFiles = false;
  List<DataFile> allUserSongsData = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String) {
        setState(() {
          gotFiles = false;
        });
        playlistId = arg;
        final messenger = ScaffoldMessenger.of(context);
        try {
          // get settings
          final directory = await getApplicationDocumentsDirectory();
          final settingsFile = File("${directory.path}/app/settings.txt");
          if (playlistId != null && settingsFile != null) {
            setState(() {
              allUserSongsData = [];
            });
            String settingsString = await settingsFile.readAsString();
            dynamic settingsJson = jsonDecode(settingsString);
            setState(() {
              settings = AppSettings.classFromTxt(settingsJson);
              if (settings != null) {
                thisPlaylistData = settings!.playlists.where((item) => item.playlistId == playlistId).toList()[0];
              }
            });

            // get selected songs data
            final dataDirectoryPath = "${directory.path}/songs/data";
            final dataDirectory = Directory(dataDirectoryPath);
            final List<FileSystemEntity> songDataFiles = dataDirectory.listSync(recursive: true);
            for (int i = 0; i < songDataFiles.length; i++) {
              File thisFile = File(songDataFiles[i].path);
              String dataString = await thisFile.readAsString();
              dynamic dataJson = jsonDecode(dataString);
              DataFile fileData = DataFile.classFromTxt(dataJson);
              setState(() {
                allUserSongsData.add(fileData);
              });
            }
            // for (int i = 0; i < thisPlaylistData!.songIds.length; i++) {
            //   final songPath = "${directory.path}/songs/data/${thisPlaylistData!.songIds[i]}";
            //   final songFile = File(songPath);
            //   String songString = await songFile.readAsString();
            //   dynamic songJson = jsonDecode(songString);
            //   DataFile songData = DataFile.classFromTxt(songJson);

            //   setState(() {
            //     songsData.add(songData);
            //   });
            // }
          }
          setState(() {
            gotFiles = true;
          });
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('Could not load playlist ID $playlistId')));
        }
      }
    });
  }

  void savePlaylistInfo() async {
    final directory = await getApplicationDocumentsDirectory();
    final appSettingsPath = "${directory.path}/app/settings.txt";
    String oldSettingsString = await File(appSettingsPath).readAsString();
    dynamic oldJson = jsonDecode(oldSettingsString);
    AppSettings oldSettings = AppSettings.classFromTxt(oldJson);

    PlaylistData newPlaylist = thisPlaylistData!;
    newPlaylist.playlistName = playlistNameController.text;
    newPlaylist.playlistDescription = playlistDescriptionController.text;

    oldSettings.playlists.removeWhere((item) => item.playlistId == playlistId);
    oldSettings.playlists.add(newPlaylist);

    final newSettingsJson = oldSettings.jsonFromClass();
    await File(appSettingsPath).writeAsString(jsonEncode(newSettingsJson));
  }

  void deleteSongFromPlaylist(String songId) async {}

  void addSongToPlaylist() async {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext context) {
        return Container(
          height: 500,
          width: double.maxFinite,
          child: Padding(
            padding: EdgeInsetsGeometry.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text('Pick a song:'),
                SizedBox(height: 16),
                (allUserSongsData.isEmpty)
                    ? Text("You have not uplaoded any songs yet.")
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: allUserSongsData.map((song) {
                          return ListTile(
                            leading: Icon(Icons.playlist_play),
                            title: Text(song.fileName),
                            onTap: () async {
                              final directory = await getApplicationDocumentsDirectory();
                              final appSettingsPath = "${directory.path}/app/settings.txt";
                              String oldSettingsString = await File(appSettingsPath).readAsString();
                              dynamic oldJson = jsonDecode(oldSettingsString);
                              AppSettings oldSettings = AppSettings.classFromTxt(oldJson);

                              PlaylistData newPlaylist = thisPlaylistData!;
                              newPlaylist.songIds.add(song.fileId);

                              oldSettings.playlists.removeWhere((item) => item.playlistId == playlistId);
                              oldSettings.playlists.add(newPlaylist);

                              final newSettingsJson = oldSettings.jsonFromClass();
                              await File(appSettingsPath).writeAsString(jsonEncode(newSettingsJson));
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                SizedBox(height: 16),
                FilledButton.tonal(onPressed: () => {Navigator.pop(context)}, child: Text('Close')),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    playlistId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: Text(thisPlaylistData?.playlistName ?? 'Playlist')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Songs", style: TextStyle(fontSize: 18.0)),
              SizedBox(height: 16),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                direction: Axis.horizontal,
                children: [
                  FilledButton.tonalIcon(
                    style: ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsetsGeometry.fromLTRB(10, 0, 10, 0))),
                    label: Text("Play All"),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/listen',
                        arguments: ListenArguments("playlist", playlistId!, thisPlaylistData!.songIds[0]),
                      );
                    },
                    icon: Icon(Icons.playlist_play),
                  ),
                  FilledButton.tonalIcon(
                    style: ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsetsGeometry.fromLTRB(10, 0, 10, 0))),
                    label: Text("Add Song"),
                    onPressed: addSongToPlaylist,
                    icon: Icon(Icons.add),
                  ),
                ],
              ),
              SizedBox(height: 16),
              (gotFiles)
                  ? (allUserSongsData.isNotEmpty && (thisPlaylistData?.songIds.isNotEmpty ?? false)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: thisPlaylistData!.songIds.map((songId) {
                              return ListTile(
                                leading: Icon(Icons.play_arrow),
                                title: Text(allUserSongsData.firstWhere((item) => item.fileId == songId).fileName),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    deleteSongFromPlaylist(songId);
                                  },
                                ),
                                onTap: () => {
                                  Navigator.pushNamed(
                                    context,
                                    '/listen',
                                    arguments: ListenArguments("playlist", playlistId!, songId),
                                  ),
                                },
                              );
                            }).toList(),
                          )
                        : Column(children: [Text("No songs found")]))
                  : Text("Refresh to load songs"),
            ],
          ),
        ),
      ),
    );
  }
}
