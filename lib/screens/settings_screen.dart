import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService.instance;
  final _notif = NotificationService.instance;

  late RecordingQuality _quality;
  late int _maxDuration;
  late bool _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _quality = _settings.quality;
    _maxDuration = _settings.maxDurationMinutes;
    _notificationsEnabled = _settings.notificationsEnabled;
  }

  Future<void> _save() async {
    await _settings.setQuality(_quality);
    await _settings.setMaxDurationMinutes(_maxDuration);

    // Notificari
    if (_notificationsEnabled != _settings.notificationsEnabled) {
      await _settings.setNotificationsEnabled(_notificationsEnabled);
      if (_notificationsEnabled) {
        final granted = await _notif.requestPermission();
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Permisiunea pentru notificări a fost refuzată.')),
          );
          setState(() => _notificationsEnabled = false);
          await _settings.setNotificationsEnabled(false);
          return;
        }
        await _notif.showIdle();
      } else {
        await _notif.hide();
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setări salvate'),
          backgroundColor: Color(0xFF00E5CC),
        ),
      );
      Navigator.pop(context);
    }
  }

  String _fmtDuration(int min) {
    if (min == 0) return 'Nelimitat';
    if (min < 60) return '$min min';
    final h = min ~/ 60;
    final m = min % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('SETĂRI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      )),
                  const Spacer(),
                  TextButton(
                    onPressed: _save,
                    child: const Text('SALVEAZĂ',
                        style: TextStyle(
                            color: Color(0xFF00E5CC),
                            letterSpacing: 2,
                            fontSize: 12)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── CALITATE ──────────────────────────────────────
                  _sectionTitle('CALITATE ÎNREGISTRARE'),
                  const SizedBox(height: 12),
                  ...RecordingQuality.values.map((q) => _qualityTile(q)),

                  const SizedBox(height: 28),

                  // ── DURATA MAXIMA ─────────────────────────────────
                  _sectionTitle('DURATĂ MAXIMĂ'),
                  const SizedBox(height: 12),
                  _durationSlider(),

                  const SizedBox(height: 28),

                  // ── NOTIFICARI ────────────────────────────────────
                  _sectionTitle('NOTIFICĂRI'),
                  const SizedBox(height: 12),
                  _notificationToggle(),
                  if (_notificationsEnabled) ...[
                    const SizedBox(height: 10),
                    _notificationInfo(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: TextStyle(
          color: const Color(0xFF00E5CC).withOpacity(0.7),
          fontSize: 10,
          letterSpacing: 3,
          fontWeight: FontWeight.bold,
        ));
  }

  Widget _qualityTile(RecordingQuality q) {
    final selected = _quality == q;
    return GestureDetector(
      onTap: () => setState(() => _quality = q),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00E5CC).withOpacity(0.08)
              : const Color(0xFF141929),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF00E5CC).withOpacity(0.5)
                : Colors.white.withOpacity(0.07),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFF00E5CC) : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.label,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      )),
                  const SizedBox(height: 3),
                  Text(q.description,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _durationSlider() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141929),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  color: Colors.white54, size: 18),
              const SizedBox(width: 10),
              Text('Oprire automată după',
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5CC).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_fmtDuration(_maxDuration),
                    style: const TextStyle(
                        color: Color(0xFF00E5CC),
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF00E5CC),
              inactiveTrackColor: Colors.white12,
              thumbColor: const Color(0xFF00E5CC),
              overlayColor: const Color(0xFF00E5CC).withOpacity(0.1),
              trackHeight: 3,
            ),
            child: Slider(
              value: _maxDuration.toDouble(),
              min: 0,
              max: 480,
              divisions: 96,
              onChanged: (v) =>
                  setState(() => _maxDuration = (v / 5).round() * 5),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nelimitat',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 10)),
              Text('8 ore',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          // Butoane rapide
          Wrap(
            spacing: 8,
            children: [0, 30, 60, 120, 240].map((min) {
              final sel = _maxDuration == min;
              return GestureDetector(
                onTap: () => setState(() => _maxDuration = min),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF00E5CC).withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF00E5CC)
                          : Colors.white12,
                    ),
                  ),
                  child: Text(_fmtDuration(min),
                      style: TextStyle(
                        color: sel
                            ? const Color(0xFF00E5CC)
                            : Colors.grey.shade500,
                        fontSize: 11,
                      )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _notificationToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF141929),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Notificare persistentă',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        subtitle: Text(
          'Controlează înregistrarea fără a deschide aplicația',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        secondary: Icon(Icons.notifications_outlined,
            color: _notificationsEnabled
                ? const Color(0xFF00E5CC)
                : Colors.grey.shade600,
            size: 22),
        value: _notificationsEnabled,
        activeColor: const Color(0xFF00E5CC),
        onChanged: (v) => setState(() => _notificationsEnabled = v),
      ),
    );
  }

  Widget _notificationInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF00E5CC).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF00E5CC).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: Color(0xFF00E5CC), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Notificarea va rămâne vizibilă în bara de stare. '
              'Apasă START sau STOP direct din notificare '
              'pentru a controla înregistrarea fără să deschizi aplicația.',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
