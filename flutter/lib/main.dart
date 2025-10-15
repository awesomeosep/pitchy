import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:pitchy/home.dart';
import 'package:pitchy/listen.dart';
import 'package:pitchy/new_playlist.dart';
import 'package:pitchy/playlist.dart';
import 'package:pitchy/settings.dart';
import 'package:pitchy/split_song.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:pitchy/utils/theme_provider.dart';
import 'package:provider/provider.dart';

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

  runApp(ChangeNotifierProvider(create: (_) => ThemeProvider(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Use dynamic colors if available
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          // Fallback to a baseline color scheme
          lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.red);
          darkColorScheme = ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.dark);
        }

        final themeProvider = Provider.of<ThemeProvider>(context);

        return MaterialApp(
          theme: ThemeData(colorScheme: lightColorScheme, useMaterial3: true),
          darkTheme: ThemeData(colorScheme: darkColorScheme, useMaterial3: true),
          title: 'pitchy',
          routes: <String, WidgetBuilder>{
            '/': (BuildContext context) => const HomeList(),
            '/split': (BuildContext context) => const SplitSong(),
            '/listen': (BuildContext context) => const Listen(),
            '/newPlaylist': (BuildContext context) => const NewPlaylist(),
            '/openPlaylist': (BuildContext context) => const OpenPlaylist(),
            '/settings': (BuildContext context) => const Settings(),
          },
          themeMode: themeProvider.themeMode,
        );
      },
    );
  }
}
