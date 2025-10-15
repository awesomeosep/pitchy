import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pitchy/types/listen_arguments.dart';
import 'package:pitchy/types/playlists.dart';
import 'package:pitchy/types/app_settings.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:pitchy/types/song_data.dart';
import 'package:just_audio/just_audio.dart' as justaudio;

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
  int _semitones = 0;
  double _volume = 1.0;
  double _lastVolume = 1.0;
  double _bassBoost = 0.0;
  bool _echoEnabled = false;
  double _echoDelay = 0.0;
  double _echoDecay = 0.0;
  bool _muted = false;
  int trackIndex = 0;
  List<File> trackFiles = [];
  String currentPlayer = "accompaniment";
  SoundHandle? soundHandle;
  AudioSource? currentAudioSource;
  final _playerController = StreamController<SoLoud>.broadcast();
  StreamSubscription? _playerSubscription;
  Duration _currentPos = Duration.zero;
  bool draggingPosSlider = false;

  double _pitchFromSemitones(int s) => pow(2, s / 12).toDouble();

  @override
  void initState() {
    super.initState();

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
            if (currentFileId != null) {
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
          final directory = await getApplicationDocumentsDirectory();
          final newPlayer = justaudio.AudioPlayer();
          newPlayer.addAudioSource(
            justaudio.AudioSource.uri(
              Uri.file(
                songFiles[songsData.indexWhere((item) => item.fileId == currentFileId)][songFiles[songsData.indexWhere(
                          (item) => item.fileId == currentFileId,
                        )]
                        .indexWhere((item) => item.path.contains("accompaniment"))]
                    .path,
              ),
            ),
          );
          print(directory);
          final audioSource = currentAudioSource = await SoLoud.instance.loadFile(
            File(
              songFiles[songsData.indexWhere((item) => item.fileId == currentFileId)][songFiles[songsData.indexWhere(
                        (item) => item.fileId == currentFileId,
                      )]
                      .indexWhere((item) => item.path.contains("accompaniment"))]
                  .path,
            ).path,
          );
          setState(() {
            currentAudioSource = audioSource;
          });
          final tempSoundHandle = await SoLoud.instance.play(currentAudioSource!);
          setState(() {
            soundHandle = tempSoundHandle;
          });
          SoLoud.instance.setLooping(soundHandle!, false);
          await changeSong(currentFileId!, true);
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('Could not load file ID $currentFileId')));
          print(e);
        }
      }
    });
  }

  void _startPlayerStream(SoundHandle handle) {
    _playerSubscription?.cancel();

    _playerSubscription = Stream.periodic(const Duration(milliseconds: 200)).listen((_) {
      try {
        final currentPosition = SoLoud.instance;
        _playerController.add(currentPosition);
      } catch (e) {
        _playerController.addError(e);
        _playerSubscription?.cancel();
      }
    });

    currentAudioSource!.allInstancesFinished.first.then((_) {
      SoLoud.instance.disposeAllSources();
      if (songsData.indexWhere((item) => item.fileId == currentFileId) != (songsData.length - 1)) {
        changeSong(songsData[songsData.indexWhere((element) => element.fileId == currentFileId) + 1].fileId, false);
      } else {
        changeSong(songsData[songsData.indexWhere((element) => element.fileId == currentFileId)].fileId, false);
      }
    });
  }

  @override
  void dispose() {
    SoLoud.instance.disposeAllSources();
    _playerSubscription?.cancel();
    _playerController.close();
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
    SoLoud.instance.disposeAllSources();
    final tempAsset = await SoLoud.instance.loadFile(
      songFiles[songsData.indexWhere((item) => item.fileId == currentFileId)][newIdx].path,
    );
    setState(() {
      currentAudioSource = tempAsset;
    });
    final tempSoundHandle = await SoLoud.instance.play(currentAudioSource!);
    setState(() {
      soundHandle = tempSoundHandle;
    });
    _startPlayerStream(soundHandle!);
    SoLoud.instance.setPause(soundHandle!, true);
    SoLoud.instance.seek(soundHandle!, Duration.zero);
    setState(() {
      _currentPos = Duration.zero;
    });
  }

  void saveSettings() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      DataFile newSongData = songsData.firstWhere((item) => item.fileId == currentFileId);

      newSongData.settings.pitch = _pitchFromSemitones(_semitones);
      newSongData.settings.volume = _volume;
      newSongData.settings.bassBoost = _bassBoost;
      newSongData.settings.echoEnabled = _echoEnabled;
      newSongData.settings.echoDelay = _echoDelay;
      newSongData.settings.echoDecay = _echoDecay;
      songsData[songsData.indexWhere((item) => item.fileId == currentFileId)] = newSongData;
      await File(newSongData.dataPath).writeAsString(jsonEncode(newSongData.jsonFromClass()));
      print("file saved");
      messenger.showSnackBar(SnackBar(content: Text("Saved song settings!")));
    } catch (e) {
      print("Error saving song settings ${e.toString()}");
      messenger.showSnackBar(SnackBar(content: Text("Error saving song settings.")));
    }
  }

  Future<void> changeSong(String songId, bool pause) async {
    setState(() {
      currentFileId = songId;
    });
    changeTrack(
      songFiles[songsData.indexWhere((item) => item.fileId == currentFileId)].indexWhere(
        (item) => item.path.contains("accompaniment"),
      ),
    );
    setSongDefaultSettings(songId);
    if (pause) {
      SoLoud.instance.setPause(soundHandle!, true);
    }
  }

  void setSongDefaultSettings(String songId) async {
    SoLoud.instance.setPause(soundHandle!, true);
    setState(() {
      _currentPos = SoLoud.instance.getPosition(soundHandle!);
      _semitones = (12 * (log(songsData.firstWhere((item) => item.fileId == songId).settings.pitch) / log(2))).round();
      _volume = songsData.firstWhere((item) => item.fileId == songId).settings.volume;
      _lastVolume = _volume;
      _bassBoost = songsData.firstWhere((item) => item.fileId == songId).settings.bassBoost;
      _echoEnabled = songsData.firstWhere((item) => item.fileId == songId).settings.echoEnabled;
      _echoDelay = songsData.firstWhere((item) => item.fileId == songId).settings.echoDelay;
      _echoDecay = songsData.firstWhere((item) => item.fileId == songId).settings.echoDecay;
    });
    if (!SoLoud.instance.filters.pitchShiftFilter.isActive) {
      SoLoud.instance.filters.pitchShiftFilter.activate();
    }
    if (!SoLoud.instance.filters.bassBoostFilter.isActive) {
      SoLoud.instance.filters.bassBoostFilter.activate();
    }
    if (_echoEnabled) {
      if (!SoLoud.instance.filters.echoFilter.isActive) {
        SoLoud.instance.filters.echoFilter.activate();
      }
    } else {
      if (SoLoud.instance.filters.echoFilter.isActive) {
        SoLoud.instance.filters.echoFilter.deactivate();
      }
    }
    SoLoud.instance.filters.echoFilter.delay.value = _echoDelay;
    SoLoud.instance.filters.echoFilter.decay.value = _echoDecay;
    SoLoud.instance.setVolume(soundHandle!, _volume);
    SoLoud.instance.filters.pitchShiftFilter.shift.value = _pitchFromSemitones(_semitones);
    SoLoud.instance.filters.bassBoostFilter.boost.value = _bassBoost;
    SoLoud.instance.setLooping(soundHandle!, false);
    // SoLoud.instance.seek(soundHandle!, Duration.zero);
  }

  final TextEditingController trackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    pageArguments = ModalRoute.of(context)!.settings.arguments as ListenArguments;

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                                // color: Colors.white,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    width: 40.0,
                                    height: 4.0,
                                    decoration: BoxDecoration(
                                      // color: Colors.grey[300],
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
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SingleChildScrollView(
            child: Column(
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
                (currentAudioSource != null && soundHandle != null)
                    ? StreamBuilder(
                        stream: _playerController.stream,
                        initialData: null,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Text("Error loading audio");
                          }

                          final Duration pos = snapshot.data?.getPosition(soundHandle!) ?? Duration.zero;
                          final Duration total = snapshot.data?.getLength(currentAudioSource!) ?? Duration.zero;
                          final bool paused = snapshot.data?.getPause(soundHandle!) ?? false;
                          final bool echoFilterActivated = snapshot.data?.filters.echoFilter.isActive ?? false;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Slider(
                                    value: draggingPosSlider
                                        ? ((total.inMilliseconds > 0
                                                  ? _currentPos.inMilliseconds / total.inMilliseconds
                                                  : 0.0)
                                              .clamp(0.0, 1.0))
                                        : ((total.inMilliseconds > 0 ? pos.inMilliseconds / total.inMilliseconds : 0.0)
                                              .clamp(0.0, 1.0)),
                                    onChangeStart: (v) {
                                      setState(() {
                                        draggingPosSlider = true;
                                      });
                                    },
                                    onChanged: (v) {
                                      setState(() {
                                        _currentPos = Duration(milliseconds: (v * total.inMilliseconds).round());
                                      });
                                    },
                                    onChangeEnd: (v) {
                                      setState(() {
                                        draggingPosSlider = false;
                                        _currentPos = Duration(milliseconds: (v * total.inMilliseconds).round());
                                      });
                                      if (total.inMilliseconds > 0) {
                                        SoLoud.instance.seek(
                                          soundHandle!,
                                          Duration(milliseconds: (v * total.inMilliseconds).round()),
                                        );
                                      }
                                    },
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [Text(_formatDuration(pos)), Text(_formatDuration(total))],
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton.filledTonal(
                                    onPressed: () {
                                      if (paused) {
                                        SoLoud.instance.setPause(soundHandle!, false);
                                      } else {
                                        SoLoud.instance.setPause(soundHandle!, true);
                                      }
                                      // SoLoud.instance.pauseSwitch(soundHandle!);
                                    },
                                    icon: paused ? Icon(Icons.play_arrow) : Icon(Icons.pause),
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
                                                      item
                                                          .split(".")
                                                          .sublist(0, (item.split(".").length - 1))
                                                          .last
                                                          .split("_")
                                                          .last,
                                                    ),
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
                                                    SoLoud.instance.setVolume(soundHandle!, _volume);
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
                                                  SoLoud.instance.setVolume(soundHandle!, _volume);
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
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Pitch (semitones)',
                                                  style: TextStyle(fontWeight: FontWeight.w600),
                                                ),
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
                                                    SoLoud.instance.filters.pitchShiftFilter.shift.value =
                                                        _pitchFromSemitones(_semitones);
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
                                                  SoLoud.instance.filters.pitchShiftFilter.shift.value =
                                                      _pitchFromSemitones(_semitones);
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
                                                  SoLoud.instance.filters.pitchShiftFilter.shift.value =
                                                      _pitchFromSemitones(_semitones);
                                                },
                                                icon: Icon(Icons.keyboard_double_arrow_down),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // Bass boost
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Bass Boost', style: TextStyle(fontWeight: FontWeight.w600)),
                                                Slider(
                                                  value: _bassBoost,
                                                  min: 1,
                                                  max: 5,
                                                  divisions: 8,
                                                  label: _bassBoost.toStringAsFixed(2),
                                                  onChanged: (v) {
                                                    setState(() {
                                                      _bassBoost = v;
                                                    });
                                                    SoLoud.instance.filters.bassBoostFilter.boost.value = _bassBoost;
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Column(
                                            children: [
                                              Container(
                                                width: 60,
                                                alignment: Alignment.center,
                                                child: Text(_bassBoost.toStringAsFixed(2)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // Echo
                                      SwitchListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                        title: const Text("Echo"),
                                        value: _echoEnabled,
                                        onChanged: (bool value) {
                                          setState(() {
                                            _echoEnabled = value;
                                          });
                                          if (echoFilterActivated && value == false) {
                                            SoLoud.instance.filters.echoFilter.deactivate();
                                          } else if (!echoFilterActivated && value == true) {
                                            SoLoud.instance.filters.echoFilter.activate();
                                          }
                                        },
                                      ),
                                      _echoEnabled
                                          ? Padding(
                                            padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
                                            child: Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              'Echo Delay (seconds)',
                                                              style: TextStyle(fontWeight: FontWeight.w600),
                                                            ),
                                                            Slider(
                                                              value: _echoDelay,
                                                              min: 0,
                                                              max: 5,
                                                              divisions: 20,
                                                              label: _echoDelay.toStringAsFixed(2),
                                                              onChanged: (v) {
                                                                setState(() {
                                                                  _echoDelay = v;
                                                                });
                                                                SoLoud.instance.filters.echoFilter.delay.value =
                                                                    _echoDelay;
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Column(
                                                        children: [
                                                          Container(
                                                            width: 60,
                                                            alignment: Alignment.center,
                                                            child: Text(_echoDelay.toStringAsFixed(2)),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              'Echo Decay',
                                                              style: TextStyle(fontWeight: FontWeight.w600),
                                                            ),
                                                            Slider(
                                                              value: _echoDecay,
                                                              min: 0,
                                                              max: 1,
                                                              divisions: 10,
                                                              label: _echoDecay.toStringAsFixed(2),
                                                              onChanged: (v) {
                                                                setState(() {
                                                                  _echoDecay = v;
                                                                });
                                                                SoLoud.instance.filters.echoFilter.decay.value =
                                                                    _echoDecay;
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Column(
                                                        children: [
                                                          Container(
                                                            width: 60,
                                                            alignment: Alignment.center,
                                                            child: Text(_echoDecay.toStringAsFixed(2)),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                          )
                                          : Container(),
                                      TextButton.icon(
                                        onPressed: saveSettings,
                                        label: Text("Save Settings"),
                                        icon: Icon(Icons.save),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    : Container(),
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
