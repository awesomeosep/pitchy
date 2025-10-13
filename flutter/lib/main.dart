import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:pitchy/home.dart';
import 'package:pitchy/listen.dart';
import 'package:pitchy/new_playlist.dart';
import 'package:pitchy/playlist.dart';
import 'package:pitchy/split_song.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

Future main() async {
  await dotenv.load(fileName: ".env");

  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;
  Logger.root.onRecord.listen((record) {
    dev.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      zone: record.zone,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });

  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize the player.
  await SoLoud.instance.init();

  runApp(
    MaterialApp(
      title: 'pitchy',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.red)),
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => const HomeList(),
        '/split': (BuildContext context) => const SplitSong(),
        '/listen': (BuildContext context) => const Listen(),
        '/newPlaylist': (BuildContext context) => const NewPlaylist(),
        '/openPlaylist': (BuildContext context) => const OpenPlaylist(),
      },
    ),
  );
}
