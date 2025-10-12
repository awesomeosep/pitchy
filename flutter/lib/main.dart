import 'package:flutter/material.dart';
import 'package:pitchy/home.dart';
import 'package:pitchy/listen.dart';
import 'package:pitchy/new_playlist.dart';
import 'package:pitchy/playlist.dart';
import 'package:pitchy/split_song.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load(fileName: ".env");

  runApp(
    MaterialApp(
      title: 'pitchy',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.red)),
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => const HomeList(),
        '/split': (BuildContext context) => const SplitSong(),
        '/listen': (BuildContext context) => const Listen(),
        '/newPlaylist': (BuildContext context) => const NewPlaylist(),
        '/openPlaylist': (BuildContext context) => const OpenPlaylist()
      },
    ),
  );
}
