import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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

  Future<void> getFiles() async {
    setState(() {
      splitSongData = [];
      splitSongFiles = [];
    });

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
    setState(() {
      gotFiles = true;
    });
    print(splitSongData);
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
      appBar: AppBar(automaticallyImplyLeading: false, backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text("Home")),
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
                  IconButton(
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
                                onTap: () => {Navigator.pushNamed(context, '/listen', arguments: file.fileId)},
                              );
                            }).toList(),
                          )
                        : Text("No files found"))
                  : Text("Reload to get files"),
            ],
          ),
        ),
      ),
    );
  }
}
