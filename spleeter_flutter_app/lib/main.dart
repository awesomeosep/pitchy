import 'package:flutter/material.dart';
import 'package:spleeter_flutter_app/list.dart';
import 'package:spleeter_flutter_app/listen.dart';
import 'package:spleeter_flutter_app/split_song.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      // home: SplitSong(),
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => const HomeList(),
        '/split': (BuildContext context) => const SplitSong(),
        '/listen': (BuildContext context) => const Listen(),
      },
    ),
  );
}
