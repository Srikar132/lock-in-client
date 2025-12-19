import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../config/voice_api_config.dart';

class GeminiVoiceService {
  final _transcriptController = StreamController<String>.broadcast();
  final _responseController = StreamController<String>.broadcast();
  final _stateController = StreamController<String>.broadcast();

  late FlutterTts _flutterTts;
  late SpeechToText _speechToText;

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  String _accumulatedResponse = '';
  String? _customSystemPrompt; // For challenge-specific prompts

  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<String> get responseStream => _responseController.stream;
  Stream<String> get stateStream => _stateController.stream;

  bool get isConnected => _isInitialized;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  Future<bool> connect() async {
    if (_isInitialized) return true;

    try {
      print('🔄 Initializing Gemini Voice Service...');

      // Initialize TTS
      _flutterTts = FlutterTts();
      await _setupTts();

      // Initialize Speech Recognition
      _speechToText = SpeechToText();
      final available = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (!available) {
        print('❌ Speech recognition not available');
        return false;
      }

      _isInitialized = true;
      _stateController.add('connected');
      print('✅ Gemini Voice Service initialized');
      return true;
    } catch (e) {
      print('❌ Failed to initialize Gemini Voice Service: $e');
      return false;
    }
  }

  Future<void> _setupTts() async {
    await _flutterTts.setLanguage(VoiceApiConfig.ttsLanguage);
    await _flutterTts.setSpeechRate(VoiceApiConfig.ttsSpeechRate);
    await _flutterTts.setVolume(VoiceApiConfig.ttsVolume);
    await _flutterTts.setPitch(VoiceApiConfig.ttsPitch);

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      _stateController.add('speaking_started');
      print('🔊 TTS started');
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _stateController.add('speaking_complete');
      print('✅ TTS completed');
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      print('❌ TTS error: $msg');
    });
  }

  void _onSpeechStatus(String status) {
    print('🎤 Speech status: $status');
    _stateController.add('speech_$status');
  }

  void _onSpeechError(dynamic error) {
    print('❌ Speech error: $error');
    _stateController.add('error');
  }

  Future<void> startListening() async {
    if (!_isInitialized || _isListening) return;

    try {
      print('🎤 Starting speech recognition...');
      _isListening = true;
      _stateController.add('speech_started');

      await _speechToText.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            _transcriptController.add(result.recognizedWords);
            print('📝 Transcript: ${result.recognizedWords}');

            // If the result is final, send to Gemini
            if (result.finalResult) {
              _sendToGemini(result.recognizedWords);
            }
          }
        },
        listenMode: ListenMode.confirmation,
        partialResults: true,
      );
    } catch (e) {
      print('❌ Error starting speech recognition: $e');
      _isListening = false;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    print('🔇 Stopping speech recognition...');
    await _speechToText.stop();
    _isListening = false;
    _stateController.add('speech_stopped');
  }

  Future<void> _sendToGemini(String text) async {
    if (VoiceApiConfig.apiKey.isEmpty) {
      print('❌ Please set GEMINI_API_KEY in environment variables.');
      _responseController.add(
        "Please set GEMINI_API_KEY in environment variables.",
      );
      return;
    }

    try {
      print('📤 Sending to Gemini: $text');
      _stateController.add('response_started');

      final url = Uri.parse(
        '${VoiceApiConfig.chatUrl}${VoiceApiConfig.apiKey}',
      );

      // Use custom prompt if set, otherwise use default
      final systemPrompt =
          _customSystemPrompt ?? VoiceApiConfig.systemInstruction;

      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': text},
            ],
          },
        ],
        'generationConfig': {
          'temperature': VoiceApiConfig.temperature,
          'maxOutputTokens': VoiceApiConfig.maxTokens,
        },
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
      });

      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List;

        if (candidates.isNotEmpty) {
          final content =
              candidates[0]['content']['parts'][0]['text'] as String;

          // Clean up the response text
          final cleanContent = content.trim();

          _accumulatedResponse = cleanContent;
          _responseController.add(cleanContent);

          print('✅ Gemini response: $cleanContent');

          // Speak the response
          await _speakResponse(cleanContent);
        }
      } else {
        print('❌ Gemini API error: ${response.statusCode} - ${response.body}');
        _responseController.add(
          "Sorry, I'm having trouble connecting. Let's focus on studying!",
        );
        _stateController.add('error');
      }
    } catch (e) {
      print('❌ Network error: $e');
      _responseController.add("Connection issue. Please check your internet.");
      _stateController.add('error');
    }
  }

  Future<void> _speakResponse(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    print('🔊 Speaking response...');
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
      _stateController.add('speaking_stopped');
      print('⏹️ Speech stopped');
    }
  }

  // Legacy methods to maintain compatibility with existing code
  void sendAudio(Uint8List audioChunk) {
    // For Gemini service, audio is handled by speech_to_text package
    // This method is kept for compatibility but doesn't do anything
    print('⚠️ sendAudio called - audio handled by speech_to_text package');
  }

  void commitAudio() {
    // For Gemini service, we don't need to commit audio
    // Speech recognition handles this automatically
    print('⚠️ commitAudio called - not needed for Gemini service');
  }

  void cancelResponse() {
    if (_isSpeaking) {
      stopSpeaking();
    }
    _accumulatedResponse = '';
    print('⏹️ Response cancelled');
  }

  Future<void> disconnect() async {
    await stopListening();
    await stopSpeaking();
    _isInitialized = false;
    _stateController.add('disconnected');
    print('🔌 Disconnected from Gemini Voice Service');
  }

  Future<void> dispose() async {
    await disconnect();
    await _transcriptController.close();
    await _responseController.close();
    await _stateController.close();
  }

  // ==================== CHALLENGE NARRATION ====================

  /// Update system prompt for Survival Mode
  void setSurvivalModeContext({
    required int survivorsLeft,
    required int totalParticipants,
    required Duration timeRemaining,
  }) {
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;

    _customSystemPrompt =
        '''
You are Lumo, narrating a high-stakes "Deep Work Survival Mode" challenge.
Currently, $survivorsLeft out of $totalParticipants participants are still active.
Time remaining: ${hours}h ${minutes}m.

Be dramatic and motivational like a sports commentator. Keep responses under 50 words.
Celebrate survivors, acknowledge knockouts professionally, and build tension as time runs out.
Examples: "Only $survivorsLeft warriors remain! The tension is incredible!" or "Stay focused - the finish line is in sight!"
''';

    print('🔥 Lumo: Survival Mode context updated - $survivorsLeft survivors');
  }

  /// Update system prompt for World Boss battle
  void setWorldBossContext({
    required String bossName,
    required double bossHPPercentage,
    required int userContribution,
    required int minimumContribution,
  }) {
    final hpPercent = (bossHPPercentage * 100).toInt();
    final contributionPercent = ((userContribution / minimumContribution) * 100)
        .toInt();

    _customSystemPrompt =
        '''
You are Lumo, serving as the battle commentator for a community-wide boss fight against "$bossName".
Current boss HP: $hpPercent%
User's contribution: $userContribution minutes ($contributionPercent% toward qualification)
Minimum needed: $minimumContribution minutes

Be energetic like a battle narrator. Keep responses under 50 words.
Encourage the user to deal more damage, celebrate milestones, and announce when boss phases change.
Examples: "The boss is at $hpPercent% HP! Your contribution is making a real difference!" or "Just ${minimumContribution - userContribution} more minutes to qualify for the legendary reward!"
''';

    print('⚔️ Lumo: World Boss context updated - $hpPercent% HP remaining');
  }

  /// Provide a battle update announcement
  Future<void> announceBattleUpdate(String message) async {
    if (!_isInitialized) return;

    _responseController.add(message);
    await _speakResponse(message);
    print('📢 Lumo: $message');
  }

  /// Announce survival mode knockout
  Future<void> announceKnockout(String userName) async {
    final message = "$userName has been knocked out! Stay strong, survivors!";
    await announceBattleUpdate(message);
  }

  /// Announce boss HP milestone
  Future<void> announceBossMilestone(int hpPercent) async {
    String message;
    if (hpPercent == 50) {
      message = "The boss is at half health! Keep pushing!";
    } else if (hpPercent == 25) {
      message = "Only 25% HP left! The boss is weakening!";
    } else if (hpPercent == 10) {
      message = "10% HP remaining! Give it everything you've got!";
    } else if (hpPercent <= 0) {
      message = "🎉 BOSS DEFEATED! Incredible work, community!";
    } else {
      message = "Boss HP: $hpPercent%";
    }
    await announceBattleUpdate(message);
  }

  /// Clear custom prompt and return to normal
  void clearChallengeContext() {
    _customSystemPrompt = null;
    print('🔄 Lumo: Returned to normal mode');
  }
}
