# 🔧 Voice Assistant Troubleshooting Guide

## 🚨 Common Issues & Solutions

---

## 1. "Failed to connect to API"

### Symptoms
- Error message on app launch
- Red error state background
- Cannot initialize voice session

### Solutions

#### Check API Key
```bash
# Verify your API key format
# Should start with: sk-proj-...
echo $OPENAI_API_KEY
```

#### Run with correct key
```bash
flutter run --dart-define=OPENAI_API_KEY=sk-your-actual-key
```

#### Verify API access
1. Visit https://platform.openai.com/api-keys
2. Check if key is active
3. Verify you have API credits
4. Check if Realtime API is enabled for your account

#### Check network
```bash
# Test internet connection
ping api.openai.com

# Test WebSocket connectivity
curl -i -N -H "Connection: Upgrade" \
     -H "Upgrade: websocket" \
     https://api.openai.com/v1/realtime
```

---

## 2. "Microphone permission denied"

### Symptoms
- "Failed to start recording" message
- No audio visualization
- Cannot enter listening state

### Solutions

#### Android
```bash
# Grant permission via ADB
adb shell pm grant com.example.lock_in android.permission.RECORD_AUDIO

# Or manually:
# Settings → Apps → Lock In → Permissions → Microphone → Allow
```

#### iOS
```
Settings → Privacy → Microphone → Lock In → Enable
```

#### Reset permissions
```bash
# Android
adb shell pm reset-permissions com.example.lock_in

# Then restart app
```

#### Check manifest
Verify `AndroidManifest.xml` has:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

---

## 3. High Latency / Slow Response

### Symptoms
- 2-5 second delay before response
- Choppy audio playback
- UI lag

### Solutions

#### Use Release Mode
```bash
# Instead of debug mode
flutter run --release
```

#### Check Network
- Use Wi-Fi instead of cellular
- Speed test: https://fast.com
- Minimum: 5 Mbps upload, 10 Mbps download

#### Reduce Chunk Size
Edit `lib/config/voice_api_config.dart`:
```dart
static const int chunkDurationMs = 50;  // Lower = faster
```

#### Close Background Apps
```bash
# Android
adb shell am force-stop <package-name>
```

#### Optimize VAD Settings
```dart
// More aggressive detection
static const double silenceThreshold = 0.005;
static const int silenceDurationMs = 500;
```

---

## 4. No Audio Playback

### Symptoms
- See transcript but hear nothing
- Audio visualizer works but no sound
- "Speaking" state but silent

### Solutions

#### Check Device Volume
- Ensure media volume is up
- Test with other audio apps
- Check mute switch (iOS)

#### Verify Audio Output
```bash
# Android
adb shell dumpsys audio

# Look for active audio streams
```

#### Test Audio Player
```dart
// Add debug logging in audio_player_service.dart
print('🔊 Playing chunk: ${chunk.length} bytes');
```

#### Use Physical Device
- Emulators have audio limitations
- Test on real device for best results

#### Check Format Compatibility
- Ensure PCM format support
- Sample rate: 24kHz
- Bit depth: 16-bit

---

## 5. App Crashes on Launch

### Symptoms
- App closes immediately
- White screen
- Build errors

### Solutions

#### Clean Build
```bash
flutter clean
flutter pub get
flutter run
```

#### Check Dependencies
```bash
flutter pub outdated
flutter pub upgrade
```

#### Verify Package Integrity
```bash
# Remove and reinstall
rm -rf pubspec.lock
rm -rf .dart_tool
flutter pub get
```

#### Check Platform Setup
```bash
# Android
cd android && ./gradlew clean

# iOS
cd ios && pod deintegrate && pod install
```

---

## 6. "WebSocket connection closed"

### Symptoms
- Disconnects during conversation
- Intermittent connectivity
- "Error occurred" state randomly

### Solutions

#### Implement Reconnection
Add to `realtime_service.dart`:
```dart
Future<void> reconnect() async {
  await disconnect();
  await Future.delayed(Duration(seconds: 2));
  await connect();
}
```

#### Check Firewall
- VPN may block WebSocket
- Corporate firewall restrictions
- Router settings

#### Monitor Connection
```dart
_channel!.stream.listen(
  _handleMessage,
  onDone: () {
    print('⚠️ Connection closed, reconnecting...');
    reconnect();
  },
);
```

---

## 7. Memory Leaks / High Memory Usage

### Symptoms
- App slows down over time
- Memory usage keeps increasing
- Eventually crashes

### Solutions

#### Dispose Resources
Verify in `voice_session_provider.dart`:
```dart
@override
Future<void> dispose() async {
  await _audioSubscription?.cancel();
  await _audioService.dispose();
  await _realtimeService.dispose();
  await _playerService.dispose();
  super.dispose();
}
```

#### Clear Audio Queue
```dart
// In audio_player_service.dart
Future<void> clearQueue() async {
  _audioQueue.clear();
  await _deleteOldFiles();
}
```

