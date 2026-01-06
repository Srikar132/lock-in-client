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
- Test internet connection
- Ensure no VPN/firewall blocking WebSocket

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

#### Check manifest
Verify `AndroidManifest.xml` has:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
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

#### Close Background Apps
- Close unnecessary apps
- Restart device if needed

#### Optimize VAD Settings
Edit `lib/config/voice_api_config.dart`:
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

#### Check Firewall
- VPN may block WebSocket
- Corporate firewall restrictions
- Router settings

#### Check Internet Stability
- Use stable Wi-Fi
- Avoid switching networks during conversation

---

## 7. Memory Leaks / High Memory Usage

### Symptoms
- App slows down over time
- Memory usage keeps increasing
- Eventually crashes

### Solutions

#### Dispose Resources
Verify proper disposal in `voice_session_provider.dart`

#### Monitor Memory
```bash
# Android
adb shell dumpsys meminfo com.example.lock_in
```

---

## 8. Choppy/Distorted Audio

### Symptoms
- Audio playback stutters
- Robotic voice
- Crackling sounds

### Solutions

#### Check Sample Rate
Ensure consistency in `voice_api_config.dart`:
```dart
static const int sampleRate = 24000;  // Must match API
```

#### Reduce Concurrent Operations
- Don't run heavy tasks during playback
- Close background apps

---

## 9. API Rate Limit / Cost Issues

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

#### Use Backend Proxy (Production)
```
Flutter → Your Backend → OpenAI
          (rate limiting)
```

---

## 🛠️ Debugging Tools

### Enable Verbose Logging
Look for emoji-prefixed logs:
- 🎤 = Audio operations
- ✅ = Success
- ❌ = Error
- 🔌 = Connection
- 💬 = Message handling

### Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

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

## 📚 Additional Resources

- **OpenAI Status:** https://status.openai.com
- **OpenAI Docs:** https://platform.openai.com/docs
- **Flutter Issues:** https://github.com/flutter/flutter/issues

---

## 💡 Prevention Tips

1. **Always test on physical devices**
2. **Use environment variables for keys**
3. **Monitor API usage regularly**
4. **Implement proper error handling**
5. **Test with poor network conditions**
6. **Keep dependencies updated**

---

**Still stuck?** Check the console logs for emoji-prefixed messages - they'll guide you to the issue! 🔍
