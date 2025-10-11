import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:spleeter_flutter_app/types/SongData.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SplitSong extends StatefulWidget {
  const SplitSong({super.key});

  @override
  State<SplitSong> createState() => _SplitSongState();
}

class _SplitSongState extends State<SplitSong> {
  File? pickedFile;
  int step = 0;
  String outputType = "accompaniment";
  List<int>? zipBytes;
  bool currentlyPlaying = false;
  bool loadingSplit = false;

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() {
        pickedFile = File(result.files.single.path!);
        step = 1;
      });
      print("Picked file: ${pickedFile!.path}");
    } else {
      print("Pick cancelled");
    }
  }

  Future<void> stripFile() async {
    print("starting request");
    setState(() {
      loadingSplit = true;
    });
    final apiUrl = dotenv.env["SPLEETER_API_URL"] ?? "error";
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    request.files.add(await http.MultipartFile.fromPath('song_file', pickedFile!.path));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        print('File sent successfully!');

        var outBytes = await response.stream.toBytes();

        setState(() {
          zipBytes = outBytes;
          step = 2;
        });
      } else {
        print('File sent failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending file: $e');
    }
    setState(() {
      loadingSplit = false;
    });
  }

  Future<void> saveFile() async {
    final Random random = Random();

    final directory = await getApplicationDocumentsDirectory();

    final pathitems = pickedFile!.path.split('/').last.split(".");
    pathitems.removeLast();
    final origFileName = pathitems.join(".");

    DataFile songData = DataFile(
      random.nextInt(10000).toString(),
      origFileName,
      "",
      [],
      "2stems",
      DateTime.now(),
      SongSettings(1.0, 1.0),
    );

    // extract zip
    final extractPath = p.join(directory.path, 'songs/audio_files');
    final extractDir = Directory(extractPath);
    if (!await extractDir.exists()) {
      print("dir dos not exist");
      await extractDir.create(recursive: true);
    }
    print("created dir?");
    final archive = ZipDecoder().decodeBytes(zipBytes!);
    print("decoded bytes");

    // save zip contents to new folder
    for (final file in archive) {
      final filename = p.join(extractPath, "${songData.fileId}_${file.name}");

      if (file.isFile) {
        final data = file.content as List<int>;
        print("creating file $filename");
        File(filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
        songData.songPaths.add(filename);
      } else {
        Directory(filename).create(recursive: true);
      }
    }

    final infoPath = p.join(directory.path, 'songs/data/');
    final infoDir = Directory(infoPath);
    if (!await infoDir.exists()) {
      print("info dir dos not exist");
      await infoDir.create(recursive: true);
    }
    songData.dataPath = "$infoPath${songData.fileId}.txt";
    print("song data contents: ${songData.jsonFromClass()}");
    await File(songData.dataPath).writeAsString(jsonEncode(songData.jsonFromClass()));

    print("created info file $infoPath/${songData.fileId}.txt");

    Navigator.pushNamed(context, "/");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text("Upload Song")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            (step == 0)
                ? Column(
                    children: [
                      Text("Upload a song file:", style: TextStyle(fontSize: 18)),
                      SizedBox(height: 16),
                      IconButton.filledTonal(onPressed: pickFile, icon: Icon(Icons.upload_file)),
                    ],
                  )
                : (step == 1)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [Icon(Icons.audio_file), SizedBox(width: 8), Text(pickedFile!.path.split('/').last)],
                      ),
                      SizedBox(height: 16),
                      FilledButton(
                        onPressed: loadingSplit ? null : stripFile,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            loadingSplit
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      ),
                                      SizedBox(width: 16),
                                    ],
                                  )
                                : SizedBox(),
                            Text("Split Song"),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton.icon(
                        icon: Icon(Icons.arrow_back),
                        label: Text("Pick different file"),
                        onPressed: loadingSplit ? null : () {
                          setState(() {
                            pickedFile = null;
                            step = 0;
                          });
                        },
                      ),
                    ],
                  )
                : (step == 2)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [Icon(Icons.audio_file), SizedBox(width: 8), Text(pickedFile!.path.split('/').last)],
                      ),
                      SizedBox(height: 16),
                      Text("Song split successfully!"),
                      SizedBox(height: 16),
                      TextButton.icon(onPressed: saveFile, icon: Icon(Icons.save), label: Text("Save Song to App")),
                    ],
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
