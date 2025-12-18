class VoiceApiConfig {
  // OpenAI Realtime API (WebSocket)
  static const String realtimeWsUrl = 'wss://api.openai.com/v1/realtime';
  static const String model = 'gpt-4o-realtime-preview-2024-12-17';
  
  // OpenAI REST API (fallback)
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String chatCompletionsUrl = '$openaiBaseUrl/chat/completions';
  static const String whisperUrl = '$openaiBaseUrl/audio/transcriptions';
  static const String ttsUrl = '$openaiBaseUrl/audio/speech';
  
  // Your API key (NEVER commit this - use env variables in production)
  static const String apiKey = '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';
  
  // Audio Configuration - 24kHz mono 16-bit PCM for Realtime API
  static const int sampleRate = 24000; // 24kHz for Realtime API
  static const int channels = 1;
  static const int bitsPerSample = 16;
  static const int chunkDurationMs = 100; // 100ms chunks
  
  // TTS Configuration
  // Available voices: alloy, ash, ballad, coral, echo, sage, shimmer, verse
  static const String ttsVoice = 'shimmer'; // shimmer is clearer and more natural
  static const String ttsModel = 'tts-1-hd'; // HD model for better quality
  
  // VAD (Voice Activity Detection) thresholds
  static const double silenceThreshold = 0.02;
  static const int silenceDurationMs = 700; // Slightly longer for better sentence detection
}
