import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'recorder_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _notifId = 42;
  static const String _channelId = 'memorec_channel';
  static const String _actionStart = 'ACTION_START';
  static const String _actionStop = 'ACTION_STOP';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onAction,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundAction,
    );

    _initialized = true;
  }

  // Apelat cand userul apasa un buton din notificare
  void _onAction(NotificationResponse response) {
    final payload = response.actionId;
    if (payload == _actionStart) {
      RecorderService.instance.startRecording();
    } else if (payload == _actionStop) {
      RecorderService.instance.stopRecording();
    }
  }

  // Afiseaza notificarea persistenta in starea IDLE (gata de inregistrare)
  Future<void> showIdle() async {
    await _plugin.show(
      _notifId,
      'MemoRec',
      'Apasă START pentru a înregistra',
      _buildDetails(isRecording: false),
    );
  }

  // Afiseaza notificarea persistenta in starea RECORDING
  Future<void> showRecording() async {
    await _plugin.show(
      _notifId,
      'MemoRec — Înregistrare activă ●',
      'Apasă STOP pentru a opri',
      _buildDetails(isRecording: true),
    );
  }

  // Ascunde notificarea
  Future<void> hide() async {
    await _plugin.cancel(_notifId);
  }

  NotificationDetails _buildDetails({required bool isRecording}) {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      'MemoRec Controls',
      channelDescription: 'Controlează înregistrarea din notificări',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,           // nu poate fi swipe-uita
      autoCancel: false,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
      color: isRecording ? Color(0xFFFF4444) : Color(0xFF00E5CC),
      actions: isRecording
          ? [
              const AndroidNotificationAction(
                _actionStop,
                'STOP',
                showsUserInterface: true,
              ),
            ]
          : [
              const AndroidNotificationAction(
                _actionStart,
                'START',
                showsUserInterface: true,
              ),
            ],
    );

    return NotificationDetails(android: androidDetails);
  }

  // Solicita permisiunea de notificari (Android 13+)
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }
}

// Handler pentru background (necesar pentru flutter_local_notifications)
@pragma('vm:entry-point')
void _onBackgroundAction(NotificationResponse response) {
  // Nu putem accesa RecorderService din background in mod direct
  // Actiunile se vor procesa la urmatoarea deschidere a aplicatiei
}
