import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class HomeList extends StatefulWidget {
  const HomeList({super.key});

  @override
  State<HomeList> createState() => _HomeListState();
}

class _HomeListState extends State<HomeList> {
  bool gotFiles = false;
  List<FileSystemEntity> splitSongFiles = [];

  Future<void> getFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync(recursive: true);
    setState(() {
      splitSongFiles = files.where((entity) => entity is File && entity.path.endsWith(".wav")).toList();
      gotFiles = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text("Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text("Your split songs:"),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await getFiles();
                      },
                      child: Text("Load files"),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pushNamed(context, '/split');
                      },
                      child: Text("Split Song"),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                (gotFiles)
                    ? Column(
                        children: splitSongFiles.map((file) {
                          return ListTile(
                            leading: Icon(Icons.music_note),
                            title: Text(file.path.split('/').last),
                            onTap: () => {
                              Navigator.pushNamed(
                                context,
                                '/listen',
                                arguments: File(file.path),
                              )
                            },
                          );
                        }).toList(),
                      )
                    : Text("No files loaded"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
