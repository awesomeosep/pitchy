import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pitchy/types/playlists.dart';
import 'package:pitchy/types/app_settings.dart';

class NewPlaylist extends StatefulWidget {
  const NewPlaylist({super.key});

  @override
  State<NewPlaylist> createState() => _NewPlaylistState();
}

class _NewPlaylistState extends State<NewPlaylist> {
  final playlistNameController = TextEditingController();
  final playlistDescriptionController = TextEditingController();

  Future<void> createPlaylist() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final Random random = Random();
      final directory = await getApplicationDocumentsDirectory();
      final appSettingsPath = "${directory.path}/app/settings.txt";
      String oldSettingsString = await File(appSettingsPath).readAsString();
      dynamic oldJson = jsonDecode(oldSettingsString);
      AppSettings oldSettings = AppSettings.classFromTxt(oldJson);

      PlaylistData newPlaylist = PlaylistData(
        random.nextInt(10000).toString(),
        playlistNameController.text,
        playlistDescriptionController.text,
        [],
      );

      oldSettings.playlists.add(newPlaylist);
      final newSettingsJson = oldSettings.jsonFromClass();
      await File(appSettingsPath).writeAsString(jsonEncode(newSettingsJson));
      messenger.showSnackBar(SnackBar(content: Text("Playlist created!")));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error creating playlist")));
      print("Error creating playlist ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text("New Playlist")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Please fill out the following details:"),
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
              FilledButton.icon(
                onPressed: () {
                  createPlaylist();
                  Navigator.pushNamed(context, "/", arguments: "playlists");
                },
                label: Text("Create Playlist"),
                icon: Icon(Icons.playlist_add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
