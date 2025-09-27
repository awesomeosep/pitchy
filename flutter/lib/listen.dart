// import 'package:audioplayers/audioplayers.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';

class Listen extends StatefulWidget {
  const Listen({super.key});

  @override
  State<Listen> createState() => _ListenState();
}

class _ListenState extends State<Listen> {
  late File? file;
  final player = AudioPlayer();
  bool currentlyPlaying = false;
  StreamSubscription<PlayerState>? _playerStateSub;
  // pitch represented as semitones (half-steps). 0 = original pitch
  int _semitones = 0;
  double _volume = 1.0;
  double _lastVolume = 1.0;
  bool _muted = false;

  double _pitchFromSemitones(int s) => pow(2, s / 12).toDouble();

  @override
  void initState() {
    super.initState();
    // keep playing state in sync
    _playerStateSub = player.playerStateStream.listen((state) {
      setState(() {
        currentlyPlaying = state.playing;
      });
    });

    // After the first frame, read the selected file from route args and load it
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is File) {
        file = arg;
        final messenger = ScaffoldMessenger.of(context);
        // check existence before attempting to open the file on the device
        try {
          final exists = await file!.exists();
          if (!exists) {
            messenger.showSnackBar(
              SnackBar(content: Text('${file!.path.split(Platform.pathSeparator).last} not found on device.')),
            );
            return;
          }

          await player.setAudioSource(AudioSource.uri(Uri.file(file!.path)));
          await player.setLoopMode(LoopMode.all);
          // initialize pitch/volume state from player defaults
          _semitones = (12 * (log(player.pitch) / log(2))).round();
          _volume = player.volume;
          _lastVolume = _volume;
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(content: Text('Could not load ${file!.path.split(Platform.pathSeparator).last}: $e')),
          );
        }
      }
    });
  }

  // Removed song list loading; the page expects a File to be passed in via route arguments.

  @override
  void dispose() {
    _playerStateSub?.cancel();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    file = ModalRoute.of(context)!.settings.arguments as File;

    return Scaffold(
      appBar: AppBar(title: Text(file != null ? file!.path.split('/').last : 'Listen')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            SizedBox(height: 12),

            // Current file info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.audio_file),
                SizedBox(width: 8),
                Text(file != null ? file!.path.split(Platform.pathSeparator).last : 'No file selected'),
              ],
            ),

            SizedBox(height: 12),

            // Position slider
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
                    // playerStateStream listener will update currentlyPlaying
                  },
                  icon: currentlyPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Play button and audio controls (pitch, volume, mute)
            Card(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // SizedBox(height: 8),

                    // Pitch control in semitone (half-step) increments
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pitch (semitones)', style: TextStyle(fontWeight: FontWeight.w600)),
                              Slider(
                                value: _semitones.toDouble().clamp(-24.0, 24.0),
                                min: -24,
                                max: 24,
                                divisions: 48,
                                label: '${_semitones >= 0 ? '+' : ''}${_semitones}',
                                onChanged: (v) {
                                  setState(() {
                                    _semitones = v.round();
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
                                  _semitones = (_semitones + 1).clamp(-24, 24);
                                });
                                player.setPitch(_pitchFromSemitones(_semitones));
                              },
                              icon: Icon(Icons.keyboard_double_arrow_up),
                            ),
                            Container(
                              width: 60,
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text('${_semitones >= 0 ? '+' : ''}${_semitones}'),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _semitones = (_semitones - 1).clamp(-24, 24);
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
                  ],
                ),
              ),
            ),
          ],
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
