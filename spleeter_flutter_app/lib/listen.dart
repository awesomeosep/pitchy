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
  Widget build(BuildContext context) {
    file = ModalRoute.of(context)!.settings.arguments as File;

    return Scaffold(
      appBar: AppBar(title: Text(file.path.split('/').last)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text("Now playing:"), SizedBox(height: 16), Text(file.path.split('/').last)],
        ),
      ),
    );
  }
}
