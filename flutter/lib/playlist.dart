import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pitchy/types/listen_arguments.dart';
import 'package:pitchy/types/playlists.dart';
import 'package:pitchy/types/app_settings.dart';
import 'dart:io';

import 'package:pitchy/types/song_data.dart';

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
  bool gotFiles = false;
  List<DataFile> allUserSongsData = [];
  bool loadingData = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        loadingData = true;
      });
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
          if (playlistId != null) {
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
              print(fileData);
              setState(() {
                allUserSongsData.add(fileData);
              });
            }
          }
          print(allUserSongsData.map((item) => item.jsonFromClass()).toList());
          playlistNameController.text = thisPlaylistData?.playlistName ?? "";
          playlistDescriptionController.text = thisPlaylistData?.playlistDescription ?? "";
          setState(() {
            gotFiles = true;
          });
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('Could not load playlist ID $playlistId')));
          setState(() {
            loadingData = false;
          });
        }
      }
      setState(() {
        loadingData = false;
      });
    });
  }

  void savePlaylistInfo(bool snackbar) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
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
      thisPlaylistData!.playlistName = playlistNameController.text;
      thisPlaylistData!.playlistDescription = playlistNameController.text;
      if (snackbar) {
        messenger.showSnackBar(SnackBar(content: Text("Playlist details saved!")));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error saving playlist details.")));
    }
  }

  void deleteSongFromPlaylist(int idx, String songId) async {
    final directory = await getApplicationDocumentsDirectory();
    final appSettingsPath = "${directory.path}/app/settings.txt";
    String oldSettingsString = await File(appSettingsPath).readAsString();
    dynamic oldJson = jsonDecode(oldSettingsString);
    AppSettings oldSettings = AppSettings.classFromTxt(oldJson);

    PlaylistData newPlaylist = thisPlaylistData!;
    newPlaylist.songIds.removeAt(idx);

    oldSettings.playlists.removeWhere((item) => item.playlistId == playlistId);
    oldSettings.playlists.add(newPlaylist);

    final newSettingsJson = oldSettings.jsonFromClass();
    await File(appSettingsPath).writeAsString(jsonEncode(newSettingsJson));

    setState(() {
      thisPlaylistData = newPlaylist;
    });
  }

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
            child: loadingData
                ? CircularProgressIndicator()
                : Column(
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
                                  trailing: Icon(Icons.add),
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(thisPlaylistData?.playlistName ?? 'Playlist'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: !loadingData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: EdgeInsetsGeometry.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Playlist", style: TextStyle(fontSize: 18.0)),
                            SizedBox(height: 16),
                            TextField(
                              controller: playlistNameController,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: playlistDescriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
                              ),
                            ),
                            SizedBox(height: 16),
                            FilledButton.tonalIcon(
                              style: ButtonStyle(
                                padding: WidgetStatePropertyAll(EdgeInsetsGeometry.fromLTRB(10, 0, 10, 0)),
                              ),
                              label: Text("Save"),
                              onPressed: () {
                                savePlaylistInfo(true);
                              },
                              icon: Icon(Icons.save),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: EdgeInsetsGeometry.fromLTRB(0, 16, 0, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsetsGeometry.fromLTRB(16, 0, 16, 0),
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
                                      (thisPlaylistData?.songIds.isNotEmpty ?? false)
                                          ? FilledButton.tonalIcon(
                                              style: ButtonStyle(
                                                padding: WidgetStatePropertyAll(
                                                  EdgeInsetsGeometry.fromLTRB(10, 0, 10, 0),
                                                ),
                                              ),
                                              label: Text("Play All"),
                                              onPressed: () {
                                                Navigator.pushNamed(
                                                  context,
                                                  '/listen',
                                                  arguments: ListenArguments(
                                                    "playlist",
                                                    playlistId!,
                                                    thisPlaylistData!.songIds[0],
                                                  ),
                                                );
                                              },
                                              icon: Icon(Icons.playlist_play),
                                            )
                                          : Container(),
                                      FilledButton.tonalIcon(
                                        style: ButtonStyle(
                                          padding: WidgetStatePropertyAll(EdgeInsetsGeometry.fromLTRB(10, 0, 10, 0)),
                                        ),
                                        label: Text("Add Song"),
                                        onPressed: addSongToPlaylist,
                                        icon: Icon(Icons.add),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            (gotFiles && playlistId != null)
                                ? (allUserSongsData.isNotEmpty && (thisPlaylistData?.songIds.isNotEmpty ?? false)
                                      ? ReorderableListView(
                                          physics: NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          onReorder: (oldIndex, newIndex) => {
                                            setState(() {
                                              if (newIndex > oldIndex) {
                                                newIndex -= 1;
                                              }
                                              final String item = thisPlaylistData!.songIds.removeAt(oldIndex);
                                              thisPlaylistData!.songIds.insert(newIndex, item);
                                            }),
                                            savePlaylistInfo(false),
                                          },
                                          children: thisPlaylistData!.songIds
                                              .asMap()
                                              .map((idx, songId) {
                                                return MapEntry(
                                                  idx,
                                                  ListTile(
                                                    key: ValueKey("${idx}_$songId"),
                                                    title: Text(
                                                      allUserSongsData
                                                          .firstWhere(
                                                            (item) => item.fileId == thisPlaylistData!.songIds[idx],
                                                          )
                                                          .fileName,
                                                    ),
                                                    leading: ReorderableDragStartListener(
                                                      index: idx,
                                                      child: const Icon(Icons.drag_handle), // The part to drag
                                                    ),
                                                    trailing: IconButton(
                                                      icon: Icon(Icons.delete),
                                                      onPressed: () {
                                                        deleteSongFromPlaylist(idx, songId);
                                                      },
                                                    ),
                                                    onTap: () => {
                                                      Navigator.pushNamed(
                                                        context,
                                                        '/listen',
                                                        arguments: ListenArguments("playlist", playlistId!, songId),
                                                      ),
                                                    },
                                                  ),
                                                );
                                              })
                                              .values
                                              .toList(),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.fromLTRB(16.0, 0, 16, 16),
                                          child: Column(children: [Text("No songs found")]),
                                        ))
                                : Text("Refresh to load songs"),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : CircularProgressIndicator(),
        ),
      ),
    );
  }
}
