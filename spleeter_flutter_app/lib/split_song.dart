import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class SplitSong extends StatefulWidget {
  const SplitSong({super.key});

  @override
  State<SplitSong> createState() => _SplitSongState();
}

class _SplitSongState extends State<SplitSong> {
  File? pickedFile;
  int step = 0;
  String outputType = "accompaniment";
  Uint8List? resultBytes;
  final player = AudioPlayer();
  bool currentlyPlaying = false;

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
    var request = http.MultipartRequest('POST', Uri.parse("http://192.168.1.159:8000/songs/"));

    request.files.add(await http.MultipartFile.fromPath('song_file', pickedFile!.path));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        print('File sent successfully!');
        var bytes = await response.stream.toBytes();
        setState(() {
          step = 2;
          resultBytes = bytes;
        });
      } else {
        print('File sent failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending file: $e');
    }
  }

  Future<void> saveFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final uploadedFileName = pickedFile!.path.split('/').last.split(".");
    uploadedFileName.removeLast();
    final filePath = '${directory.path}/${uploadedFileName.join("_")}.wav';
    print(filePath);
    final newFile = File(filePath);
    await newFile.writeAsBytes(resultBytes!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text("Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            (step == 0)
                ? Column(
                    children: [
                      Text("Upload a song file:"),
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
                      SizedBox(height: 32),
                      Text("Select settings:"),
                      SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IntrinsicWidth(
                            child: ListTile(
                              title: const Text('Accompaniment'),
                              leading: Radio<String>(
                                value: 'accompaniment',
                                groupValue: outputType,
                                onChanged: (String? value) {
                                  setState(() {
                                    outputType = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                          IntrinsicWidth(
                            child: ListTile(
                              title: const Text('Bass Only'),
                              leading: Radio<String>(
                                value: 'bass',
                                groupValue: outputType,
                                onChanged: (String? value) {
                                  setState(() {
                                    outputType = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                          IntrinsicWidth(
                            child: ListTile(
                              title: const Text('Drums Only'),
                              leading: Radio<String>(
                                value: 'drums',
                                groupValue: outputType,
                                onChanged: (String? value) {
                                  setState(() {
                                    outputType = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                          IntrinsicWidth(
                            child: ListTile(
                              title: const Text('Vocals'),
                              leading: Radio<String>(
                                value: 'vocals',
                                groupValue: outputType,
                                onChanged: (String? value) {
                                  setState(() {
                                    outputType = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                          IntrinsicWidth(
                            child: ListTile(
                              title: const Text('Other (no drums, bass, or vocals)'),
                              leading: Radio<String>(
                                value: 'other',
                                groupValue: outputType,
                                onChanged: (String? value) {
                                  setState(() {
                                    outputType = value!;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      FilledButton(onPressed: stripFile, child: Text("Strip Vocals from Audio")),
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
                      SizedBox(height: 32),
                      IconButton.filledTonal(
                        onPressed: () {
                          if (currentlyPlaying) {
                            player.pause();
                          } else {
                            if (player.state == PlayerState.paused) {
                              player.resume();
                            } else {
                              player.play(BytesSource(resultBytes!));
                            }
                          }
                          setState(() {
                            currentlyPlaying = !currentlyPlaying;
                          });
                        },
                        icon: currentlyPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
                      ),
                      SizedBox(height: 32),
                      TextButton.icon(onPressed: saveFile, icon: Icon(Icons.save), label: Text("Save File")),
                    ],
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