#### Monitor Memory
```bash
# Android
adb shell dumpsys meminfo com.example.lock_in

# Look for memory growth over time
```

---

## 8. Choppy/Distorted Audio

### Symptoms
- Audio playback stutters
- Robotic voice
- Crackling sounds

### Solutions

#### Increase Buffer Size
```dart
// In audio_player_service.dart
static const int minBufferChunks = 3;
```

#### Check Sample Rate
```dart
// Ensure consistency
static const int sampleRate = 24000;  // Must match API
```

#### Reduce Concurrent Operations
- Don't run heavy tasks during playback
- Profile with Flutter DevTools

#### Use Hardware Acceleration
```xml
<!-- AndroidManifest.xml -->
<application android:hardwareAccelerated="true">
```

---

## 9. Conversation History Not Showing

### Symptoms
- Messages disappear
- UI doesn't update
- State not persisting

### Solutions

#### Check State Updates
```dart
// Debug in voice_session_provider.dart
print('📝 Messages: ${state.messages.length}');
```

#### Verify UI Binding
```dart
// In lumo_voice_bot_screen.dart
final voiceState = ref.watch(voiceSessionProvider);
print('🔄 State updated: ${voiceState.state}');
```

#### Check Message Creation
```dart
final message = VoiceMessage(
  id: _uuid.v4(),  // Unique ID
  role: 'user',
  content: transcript,
  timestamp: DateTime.now(),
);
```

---

## 10. API Rate Limit / Cost Issues

### Symptoms
- "Rate limit exceeded" error
- Unexpected API bills
- Slow response after many requests

### Solutions

#### Check Usage
Visit: https://platform.openai.com/usage

#### Set Spending Limits
1. Go to https://platform.openai.com/account/limits
2. Set monthly budget
3. Enable email alerts

#### Implement Rate Limiting
```dart
// Add to realtime_service.dart
DateTime? _lastRequestTime;

void sendAudio(Uint8List audioChunk) {
  final now = DateTime.now();
  if (_lastRequestTime != null) {
    final diff = now.difference(_lastRequestTime!);
    if (diff.inMilliseconds < 100) {
      return;  // Skip if too frequent
    }
  }
  _lastRequestTime = now;
  // ... send audio
}
```

#### Use Backend Proxy
```
Flutter → Your Backend → OpenAI
          (rate limiting)
```

---

## 🛠️ Debugging Tools

### Enable Verbose Logging
```dart
// Add to each service
static const bool _debug = true;

if (_debug) print('🎤 [AudioStream] Recording started');
```

### Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Network Inspector
```bash
# Use Charles Proxy or Wireshark
# Monitor WebSocket traffic
```

### Audio Analysis
```dart
// Calculate audio metrics
void _analyzeAudio(Uint8List chunk) {
  final level = _calculateAudioLevel(chunk);
  print('📊 Audio level: ${level.toStringAsFixed(3)}');
}
```

---

## 📱 Platform-Specific Issues

### Android

#### Issue: No audio on Android 12+
**Solution:** Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

#### Issue: Background audio stops
**Solution:** Implement foreground service

### iOS

#### Issue: App killed in background
**Solution:** Enable background audio capability

#### Issue: Simulator audio not working
**Solution:** Use physical device for testing

---

## 🔍 Quick Diagnostic Checklist

Run this checklist when encountering issues:

```
□ API key is valid and has credits
□ Internet connection is stable (>5 Mbps)
□ Microphone permission granted
□ Using release build (not debug)
□ Testing on physical device
□ No VPN/firewall blocking WebSocket
□ Latest dependencies installed
□ Clean build performed
□ Audio output not muted
□ Sufficient device storage
```

---

## 📞 Getting Help

### Check Logs
```dart
// Look for emoji-prefixed logs
🎤 = Audio operations
✅ = Success
❌ = Error
🔌 = Connection
💬 = Message handling
```

### Enable All Logging
```bash
flutter run --verbose
```

### Test Individual Components
```dart
// Test audio capture
final service = AudioStreamService();
await service.startRecording();

// Test WebSocket
final realtime = RealtimeService();
await realtime.connect();
```

---

## 📚 Additional Resources

- **OpenAI Status:** https://status.openai.com
- **OpenAI Docs:** https://platform.openai.com/docs
- **Flutter Issues:** https://github.com/flutter/flutter/issues
- **Package Issues:** 
  - record: https://github.com/llfbandit/record/issues
  - web_socket_channel: https://github.com/dart-lang/web_socket_channel/issues

---

## 💡 Prevention Tips

1. **Always test on physical devices**
2. **Use environment variables for keys**
3. **Monitor API usage regularly**
4. **Implement proper error handling**
5. **Test with poor network conditions**
6. **Profile memory usage**
7. **Set up crash reporting**
8. **Keep dependencies updated**

---

**Still stuck?** Check the console logs for emoji-prefixed messages - they'll guide you to the issue! 🔍
