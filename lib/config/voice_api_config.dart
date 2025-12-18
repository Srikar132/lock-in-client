class VoiceApiConfig {
  // Updated Gemini 1.5 Pro API (correct endpoints for 2025)
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String chatUrl =
      '$geminiBaseUrl/models/gemini-1.5-flash-latest:generateContent?key=';
  static const String model = 'gemini-1.5-flash-latest'; // Free tier, fast

  // Note: Gemini doesn't have realtime WebSocket API, so we'll use REST API with TTS/STT
  // For speech-to-text, we'll use Web Speech API (browser) or speech_to_text package
  // For text-to-speech, we'll use flutter_tts package

  // Get FREE API key from https://aistudio.google.com/app/apikey
  static const String apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Remove hardcoded key
  );

  // Audio Configuration - Standard audio settings
  static const int sampleRate = 16000; // 16kHz for speech recognition
  static const int channels = 1;
  static const int bitsPerSample = 16;
  static const int chunkDurationMs = 100; // 100ms chunks

  // TTS Configuration (using flutter_tts)
  static const String ttsLanguage = 'en-US';
  static const double ttsSpeechRate = 0.5; // Speech rate (0.1 to 1.0)
  static const double ttsVolume = 0.8; // Volume (0.0 to 1.0)
  static const double ttsPitch = 1.0; // Pitch (0.5 to 2.0)

  // VAD (Voice Activity Detection) thresholds
  static const double silenceThreshold = 0.02;
  static const int silenceDurationMs =
      700; // Slightly longer for better sentence detection

  // Gemini-specific settings
  static const double temperature = 0.7; // Response creativity (0.0 to 1.0)
  static const int maxTokens = 1000; // Max response length

  // System instruction for Lumo
  static const String systemInstruction = '''
You are Lumo, a helpful AI voice assistant integrated into a focus and study app called LOCK-IN. 
Be concise, encouraging, and supportive. Help users with their study goals and productivity. 
Keep responses brief and clear, under 100 words. Use a friendly, motivational tone.
''';
}
