// import 'package:audioplayers/audioplayers.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class Listen extends StatefulWidget {
  const Listen({super.key});

  @override
  State<Listen> createState() => _ListenState();
}

class _ListenState extends State<Listen> {
  late File? file;
  final player = AudioPlayer();
  bool currentlyPlaying = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (file == null)
        return;
      else {
        player.setAudioSource(AudioSource.uri(Uri.file(file!.path)));
        await player.setLoopMode(LoopMode.all);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    file = ModalRoute.of(context)!.settings.arguments as File;

    return Scaffold(
      appBar: AppBar(title: Text(file != null ? file!.path.split('/').last : 'Loading file...')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [Icon(Icons.audio_file), SizedBox(width: 8), Text(file != null ? file!.path.split('/').last : 'Loading...')],
            ),
            SizedBox(height: 32),
            IconButton.filledTonal(
              onPressed: () {
                if (!player.playing) {
                  player.play();
                } else {
                  player.play();
                }
                setState(() {
                  currentlyPlaying = !currentlyPlaying;
                });
              },
              icon: currentlyPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    player.setPitch(player.pitch - 0.05);
                  },
                  icon: Icon(Icons.keyboard_arrow_down_outlined),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    player.setPitch(player.pitch + 0.05);
                  },
                  icon: Icon(Icons.keyboard_arrow_up_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
