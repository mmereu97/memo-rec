# 🎙️ MemoRec

**A one-tap audio recorder for Android, built for real meetings and notes.** Press record, put the phone down, and it keeps recording until you stop it or the time limit you chose runs out.

I use it daily on my phone.

**Tech:** Flutter / Dart · record (AAC) · just_audio · flutter_local_notifications · share_plus · SharedPreferences

---

## ✨ Features

- **One big button** to start and stop; a live timer and a clear "recording" state.
- **Three quality presets:** 32 kbps mono (small files), 128 kbps mono (balanced), 320 kbps stereo (best quality); AAC at 44.1 kHz.
- **Automatic stop** after a duration you choose (up to 8 hours) or unlimited, so a forgotten recording does not fill the phone.
- **Persistent notification** while recording, so you always know the microphone is on (can be turned off).
- **Recordings list:** search by date, play and pause, share (WhatsApp, e-mail, Drive…) and delete with confirmation; file size shown for each recording.
- Files are saved automatically when recording stops, in the phone's `Music/MemoRec` folder, so they are easy to find from any file manager.

## 🏗️ Structure

```
lib/
  main.dart
  services/recorder_service.dart       recording, file naming, auto-stop
  services/settings_service.dart       quality, time limit, notification (persisted)
  services/notification_service.dart   the "recording in progress" notification
  screens/home_screen.dart             record / stop
  screens/recordings_screen.dart       list, search, playback, share, delete
  screens/settings_screen.dart
```

## 🚀 Build

```bash
flutter pub get
flutter test
flutter build apk --release
```

The interface is in Romanian.

---

## 👤 Author

Mihai Mereu · [GitHub](https://github.com/mmereu97)
