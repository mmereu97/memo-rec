import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/recorder_service.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import 'recordings_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _recorder = RecorderService.instance;
  final _settings = SettingsService.instance;
  final _notif = NotificationService.instance;

  late AnimationController _waveController;
  bool _isRecording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800),
    )..repeat();

    _sub = _recorder.stateStream.listen((state) {
      final recording = state == RecorderState.recording;
      setState(() => _isRecording = recording);
      if (recording) {
        _elapsed = Duration.zero;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() => _elapsed += const Duration(seconds: 1));
        });
        if (_settings.notificationsEnabled) _notif.showRecording();
      } else {
        _timer?.cancel();
        _elapsed = Duration.zero;
        if (_settings.notificationsEnabled) _notif.showIdle();
      }
    });

    if (_settings.notificationsEnabled) _notif.showIdle();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final ok = await _recorder.startRecording();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu s-a putut porni. Verifică permisiunea microfonului.')),
      );
    }
  }

  Future<void> _stop() async { await _recorder.stopRecording(); }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${_p(h)}:${_p(m)}:${_p(s)}';
    return '${_p(m)}:${_p(s)}';
  }
  String _p(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text('MEMO REC', style: TextStyle(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.bold, letterSpacing: 4,
                  )),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.folder_outlined, color: Colors.white70),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RecordingsScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                    onPressed: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 70,
                      child: _isRecording
                          ? AnimatedBuilder(
                              animation: _waveController,
                              builder: (_, __) => Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(24, (i) {
                                  final phase = (_waveController.value * 2 * pi) + (i * 0.38);
                                  final h = 8.0 + (sin(phase) * 0.5 + 0.5) * 44.0;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    width: 3, height: h,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF4444).withOpacity(0.5 + sin(phase) * 0.5),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  );
                                }),
                              ),
                            )
                          : const SizedBox(),
                    ),

                    const SizedBox(height: 24),

                    if (_isRecording) ...[
                      const Text('ÎNREGISTRARE ACTIVĂ', style: TextStyle(
                        color: Color(0xFFFF4444), fontSize: 12,
                        letterSpacing: 3, fontWeight: FontWeight.w600,
                      )),
                      const SizedBox(height: 12),
                      Text(_fmt(_elapsed), style: const TextStyle(
                        color: Color(0xFFFF4444), fontSize: 52,
                        fontWeight: FontWeight.w200, letterSpacing: 4,
                      )),
                      if (_settings.maxDurationMinutes > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('MAX ${_settings.maxDurationMinutes} MIN',
                            style: TextStyle(color: Colors.grey.shade600,
                                fontSize: 10, letterSpacing: 3)),
                        ),
                    ] else ...[
                      Text('Pregătit', style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 16, letterSpacing: 2,
                      )),
                      const SizedBox(height: 8),
                      Text(_settings.quality.label, style: TextStyle(
                        color: const Color(0xFF00E5CC).withOpacity(0.6),
                        fontSize: 11, letterSpacing: 2,
                      )),
                    ],

                    const SizedBox(height: 56),

                    if (!_isRecording)
                      _buildButton(label: 'ÎNREGISTREAZĂ',
                        icon: Icons.fiber_manual_record,
                        color: const Color(0xFFFF4444), onTap: _start)
                    else
                      _buildButton(label: 'OPREȘTE',
                        icon: Icons.stop_rounded,
                        color: const Color(0xFF00E5CC), onTap: _stop),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text('Înregistrările se salvează automat la oprire',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 11, letterSpacing: 1),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({required String label, required IconData icon,
      required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(60),
          border: Border.all(color: color, width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 24, spreadRadius: 2)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(color: color, fontSize: 17,
                fontWeight: FontWeight.bold, letterSpacing: 3)),
          ],
        ),
      ),
    );
  }
}
