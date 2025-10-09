import 'package:flutter/material.dart';
import 'package:spleeter_flutter_app/home.dart';
import 'package:spleeter_flutter_app/listen.dart';
import 'package:spleeter_flutter_app/split_song.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load();

  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.red)),
      // home: SplitSong(),
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => const HomeList(),
        '/split': (BuildContext context) => const SplitSong(),
        '/listen': (BuildContext context) => const Listen(),
      },
    ),
  );
}
