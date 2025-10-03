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
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text("Home")),
      body: Padding(
        padding: EdgeInsetsGeometry.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("Your songs:", style: TextStyle(fontSize: 18.0)),
                  IconButton(
                    onPressed: () async {
                      await getFiles();
                    },
                    icon: Icon(Icons.refresh),
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
                          onTap: () => {Navigator.pushNamed(context, '/listen', arguments: File(file.path))},
                        );
                      }).toList(),
                    )
                  : Text("No files loaded"),
            ],
          ),
        ),
      ),
    );
  }
}
