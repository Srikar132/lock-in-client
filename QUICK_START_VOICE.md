# 🎤 Lumo Voice Assistant - Quick Setup Guide

## ⚡ Immediate Steps to Get Started

### Step 1: Get OpenAI API Key

1. Go to https://platform.openai.com/api-keys
2. Create a new API key
3. Copy the key (starts with `sk-`)

### Step 2: Add API Key

**Method 1: Run with environment variable (Recommended)**
```bash
flutter run --dart-define=OPENAI_API_KEY=sk-your-actual-key-here
```

**Method 2: Temporarily add to config file (Development only)**
1. Open `lib/config/voice_api_config.dart`
2. Replace the apiKey line:
   ```dart
   static const String apiKey = 'sk-your-actual-key-here';
   ```
3. **⚠️ NEVER COMMIT THIS FILE WITH YOUR KEY!**

### Step 3: Install Dependencies

```bash
flutter pub get
```

### Step 4: Test the Voice Assistant

```bash
# Run the app
flutter run

# Or with release mode for better performance
flutter run --release
```

### Step 5: Navigate to Voice Screen

In your app, navigate to the `LumoVoiceBotScreen`:

```dart
// Example navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const LumoVoiceBotScreen(),
  ),
);
```

---

## 📝 Testing Checklist

- [ ] Dependencies installed (`flutter pub get`)
- [ ] API key configured
- [ ] Microphone permission granted
- [ ] Internet connection active
- [ ] OpenAI API has sufficient credits

---

## 🎮 Usage

1. **Tap to speak** - Start listening
2. **Speak your question** - "What's the best study technique?"
3. **Lumo responds** - Real-time voice response
4. **Tap to stop** - Interrupt anytime

---

## 🎨 Features

✅ **Full-duplex conversation** - Natural back-and-forth  
✅ **Ultra-low latency** - ~200-300ms response time  
✅ **Barge-in support** - Interrupt anytime  
✅ **Voice visualization** - See audio levels in real-time  
✅ **Beautiful UI** - Gradient animations and smooth transitions  
✅ **Error handling** - Graceful failure with user feedback  

---

## 🐛 Common Issues

### "Failed to connect to API"
- Check your API key
- Verify internet connection
- Ensure you have OpenAI API credits

### "Microphone permission denied"
- Go to Settings → Apps → Lock In → Permissions
- Enable Microphone permission

### High latency
- Use `flutter run --release` instead of debug mode
- Close background apps
- Use Wi-Fi instead of cellular

### No audio playing
- Check device volume
- Ensure audio output is not muted
- Test on physical device (not emulator)

---

## 💰 Cost Estimation

OpenAI Realtime API pricing (as of Dec 2024):
- Audio input: $0.06 per minute
- Audio output: $0.24 per minute

**Estimated cost per conversation:**
- 5-minute conversation: ~$1.50

💡 **Tip:** Monitor usage at https://platform.openai.com/usage

---

## 🔐 Security Notes

### For Development
```bash
# Use environment variable
flutter run --dart-define=OPENAI_API_KEY=sk-xxx
```

### For Production
**DO NOT** put API keys in the app. Instead:

1. **Create a backend API:**
   ```
   Flutter App → Your Backend → OpenAI API
   ```

2. **Backend handles:**
   - API key storage
   - Rate limiting
   - User authentication
   - Usage monitoring

---

## 📚 Resources

- [OpenAI Realtime API Docs](https://platform.openai.com/docs/guides/realtime)
- [Full Implementation Guide](VOICE_ASSISTANT_README.md)
- [OpenAI API Keys](https://platform.openai.com/api-keys)
- [Troubleshooting Guide](VOICE_TROUBLESHOOTING.md)

---

**Ready to start? Run the app and tap to speak! 🎤**

For detailed documentation, see [VOICE_ASSISTANT_README.md](VOICE_ASSISTANT_README.md)
