# 🎤 Lumo Voice Assistant - Implementation Guide

## Overview
A production-ready voice assistant integrated into your LOCK-IN app, featuring:
- ✅ **Full-duplex streaming** (200-300ms latency)
- ✅ **Real-time STT, LLM, and TTS** via OpenAI Realtime API
- ✅ **Barge-in support** - interrupt anytime
- ✅ **Voice Activity Detection** (VAD)
- ✅ **Real-time audio visualization**
- ✅ **Reactive state management** with Riverpod

---

## 🏗️ Architecture

```
┌─────────────┐
│ Microphone  │ → PCM audio (24kHz)
└─────┬───────┘
      ↓
┌──────────────────────────┐
│ AudioStreamService       │ → Continuous streaming
└─────┬────────────────────┘
      ↓
┌───────────────────────────────────┐
│ RealtimeService (WebSocket)       │ → OpenAI Realtime API
│ • Streaming STT                   │
│ • Streaming LLM tokens            │
│ • Streaming TTS audio             │
└─────┬─────────────────────────────┘
      ↓
┌──────────────────────────┐
│ AudioPlayerService       │ → Play while generating
└──────────────────────────┘
```

**Nothing waits for completion. Everything streams.**

---

## 📁 Project Structure

```
lib/
├── config/
│   └── voice_api_config.dart          # API configuration
├── models/
│   └── voice_state.dart                # State models
├── services/
│   ├── audio_stream_service.dart       # Microphone capture
│   ├── audio_player_service.dart       # Audio playback
│   └── realtime_service.dart           # WebSocket connection
├── presentation/
│   ├── screens/
│   │   └── lumo_voice_bot_screen.dart  # Main UI
│   └── providers/
│       └── voice_session_provider.dart # State management
```

---

## 🚀 Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure OpenAI API Key

**Option A: Environment Variable (Recommended)**

Run with:
```bash
flutter run --dart-define=OPENAI_API_KEY=sk-your-key-here
```

**Option B: Direct Configuration (Development Only)**

Open `lib/config/voice_api_config.dart` and replace:
```dart
static const String apiKey = 'YOUR_OPENAI_API_KEY';
```

⚠️ **NEVER commit API keys to version control!**

### 3. Platform-Specific Setup

#### Android
Permissions already added to `AndroidManifest.xml`:
- ✅ RECORD_AUDIO
- ✅ MODIFY_AUDIO_SETTINGS
- ✅ INTERNET

#### iOS
Permissions already added to `Info.plist`:
- ✅ NSMicrophoneUsageDescription
- ✅ NSSpeechRecognitionUsageDescription
- ✅ Background audio mode

### 4. Run the App

```bash
# Debug mode
flutter run

# Release mode (better performance)
flutter run --release
```

---

## 🎯 How It Works

### Audio Flow Pipeline

1. **Microphone** captures PCM audio at 24kHz
2. **Audio chunks** sent to OpenAI Realtime API via WebSocket
3. **STT** transcribes speech in real-time (partial transcripts)
4. **LLM** generates response tokens as they arrive
5. **TTS** synthesizes audio chunks immediately
6. **Audio plays** while next chunks generate

### State Machine

```
IDLE → LISTENING → THINKING → SPEAKING → IDLE
         ↑            ↓
         └─ INTERRUPT ─┘
```

---

## 📱 Usage in Your App

### Navigate to Voice Screen

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const LumoVoiceBotScreen(),
  ),
);
```

### Or use named routes:

```dart
// In main.dart
MaterialApp(
  routes: {
    '/voice': (context) => const LumoVoiceBotScreen(),
  },
);

// Navigate
Navigator.pushNamed(context, '/voice');
```

---

## 🐛 Troubleshooting

### No audio captured

**Check permissions:**
```bash
# Android
adb shell pm grant com.example.lock_in android.permission.RECORD_AUDIO

# iOS
Reset permissions in Settings → Privacy → Microphone
```

### WebSocket connection fails

1. ✅ Verify API key is correct
2. ✅ Check internet connection
3. ✅ Ensure OpenAI API access (requires paid account)
4. ✅ Check firewall/proxy settings

### High latency

- Use **release build**: `flutter run --release`
- Close background apps
- Use wired internet if possible

### Audio playback issues

- Verify device audio output
- Check volume settings
- Use physical device (not simulator for best results)

---

## 🔒 Security Best Practices

1. ✅ **Never commit API keys**
   ```bash
   # Add to .gitignore
   *.env
   **/voice_api_config.dart
   ```

2. ✅ **Use environment variables**
   ```bash
   flutter run --dart-define=OPENAI_API_KEY=your-key
   ```

3. ✅ **Implement rate limiting** (backend proxy recommended)

4. ✅ **Add user authentication** before API access

5. ✅ **Use HTTPS/WSS only**

---

## 📄 Dependencies

```yaml
dependencies:
  flutter_riverpod: ^3.0.3      # State management
  record: ^5.2.1                 # Audio recording
  audioplayers: ^6.0.0          # Audio playback
  web_socket_channel: ^2.4.0    # WebSocket
  http: ^1.2.0                   # HTTP requests
  path_provider: ^2.1.2          # File storage
  uuid: ^4.3.3                   # Unique IDs
```

---

## ⚡ Quick Start Commands

```bash
# Install dependencies
flutter pub get

# Run with API key
flutter run --dart-define=OPENAI_API_KEY=sk-your-key-here

# Build release
flutter build apk --release

# Clean build
flutter clean && flutter pub get
```

---

**That's it! You now have a production-ready voice assistant! 🎉**

For questions or improvements, check the code comments or OpenAI documentation.
