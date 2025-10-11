import 'dart:convert';

import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spleeter_flutter_app/types/ListenArguments.dart';
import 'package:spleeter_flutter_app/types/Playlists.dart';
import 'package:spleeter_flutter_app/types/Settings.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'package:spleeter_flutter_app/types/SongData.dart';

class Listen extends StatefulWidget {
  const Listen({super.key});

  @override
  State<Listen> createState() => _ListenState();
}

class _ListenState extends State<Listen> {
  late ListenArguments pageArguments;
  late String? playlistId;
  PlaylistData? playlistData;
  late String? group;
  late String? currentFileId;
  List<List<File>> songFiles = [];
  List<DataFile> songsData = [];
  final mainPlayer = AudioPlayer();
  final alternatePlayer = AudioPlayer();
  bool mainCurrentlyPlaying = false;
  bool alternateCurrentlyPlaying = false;
  StreamSubscription<PlayerState>? _mainPlayerStateSub;
  StreamSubscription<PlayerState>? _alternatePlayerStateSub;
  int _semitones = 0;
  double _volume = 1.0;
  double _lastVolume = 1.0;
  bool _muted = false;
  int trackIndex = 0;
  List<File> trackFiles = [];
  String currentPlayer = "accompaniment";

  double _pitchFromSemitones(int s) => pow(2, s / 12).toDouble();

