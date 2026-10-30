import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../services/recorder_service.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  final AudioPlayer _player = AudioPlayer();
  List<File> _allFiles = [];
  List<File> _filteredFiles = [];
  String? _playingPath;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFiles();
    _searchCtrl.addListener(_filter);

    _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    });
    _player.playerStateStream.listen((s) {
      if (mounted) {
        setState(() {
          _isPlaying = s.playing;
          if (s.processingState == ProcessingState.completed) {
            _isPlaying = false;
            _position = Duration.zero;
          }
        });
      }
    });
  }

  Future<void> _loadFiles() async {
    final dirPath = await RecorderService.getRecordingsDir();
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      setState(() { _allFiles = []; _filteredFiles = []; });
      return;
    }
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.m4a'))
        .toList()
      ..sort((a, b) =>
          b.statSync().modified.compareTo(a.statSync().modified));
    setState(() {
      _allFiles = files;
      _filteredFiles = files;
    });
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filteredFiles = q.isEmpty
          ? _allFiles
          : _allFiles
              .where((f) => _label(f.path).toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _togglePlay(String path) async {
    if (_playingPath == path) {
      _isPlaying ? await _player.pause() : await _player.play();
    } else {
      await _player.stop();
      await _player.setFilePath(path);
      setState(() { _playingPath = path; _position = Duration.zero; });
      await _player.play();
    }
  }

  Future<void> _stopPlay() async {
    await _player.stop();
    setState(() { _playingPath = null; _isPlaying = false; _position = Duration.zero; });
  }

  Future<void> _share(String path) async {
    await Share.shareXFiles([XFile(path)]);
  }

  Future<void> _delete(File file) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141929),
        title: const Text('Șterge înregistrarea',
            style: TextStyle(color: Colors.white)),
        content: Text('Ștergi "${_label(file.path)}"?',
            style: TextStyle(color: Colors.grey.shade400)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Anulează',
                  style: TextStyle(color: Colors.grey.shade500))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Șterge',
                  style: TextStyle(color: Color(0xFFFF4444)))),
        ],
      ),
    );
    if (ok == true) {
      if (_playingPath == file.path) await _stopPlay();
      await file.delete();
      _loadFiles();
    }
  }

  // rec_20240528_143022 → 28.05.2024  14:30
  String _label(String path) {
    final name = path.split('/').last.replaceAll('.m4a', '');
    if (name.startsWith('rec_') && name.length >= 15) {
      try {
        final d = name.substring(4, 12);
        final t = name.substring(13);
        return '${d.substring(6, 8)}.${d.substring(4, 6)}.${d.substring(0, 4)}  ${t.substring(0, 2)}:${t.substring(2, 4)}';
      } catch (_) {}
    }
    return name;
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${_p(h)}:${_p(m)}:${_p(s)}';
    return '${_p(m)}:${_p(s)}';
  }

  String _p(int n) => n.toString().padLeft(2, '0');

  String _size(File f) {
    final b = f.lengthSync();
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _player.dispose();
    _searchCtrl.dispose();
    super.dispose();
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
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('ÎNREGISTRĂRI',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4)),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text('${_filteredFiles.length}',
                        style: const TextStyle(
                            color: Color(0xFF00E5CC),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141929),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Caută după dată...',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0xFF00E5CC), size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: Colors.grey.shade600, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _filter();
                            })
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Lista
            Expanded(
              child: _filteredFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic_none,
                              color: Colors.grey.shade700, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            _allFiles.isEmpty
                                ? 'Nicio înregistrare încă'
                                : 'Nicio înregistrare găsită',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredFiles.length,
                      itemBuilder: (_, i) => _buildCard(_filteredFiles[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(File file) {
    final path = file.path;
    final active = _playingPath == path;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1A2540) : const Color(0xFF141929),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? const Color(0xFF00E5CC).withOpacity(0.4)
              : Colors.white.withOpacity(0.06),
          width: active ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                // Play button
                GestureDetector(
                  onTap: () => _togglePlay(path),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00E5CC).withOpacity(0.1),
                      border: Border.all(
                          color: const Color(0xFF00E5CC), width: 1.5),
                    ),
                    child: Icon(
                      active && _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: const Color(0xFF00E5CC), size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_label(path),
                          style: TextStyle(
                            color: active ? Colors.white : Colors.white70,
                            fontSize: 14,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal,
                          )),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(_size(file),
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11)),
                          if (active) ...[
                            const SizedBox(width: 10),
                            Text(
                              '${_fmt(_position)} / ${_fmt(_duration)}',
                              style: const TextStyle(
                                  color: Color(0xFF00E5CC), fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      color: Color(0xFF00E5CC), size: 20),
                  onPressed: () => _share(path),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.grey.shade600, size: 20),
                  onPressed: () => _delete(file),
                ),
              ],
            ),
          ),

          // Progress bar
          if (active)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF00E5CC),
                      inactiveTrackColor: Colors.white.withOpacity(0.1),
                      thumbColor: const Color(0xFF00E5CC),
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: _duration.inMilliseconds > 0
                          ? (_position.inMilliseconds /
                                  _duration.inMilliseconds)
                              .clamp(0.0, 1.0)
                          : 0.0,
                      onChanged: (v) async {
                        await _player.seek(Duration(
                            milliseconds:
                                (v * _duration.inMilliseconds).round()));
                      },
                    ),
                  ),
                  GestureDetector(
                    onTap: _stopPlay,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_circle_outlined,
                            color: Colors.grey.shade600, size: 15),
                        const SizedBox(width: 6),
                        Text('OPREȘTE REDAREA',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                                letterSpacing: 2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
