import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/audio_session.dart';
import 'services/audio_control_service.dart';
import 'ui/shadcn.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const HushApp());
}

class HushApp extends StatelessWidget {
  const HushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hush',
      debugShowCheckedModeBanner: false,
      theme: ShadTheme.dark(),
      home: const HushHome(),
    );
  }
}

class HushHome extends StatefulWidget {
  const HushHome({super.key});

  @override
  State<HushHome> createState() => _HushHomeState();
}

class _HushHomeState extends State<HushHome> {
  late final AudioControlService _service;
  final List<String> _log = <String>[];

  @override
  void initState() {
    super.initState();
    _service = AudioControlService();
    _log.add('Monitor waiting to start');
  }

  Future<void> _startOrStopMonitoring() async {
    if (_service.isMonitoring) {
      await _service.stopMonitoring();
      _pushLog('Monitoring paused');
    } else {
      await _service.startMonitoring();
      _pushLog('Monitoring started for ${_service.target.name}');
    }
    setState(() {});
  }

  Future<void> _togglePlayback() async {
    final playing = !_service.target.isPlaying;
    await _service.togglePlayback(playing);
    _pushLog(playing ? 'Playback resumed' : 'Playback paused');
    setState(() {});
  }

  void _pushLog(String message) {
    setState(() {
      _log.insert(0, message);
      if (_log.length > 8) {
        _log.removeLast();
      }
    });
  }

  void _selectSession(AudioSession session) {
    _service.selectTarget(session);
    _pushLog('Target switched to ${session.name}');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _service.sessions;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Hush', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: const [
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ShadPill(label: 'Black & White'))
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const _HeroText(),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: isWide
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              ShadCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Media focus',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700)),
                                            const SizedBox(height: 4),
                                            Text(
                                                'Pick the app we should pause or duck when other audio appears.',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                        color:
                                                            Colors.grey[400])),
                                          ],
                                        ),
                                        ShadSwitch(
                                          value: _service.pauseInsteadOfDucking,
                                          label: _service.pauseInsteadOfDucking
                                              ? 'Pause instead of duck'
                                              : 'Lower volume',
                                          onChanged: (value) {
                                            setState(() => _service
                                                .pauseInsteadOfDucking = value);
                                            _pushLog(value
                                                ? 'Configured to pause playback'
                                                : 'Configured to lower volume');
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        ...sessions
                                            .map((session) => _SessionTile(
                                                  session: session,
                                                  onSelect: () =>
                                                      _selectSession(session),
                                                )),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ShadButton(
                                            label: _service.isMonitoring
                                                ? 'Pause monitoring'
                                                : 'Start monitoring',
                                            icon: _service.isMonitoring
                                                ? Icons
                                                    .pause_circle_filled_rounded
                                                : Icons
                                                    .play_circle_fill_rounded,
                                            onPressed: _startOrStopMonitoring,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ShadGhostButton(
                                            label: _service.target.isPlaying
                                                ? 'Pause music'
                                                : 'Resume music',
                                            onPressed: _togglePlayback,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ShadCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Live status',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                        ShadPill(
                                          label: _service.isMonitoring
                                              ? 'Monitoring'
                                              : 'Idle',
                                          icon: _service.isMonitoring
                                              ? Icons.circle
                                              : Icons.stop_circle_outlined,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _service.isMonitoring
                                          ? 'Hush is listening for competing audio sources.'
                                          : 'Tap start to begin watching for other apps.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                            width: isWide ? 16 : 0, height: isWide ? 0 : 16),
                        Expanded(
                          flex: 2,
                          child: ShadCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Activity log',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700)),
                                    ShadGhostButton(
                                        label: 'Clear',
                                        onPressed: () => setState(_log.clear)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: _log.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(),
                                    itemBuilder: (context, index) {
                                      final entry = _log[index];
                                      return Text(entry,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                  color: Colors.grey[300]));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onSelect});

  final AudioSession session;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: session.isTarget ? Colors.white : const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: session.isTarget ? Colors.white : const Color(0xFF2A2A2A)),
        boxShadow: session.isTarget
            ? [
                const BoxShadow(
                    color: Colors.white24, blurRadius: 24, spreadRadius: 1)
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note_rounded,
                  color: session.isTarget ? Colors.black : Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  session.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: session.isTarget ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            session.isTarget ? 'Primary focus' : 'Available device',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: session.isTarget ? Colors.black87 : Colors.grey[400],
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: session.isTarget
                    ? ShadGhostButton(label: 'Selected', onPressed: null)
                    : ShadGhostButton(
                        label: 'Make target', onPressed: onSelect),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stay focused. Keep sound civil',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Hush watches for competing audio and pauses or lowers your chosen player so meetings stay distraction-free.',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.grey[400]),
        ),
      ],
    );
  }
}
