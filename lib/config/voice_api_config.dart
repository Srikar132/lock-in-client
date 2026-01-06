class VoiceApiConfig {
  // OpenAI Realtime API (WebSocket)
  static const String realtimeWsUrl = 'wss://api.openai.com/v1/realtime';
  static const String model = 'gpt-4o-realtime-preview-2024-12-17';

  // OpenAI REST API (fallback)
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String chatCompletionsUrl = '$openaiBaseUrl/chat/completions';
  static const String whisperUrl = '$openaiBaseUrl/audio/transcriptions';
  static const String ttsUrl = '$openaiBaseUrl/audio/speech';

  // Your API key - load from environment variables
  // Run with: flutter run --dart-define=OPENAI_API_KEY=your-key-here
  // static const String apiKey = String.fromEnvironment(
  //   'OPENAI_API_KEY',
  //   defaultValue: '',
  // );
  static const String apiKey ='';

  // Audio Configuration - 24kHz mono 16-bit PCM for Realtime API
  static const int sampleRate = 24000; // 24kHz for Realtime API
  static const int channels = 1;
  static const int bitsPerSample = 16;
  static const int chunkDurationMs = 100; // 100ms chunks

  // TTS Configuration
  // Available voices: alloy, ash, ballad, coral, echo, sage, shimmer, verse
  static const String ttsVoice =
      'shimmer'; // shimmer is clearer and more natural
  static const String ttsModel = 'tts-1-hd'; // HD model for better quality

  // VAD (Voice Activity Detection) thresholds
  static const double silenceThreshold = 0.02;
  static const int silenceDurationMs =
      700; // Slightly longer for better sentence detection
}
