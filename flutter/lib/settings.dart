import 'package:flutter/material.dart';
import 'package:pitchy/utils/theme_provider.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    String currentTheme = themeProvider.themeMode == ThemeMode.dark
        ? "dark"
        : (themeProvider.themeMode == ThemeMode.light ? "light" : "system");
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome to pitchy!"),
                  Text(
                    "Here you can navigate to your uploaded songs, playlists, and groups!",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text("Uploads"),
              onTap: () {
                Navigator.pushNamed(context, "/", arguments: "uploads");
              },
            ),
            ListTile(
              title: const Text("Playlists"),
              onTap: () {
                Navigator.pushNamed(context, "/", arguments: "playlists");
              },
            ),
            ListTile(
              title: const Text("Settings"),
              onTap: () {
                Navigator.pushNamed(context, "/settings");
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text("Settings")),
      body: SafeArea(
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("Theme:"),
                      const SizedBox(width: 16),
                      SegmentedButton<String>(
                        multiSelectionEnabled: false,
                        emptySelectionAllowed: true,
                        showSelectedIcon: false,
                        selected: currentTheme.isNotEmpty ? {currentTheme} : {},
                        onSelectionChanged: (Set<String> newSelection) {
                          if (newSelection.first == "dark") {
                            themeProvider.toggleTheme(ThemeMode.dark);
                          } else if (newSelection.first == "light") {
                            themeProvider.toggleTheme(ThemeMode.light);
                          } else if (newSelection.first == "system") {
                            themeProvider.toggleTheme(ThemeMode.system);
                          }
                          setState(() {
                            currentTheme = newSelection.first;
                          });
                        },
                        segments: ["dark", "light", "system"].map<ButtonSegment<String>>((String theme) {
                          return ButtonSegment<String>(
                            value: theme,
                            label: Text(theme[0].toUpperCase() + theme.substring(1)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
