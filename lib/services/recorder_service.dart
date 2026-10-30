import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'settings_service.dart';

class RecorderService {
  RecorderService._();
  static final RecorderService instance = RecorderService._();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  Timer? _maxDurationTimer;

  bool get isRecording => _isRecording;

  final StreamController<RecorderState> _stateController =
      StreamController<RecorderState>.broadcast();
  Stream<RecorderState> get stateStream => _stateController.stream;

  Future<bool> startRecording() async {
    if (_isRecording) return false;
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _stateController.add(RecorderState.permissionDenied);
        return false;
      }
      final path = await _buildFilePath();
      final settings = SettingsService.instance;
      final quality = settings.quality;
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: quality.bitRate,
          sampleRate: 44100,
          numChannels: quality.numChannels,
        ),
        path: path,
      );
      _isRecording = true;
      _stateController.add(RecorderState.recording);
      final maxMin = settings.maxDurationMinutes;
      if (maxMin > 0) {
        _maxDurationTimer = Timer(Duration(minutes: maxMin), () {
          stopRecording();
        });
      }
      return true;
    } catch (e) {
      _stateController.add(RecorderState.error);
      return false;
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    try {
      _maxDurationTimer?.cancel();
      _maxDurationTimer = null;
      final path = await _recorder.stop();
      _isRecording = false;
      _stateController.add(RecorderState.stopped);
      return path;
    } catch (e) {
      _isRecording = false;
      _stateController.add(RecorderState.stopped);
      return null;
    }
  }

  static Future<String> getRecordingsDir() async {
    try {
      final extDirs = await getExternalStorageDirectories(
        type: StorageDirectory.music,
      );
      if (extDirs != null && extDirs.isNotEmpty) {
        final dir = Directory("${extDirs.first.path}/MemoRec");
        if (!await dir.exists()) await dir.create(recursive: true);
        return dir.path;
      }
    } catch (_) {}
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory("${appDir.path}/MemoRec");
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<String> _buildFilePath() async {
    final basePath = await getRecordingsDir();
    final now = DateTime.now();
    final name = 'rec_${now.year}${_p(now.month)}${_p(now.day)}_'
        '${_p(now.hour)}${_p(now.minute)}${_p(now.second)}.m4a';
    return '$basePath/$name';
  }

  String _p(int n) => n.toString().padLeft(2, '0');

  void dispose() {
    _maxDurationTimer?.cancel();
    _recorder.dispose();
    _stateController.close();
  }
}

enum RecorderState { recording, stopped, permissionDenied, error }
