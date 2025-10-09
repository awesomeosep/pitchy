// import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';

import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
  late String? fileId;
  DataFile? origSongData;
  final player = AudioPlayer();
  bool currentlyPlaying = false;
  StreamSubscription<PlayerState>? _playerStateSub;
  int _semitones = 0;
  double _volume = 1.0;
  double _lastVolume = 1.0;
  bool _muted = false;
  int trackIndex = 0;
  List<File> trackFiles = [];

  double _pitchFromSemitones(int s) => pow(2, s / 12).toDouble();

  @override
  void initState() {
    super.initState();
    _playerStateSub = player.playerStateStream.listen((state) {
      setState(() {
        currentlyPlaying = state.playing;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String) {
        fileId = arg;
        final messenger = ScaffoldMessenger.of(context);
        try {
          final directory = await getApplicationDocumentsDirectory();
          final dataFile = File("${directory.path}/songs/data/$fileId.txt");
          if (fileId != null && dataFile != null) {
            print("fileid, datafile not null");
            setState(() {
              trackFiles = [];
            });
            String dataString = await dataFile.readAsString();
            dynamic dataJson = jsonDecode(dataString);
            setState(() {
              origSongData = DataFile.classFromTxt(dataJson);
              trackIndex = 0;
            });

            for (int i = 0; i < origSongData!.songPaths.length; i++) {
              final songPath = origSongData!.songPaths[i];
              final songFile = File(songPath);
              setState(() {
                trackFiles.add(songFile);
              });
            }

            await player.setAudioSource(AudioSource.uri(Uri.file(trackFiles[trackIndex].path)));
            await player.setVolume(origSongData!.settings.volume);
            await player.setPitch(origSongData!.settings.pitch);
            await player.setLoopMode(LoopMode.all);
            setState(() {
              _semitones = (12 * (log(player.pitch) / log(2))).round();
              _volume = player.volume;
              _lastVolume = _volume;
            });
          }
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('Could not load file ID $fileId')));
        }
      }
    });
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    player.dispose();
    super.dispose();
  }

  void changeTrack(int newIdx) async {
    setState(() {
      trackIndex = newIdx;
    });
    await player.setAudioSource(AudioSource.uri(Uri.file(trackFiles[trackIndex].path)));
    await player.setLoopMode(LoopMode.all);
    setState(() {
      _semitones = (12 * (log(player.pitch) / log(2))).round();
      _volume = player.volume;
      _lastVolume = _volume;
    });
  }

  void saveSettings() async {
    DataFile newSongData = origSongData!;
    newSongData.settings.pitch = player.pitch;
    newSongData.settings.volume = player.volume;
    await File(newSongData.dataPath).writeAsString(jsonEncode(newSongData.jsonFromClass()));
    print("file saved");
  }

  final TextEditingController trackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    fileId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: Text(origSongData?.fileName ?? 'Listen')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 16),
              origSongData != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Track:"),
                        DropdownButton<String>(
                          isDense: true,
                          value: trackIndex.toString(),
                          icon: const Icon(Icons.keyboard_arrow_down),
                          elevation: 16,
                          underline: Container(height: 1, color: Colors.black),
                          onChanged: (String? newTrack) {
                            if (newTrack != null) {
                              changeTrack(int.parse(newTrack));
                              print(newTrack);
                            }
                          },
                          items: List.from(
                            origSongData!.songPaths.map(
                              (item) => DropdownMenuItem<String>(
                                value: origSongData!.songPaths.indexOf(item).toString(),
                                child: Text(
                                  item.split(".").sublist(0, (item.split(".").length - 1)).last.split("_").last,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.audio_file),
                  SizedBox(width: 8),
                  Text(origSongData?.fileName ?? 'File not found'),
                ],
              ),
              SizedBox(height: 12),
              StreamBuilder<Duration?>(
                stream: player.durationStream,
                builder: (context, snapDur) {
                  final total = snapDur.data ?? Duration.zero;
                  return StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, snapPos) {
                      final pos = snapPos.data ?? Duration.zero;
                      double value = total.inMilliseconds > 0 ? pos.inMilliseconds / total.inMilliseconds : 0.0;
                      return Column(
                        children: [
                          Slider(
                            value: value.clamp(0.0, 1.0),
                            onChanged: (v) {
                              if (total.inMilliseconds > 0) {
                                player.seek(Duration(milliseconds: (v * total.inMilliseconds).round()));
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

              // SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      if (player.playing) {
                        player.pause();
                      } else {
                        player.play();
                      }
                    },
                    icon: currentlyPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
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
                                    player.setPitch(_pitchFromSemitones(_semitones));
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
                                  player.setPitch(_pitchFromSemitones(_semitones));
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
                                  player.setPitch(_pitchFromSemitones(_semitones));
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
                                    player.setVolume(_volume);
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
                                  player.setVolume(_volume);
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
                      TextButton.icon(onPressed: saveSettings, label: Text("Save Settings"), icon: Icon(Icons.save))
                    ],
                  ),
                ),
              ),
            ],
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
