import 'dart:async';

import '../models/audio_session.dart';

class AudioControlService {
  AudioControlService()
      : _sessions = [
          AudioSession(name: 'spotify.exe', isPlaying: true, isTarget: true),
          AudioSession(name: 'vlc.exe'),
          AudioSession(name: 'wmplayer.exe'),
        ];

  final List<AudioSession> _sessions;
  bool pauseInsteadOfDucking = true;
  bool isMonitoring = false;

  List<AudioSession> get sessions => List.unmodifiable(_sessions);

  AudioSession get target =>
      _sessions.firstWhere((session) => session.isTarget, orElse: () => _sessions.first);

  void selectTarget(AudioSession session) {
    for (final s in _sessions) {
      s.isTarget = s == session;
    }
  }

  Future<void> startMonitoring() async {
    isMonitoring = true;
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> stopMonitoring() async {
    isMonitoring = false;
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  Future<void> togglePlayback(bool playing) async {
    target.isPlaying = playing;
    await Future<void>.delayed(const Duration(milliseconds: 180));
  }
}
