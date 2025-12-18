# ✅ Voice Assistant with Gemini API - Setup Guide

## 🎯 Quick Setup

### 1. Get your Gemini API Key
1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Click "Create API Key"
3. Copy your API key

### 2. Configure the API Key

**Option 1: For Testing (Quick)**
Edit `lib/config/voice_api_config.dart` line 12:
```dart
defaultValue: 'your-actual-gemini-api-key-here',
```

**Option 2: For Production (Recommended)**
1. Copy `.env.example` to `.env`
2. Open `.env` and replace `your-gemini-api-key-here` with your actual key
3. Run: `flutter run --dart-define-from-file=.env`

### 3. Navigate to Voice Screen

The voice assistant is accessible via the "Lumo Voice Bot" screen in your app.

## 🎤 How to Use

1. **Tap the microphone button** to start listening
2. **Speak your question** 
3. **Wait for Lumo's response** (both text and speech)
4. The conversation continues automatically

## ✨ Features

- 🎤 Speech-to-text recognition
- 💬 Gemini AI responses
- 🔊 Text-to-speech output
- 📱 Beautiful Lumo-branded interface
- 🔄 Continuous conversation mode

## 🔧 Troubleshooting

### "Failed to connect" Error
- Check your API key is correct
- Verify internet connection
- Ensure you have billing enabled on your Google Cloud account

### Speech Recognition Issues
- Grant microphone permission
- Speak clearly and loudly
- Check device microphone is working

### TTS Not Working
- Check device volume
- Ensure TTS engine is available
- Try restarting the app

## 📋 What Changed from OpenAI

- ✅ Replaced OpenAI Realtime API with Gemini API
- ✅ Added speech_to_text package for voice input
- ✅ Added flutter_tts for voice output
- ✅ Simplified architecture (no WebSocket needed)
- ✅ Better error handling and connection management
- ✅ Same beautiful UI with Lumo branding

## 🎨 Customization

### Change Voice Speed/Pitch
Edit `lib/config/voice_api_config.dart`:
```dart
static const double ttsSpeechRate = 0.5; // 0.1 to 1.0
static const double ttsPitch = 1.0; // 0.5 to 2.0
```

### Modify AI Personality
Edit the `systemInstruction` in `lib/config/voice_api_config.dart`

### Adjust Colors/Animations
Edit `lib/presentation/screens/lumo_voice_bot_screen.dart`

---

## 🎉 Ready to Chat with Lumo!

The voice assistant now works with your Gemini API key. Just set up the API key and start talking to Lumo!