  @override
  void initState() {
    super.initState();
    _mainPlayerStateSub = mainPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (songsData.indexWhere((element) => element.fileId == currentFileId) != (songsData.length - 1)) {
          changeSong(songsData[songsData.indexWhere((element) => element.fileId == currentFileId) + 1].fileId, true);
        }
      }
      setState(() {
        mainCurrentlyPlaying = state.playing;
      });
    });

    _alternatePlayerStateSub = alternatePlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (songsData.indexWhere((element) => element.fileId == currentFileId) != (songsData.length - 1)) {
          changeSong(songsData[songsData.indexWhere((element) => element.fileId == currentFileId) + 1].fileId, true);
        }
      }
      setState(() {
        alternateCurrentlyPlaying = state.playing;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is ListenArguments) {
        setState(() {
          pageArguments = arg;
        });
        setState(() {
          currentFileId = pageArguments.startSongId;
          group = pageArguments.group;
        });

        print(group);

        final messenger = ScaffoldMessenger.of(context);
        try {
          if (group == "playlist") {
            setState(() {
              playlistId = arg.groupId;
            });
            print(playlistId);
            // get playlist data
            final directory = await getApplicationDocumentsDirectory();
            final settingsFile = File("${directory.path}/app/settings.txt");
            String settingsDataString = await settingsFile.readAsString();
            dynamic settingsDataJson = jsonDecode(settingsDataString);
            print(settingsDataJson);
            final settings = AppSettings.classFromTxt(settingsDataJson);
            setState(() {
              playlistData = settings.playlists.firstWhere((item) => item.playlistId == playlistId);
            });
            print("playlistData ${playlistData!.jsonFromClass().toString()}");
            // get all songs + data
            final dataDirectoryPath = "${directory.path}/songs/data";
            for (int i = 0; i < playlistData!.songIds.length; i++) {
              // get song data
              File thisFile = File("$dataDirectoryPath/${playlistData!.songIds[i]}.txt");
              String dataString = await thisFile.readAsString();
              dynamic dataJson = jsonDecode(dataString);
              DataFile fileData = DataFile.classFromTxt(dataJson);
              setState(() {
                songsData.add(fileData);
              });
              print("added songs data");
              // get song files
              List<File> thisSongFiles = [];
              for (int i = 0; i < fileData.songPaths.length; i++) {
                final songPath = fileData.songPaths[i];
                final songFile = File(songPath);
                thisSongFiles.add(songFile);
              }
              setState(() {
                songFiles.add(thisSongFiles);
              });
              print("added song files");
            }
          } else if (group == "song") {
            final directory = await getApplicationDocumentsDirectory();
            final dataFile = File("${directory.path}/songs/data/$currentFileId.txt");
            if (currentFileId != null && dataFile != null) {
              String dataString = await dataFile.readAsString();
              dynamic dataJson = jsonDecode(dataString);
              setState(() {
                songsData.add(DataFile.classFromTxt(dataJson));
              });
              List<File> thisSongFiles = [];
              for (int i = 0; i < songsData[0].songPaths.length; i++) {
                final songPath = songsData[0].songPaths[i];
                final songFile = File(songPath);
                thisSongFiles.add(songFile);
              }
              setState(() {
                songFiles.add(thisSongFiles);
              });
            }
          }

          await mainPlayer.setAudioSources(
            songsData
                .map(
                  (item) => AudioSource.uri(
                    Uri.file(
                      songFiles[songsData.indexOf(item)][songFiles[songsData.indexOf(item)].indexWhere(
                            (item) => item.path.contains("accompaniment"),
                          )]
                          .path,
                    ),
                  ),
                )
                .toList(),
          );
          await alternatePlayer.setAudioSources(
            songsData
                .map(
                  (item) => AudioSource.uri(
                    Uri.file(
                      songFiles[songsData.indexOf(item)][songFiles[songsData.indexOf(item)].indexWhere(
                            (item) => item.path.contains("vocals"),
                          )]
                          .path,
                    ),
                  ),
                )
                .toList(),
          );
          changeSong(currentFileId!, true);
          await mainPlayer.setLoopMode(LoopMode.off);
          await alternatePlayer.setLoopMode(LoopMode.off);
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('Could not load file ID $currentFileId')));
          print(e);
        }
      }
    });
  }

  @override
  void dispose() {
    _mainPlayerStateSub?.cancel();
    _alternatePlayerStateSub?.cancel();
    mainPlayer.dispose();
    alternatePlayer.dispose();
    super.dispose();
  }

  void changeTrack(int newIdx) async {
    setState(() {
      trackIndex = newIdx;
      currentPlayer =
          songFiles[songsData.indexWhere((item) => item.fileId == currentFileId)][newIdx].path.contains("accompaniment")
          ? "accompaniment"
          : "vocals";
    });
    if (currentPlayer == "accompaniment") {
      alternatePlayer.pause();
      mainPlayer.seek(Duration.zero);
    } else {
      mainPlayer.pause();
      alternatePlayer.seek(Duration.zero);
    }
    setState(() {
      _semitones = (12 * (log(currentPlayer == "accompaniment" ? mainPlayer.pitch : alternatePlayer.pitch) / log(2)))
          .round();
      _volume = currentPlayer == "accompaniment" ? mainPlayer.volume : alternatePlayer.volume;
      _lastVolume = _volume;
    });
  }

  void saveSettings() async {
    DataFile newSongData = songsData.firstWhere((item) => item.fileId == currentFileId);
    newSongData.settings.pitch = currentPlayer == "accompaniment" ? mainPlayer.pitch : alternatePlayer.pitch;
    newSongData.settings.volume = currentPlayer == "accompaniment" ? mainPlayer.volume : alternatePlayer.volume;
    songsData[songsData.indexWhere((item) => item.fileId == currentFileId)] = newSongData;
    await File(newSongData.dataPath).writeAsString(jsonEncode(newSongData.jsonFromClass()));
    print("file saved");
  }

  void changeSong(String songId, bool pause) async {
    setState(() {
      currentFileId = songId;
      print(currentFileId);
    });
    mainPlayer.setAudioSource(
      AudioSource.uri(
        Uri.file(
          songFiles[songsData.indexWhere((item) => item.fileId == songId)]
              .firstWhere((item) => item.path.contains("accompaniment"))
              .path,
        ),
      ),
    );
    alternatePlayer.setAudioSource(
      AudioSource.uri(
        Uri.file(
          songFiles[songsData.indexWhere((item) => item.fileId == songId)]
              .firstWhere((item) => item.path.contains("vocals"))
              .path,
        ),
      ),
    );
    mainPlayer.seek(Duration.zero);
    alternatePlayer.seek(Duration.zero);
    setSongDefaultSettings(songId);
    changeTrack(
      songFiles[songsData.indexWhere((item) => item.fileId == currentFileId)].indexWhere(
        (item) => item.path.contains("accompaniment"),
      ),
    );
    if (pause) {
      mainPlayer.pause();
      alternatePlayer.pause();
    }
  }

  void setSongDefaultSettings(String songId) async {
    mainPlayer.seek(Duration.zero);
    print(songsData.firstWhere((item) => item.fileId == songId).settings.volume);
    print(songsData.firstWhere((item) => item.fileId == songId).settings.pitch);
    await mainPlayer.setVolume(songsData.firstWhere((item) => item.fileId == songId).settings.volume);
    await mainPlayer.setPitch(songsData.firstWhere((item) => item.fileId == songId).settings.pitch);
    await mainPlayer.setLoopMode(LoopMode.off);
    alternatePlayer.seek(Duration.zero);
    await alternatePlayer.setVolume(songsData.firstWhere((item) => item.fileId == songId).settings.volume);
    await alternatePlayer.setPitch(songsData.firstWhere((item) => item.fileId == songId).settings.pitch);
    await alternatePlayer.setLoopMode(LoopMode.off);
    setState(() {
      _semitones = (12 * (log(mainPlayer.pitch) / log(2))).round();
      _volume = mainPlayer.volume;
      _lastVolume = _volume;
    });
  }

  final TextEditingController trackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    pageArguments = ModalRoute.of(context)!.settings.arguments as ListenArguments;

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          playlistData != null || songsData.isNotEmpty
              ? (group == "playlist" ? "Playlist: ${playlistData!.playlistName}" : "Song: ${songsData[0].fileName}")
              : "Listen",
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.only(top: 0),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              IconButton(
                onPressed: songsData.indexWhere((element) => element.fileId == currentFileId) != 0
                    ? () {
                        changeSong(
                          songsData[songsData.indexWhere((element) => element.fileId == currentFileId) - 1].fileId,
                          true,
                        );
                      }
                    : null,
                icon: Icon(Icons.keyboard_double_arrow_left),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) {
                        return DraggableScrollableSheet(
                          initialChildSize: 0.5,
                          minChildSize: 0.25,
                          maxChildSize: 0.9,
                          expand: false,
                          builder: (BuildContext context, ScrollController scrollController) {
                            return Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    width: 40.0,
                                    height: 4.0,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2.0),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: songsData.map((song) {
                                      return ListTile(
                                        selected: currentFileId == song.fileId,
                                        leading: Icon(Icons.play_arrow),
                                        title: Text(song.fileName),
                                        onTap: () {
                                          print("hello");
                                          changeSong(song.fileId, true);
                                          Navigator.pop(context);
                                        },
                                      );
                                    }).toList(),
                                  ),
                                  Text("End of playlist"),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  child: Text("Show queue"),
                ),
              ),
              IconButton(
                onPressed: songsData.indexWhere((element) => element.fileId == currentFileId) != (songsData.length - 1)
                    ? () {
                        changeSong(
                          songsData[songsData.indexWhere((element) => element.fileId == currentFileId) + 1].fileId,
                          true,
                        );
                      }
                    : null,
                icon: Icon(Icons.keyboard_double_arrow_right),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 12.0 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text("Song ${songsData.indexWhere((item) => item.fileId == currentFileId) + 1} of ${songsData.length}"),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.audio_file),
                    SizedBox(width: 8),
                    songsData.any((item) => item.fileId == currentFileId)
                        ? Text(songsData.firstWhere((item) => item.fileId == currentFileId).fileName)
                        : Text('File not found'),
                  ],
                ),
                SizedBox(height: 8),
                StreamBuilder<Duration?>(
                  stream: currentPlayer == "accompaniment" ? mainPlayer.durationStream : alternatePlayer.durationStream,
                  builder: (context, snapDur) {
                    final total = snapDur.data ?? Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: currentPlayer == "accompaniment"
                          ? mainPlayer.positionStream
                          : alternatePlayer.positionStream,
                      builder: (context, snapPos) {
                        final pos = snapPos.data ?? Duration.zero;
                        double value = total.inMilliseconds > 0 ? pos.inMilliseconds / total.inMilliseconds : 0.0;
                        return Column(
                          children: [
                            Slider(
                              value: value.clamp(0.0, 1.0),
                              onChanged: (v) {
                                if (total.inMilliseconds > 0) {
                                  if (currentPlayer == "accompaniment") {
                                    mainPlayer.seek(Duration(milliseconds: (v * total.inMilliseconds).round()));
                                  } else {
                                    alternatePlayer.seek(Duration(milliseconds: (v * total.inMilliseconds).round()));
                                  }
                                }
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [Text(_formatDuration(pos)), Text(_formatDuration(total))],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () {
                        if (currentPlayer == "accompaniment") {
                          if (mainPlayer.playing) {
                            mainPlayer.pause();
                          } else {
                            mainPlayer.play();
                          }
                        } else {
                          if (alternatePlayer.playing) {
                            alternatePlayer.pause();
                          } else {
                            alternatePlayer.play();
                          }
                        }
                      },
                      icon: currentPlayer == "accompaniment"
                          ? (mainCurrentlyPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow))
                          : (alternateCurrentlyPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow)),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8, 16, 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text("Track", style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(width: 16),
                            Wrap(
                              runSpacing: 8,
                              spacing: 8,
                              children: songsData
                                  .firstWhere((item) => item.fileId == currentFileId)
                                  .songPaths
                                  .map(
                                    (item) => ChoiceChip(
                                      onSelected: (value) {
                                        if (value == true) {
                                          changeTrack(
                                            songsData
                                                .firstWhere((item) => item.fileId == currentFileId)
                                                .songPaths
                                                .indexOf(item),
                                          );
                                        }
                                      },
                                      label: Text(
                                        item.split(".").sublist(0, (item.split(".").length - 1)).last.split("_").last,
                                      ),
                                      // labelStyle: TextStyle(
                                      //   fontWeight: FontWeight.bold,
                                      //   color:
                                      //       songsData
                                      //               .firstWhere((item) => item.fileId == currentFileId)
                                      //               .songPaths
                                      //               .indexOf(item)
                                      //               .toString() ==
                                      //           trackIndex.toString()
                                      //       ? Colors.white
                                      //       : Colors.black,
                                      // ),
                                      selected:
                                          songsData
                                              .firstWhere((item) => item.fileId == currentFileId)
                                              .songPaths
                                              .indexOf(item)
                                              .toString() ==
                                          trackIndex.toString(),
                                      selectedColor: Theme.of(context).colorScheme.primaryContainer,
                                      backgroundColor: Colors.transparent,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pitch (semitones)', style: TextStyle(fontWeight: FontWeight.w600)),
                                  Slider(
                                    value: _semitones.toDouble().clamp(-12.0, 12.0),
                                    min: -12,
                                    max: 12,
                                    divisions: 24,
                                    label: '${_semitones >= 0 ? '+' : ''}$_semitones',
                                    onChanged: (v) {
                                      setState(() {
                                        _semitones = v.toDouble().clamp(-12.0, 12.0).round();
                                      });
                                      mainPlayer.setPitch(_pitchFromSemitones(_semitones));
                                      alternatePlayer.setPitch(_pitchFromSemitones(_semitones));
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _semitones = (_semitones + 1).clamp(-12, 12);
                                    });
                                    mainPlayer.setPitch(_pitchFromSemitones(_semitones));
                                    alternatePlayer.setPitch(_pitchFromSemitones(_semitones));
                                  },
                                  icon: Icon(Icons.keyboard_double_arrow_up),
                                ),
                                Container(
                                  width: 60,
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text('${_semitones >= 0 ? '+' : ''}$_semitones'),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _semitones = (_semitones - 1).clamp(-12, 12);
                                    });
                                    mainPlayer.setPitch(_pitchFromSemitones(_semitones));
                                    alternatePlayer.setPitch(_pitchFromSemitones(_semitones));
                                  },
                                  icon: Icon(Icons.keyboard_double_arrow_down),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Volume control
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Volume', style: TextStyle(fontWeight: FontWeight.w600)),
                                  Slider(
                                    value: _muted ? 0.0 : _volume.clamp(0.0, 1.0),
                                    min: 0.0,
                                    max: 1.0,
                                    divisions: 20,
                                    label: (_muted ? 0.0 : _volume).toStringAsFixed(2),
                                    onChanged: (v) {
                                      setState(() {
                                        _volume = v;
                                        _muted = _volume <= 0.001;
                                        if (!_muted) _lastVolume = _volume;
                                      });
                                      mainPlayer.setVolume(_volume);
                                      alternatePlayer.setVolume(_volume);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Column(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      if (_muted) {
                                        // unmute
                                        _muted = false;
                                        _volume = _lastVolume > 0 ? _lastVolume : 0.5;
                                      } else {
                                        _muted = true;
                                        _lastVolume = _volume;
                                        _volume = 0.0;
                                      }
                                    });
                                    mainPlayer.setVolume(_volume);
                                    alternatePlayer.setVolume(_volume);
                                  },
                                  icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                                ),
                                Container(
                                  width: 60,
                                  alignment: Alignment.center,
                                  child: Text((_muted ? 0.0 : _volume).toStringAsFixed(2)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        TextButton.icon(onPressed: saveSettings, label: Text("Save Settings"), icon: Icon(Icons.save)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
