import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Calitate inregistrare
  RecordingQuality get quality {
    final v = _prefs.getString('quality') ?? 'medium';
    return RecordingQuality.values.firstWhere(
      (q) => q.name == v,
      orElse: () => RecordingQuality.medium,
    );
  }
  Future<void> setQuality(RecordingQuality q) =>
      _prefs.setString('quality', q.name);

  // Durata maxima in minute (0 = nelimitat)
  int get maxDurationMinutes => _prefs.getInt('max_duration') ?? 0;
  Future<void> setMaxDurationMinutes(int v) =>
      _prefs.setInt('max_duration', v);

  // Notificari active
  bool get notificationsEnabled =>
      _prefs.getBool('notifications_enabled') ?? false;
  Future<void> setNotificationsEnabled(bool v) =>
      _prefs.setBool('notifications_enabled', v);
}

enum RecordingQuality {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case RecordingQuality.low:
        return 'Scăzută';
      case RecordingQuality.medium:
        return 'Medie';
      case RecordingQuality.high:
        return 'Înaltă';
    }
  }

  String get description {
    switch (this) {
      case RecordingQuality.low:
        return '32 kbps · Mono · fișiere mici';
      case RecordingQuality.medium:
        return '128 kbps · Mono · echilibrat';
      case RecordingQuality.high:
        return '320 kbps · Stereo · calitate maximă';
    }
  }

  int get bitRate {
    switch (this) {
      case RecordingQuality.low:
        return 32000;
      case RecordingQuality.medium:
        return 128000;
      case RecordingQuality.high:
        return 320000;
    }
  }

  int get numChannels {
    switch (this) {
      case RecordingQuality.low:
        return 1;
      case RecordingQuality.medium:
        return 1;
      case RecordingQuality.high:
        return 2;
    }
  }
}
