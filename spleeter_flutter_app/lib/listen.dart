import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class Listen extends StatefulWidget {
  const Listen({super.key});

  @override
  State<Listen> createState() => _ListenState();
}

class _ListenState extends State<Listen> {
  late File file;
  final player = AudioPlayer();
  bool currentlyPlaying = false;

  @override
  void initState() {
    super.initState();

    player.setReleaseMode(ReleaseMode.stop);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await player.setSource(DeviceFileSource(file.path));
    });
  }

  @override
  Widget build(BuildContext context) {
    file = ModalRoute.of(context)!.settings.arguments as File;

    return Scaffold(
      appBar: AppBar(title: Text(file.path.split('/').last)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [Icon(Icons.audio_file), SizedBox(width: 8), Text(file.path.split('/').last)],
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
                    player.play(DeviceFileSource(file.path));
                  }
                }
                setState(() {
                  currentlyPlaying = !currentlyPlaying;
                });
              },
              icon: currentlyPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
            ),
          ],
        ),
      ),
    );
  }
}
