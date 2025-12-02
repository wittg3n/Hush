class AudioSession {
  AudioSession({required this.name, this.isPlaying = false, this.isTarget = false});

  final String name;
  bool isPlaying;
  bool isTarget;
}
