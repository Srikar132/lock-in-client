import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/voice_state.dart';
import '../../services/gemini_voice_service.dart';

final voiceSessionProvider =
    NotifierProvider<VoiceSessionNotifier, VoiceSessionStateModel>(() {
      return VoiceSessionNotifier();
    });

class VoiceSessionNotifier extends Notifier<VoiceSessionStateModel> {
  bool _mounted = true;

  @override
  VoiceSessionStateModel build() {
    _mounted = true;
    return VoiceSessionStateModel();
  }

  final _geminiService = GeminiVoiceService();
  final _uuid = const Uuid();

  bool _continuousMode = true; // Auto-restart listening after response

  // Safe state update
  void _updateState(
    VoiceSessionStateModel Function(VoiceSessionStateModel) update,
  ) {
    if (_mounted) {
      try {
        state = update(state);
      } catch (e) {
        print('⚠️ State update error: $e');
      }
    }
  }

  StreamSubscription? _transcriptSubscription;
  StreamSubscription? _responseSubscription;
  StreamSubscription? _stateSubscription;

  Future<bool> initialize() async {
    try {
      print('🚀 Initializing voice session...');

      final connected = await _geminiService.connect();
      print('🔌 Connection result: $connected');

      if (!connected) {
        _updateState(
          (s) => s.copyWith(
            state: VoiceSessionState.error,
            error: 'Failed to connect. Check internet connection and API key.',
          ),
        );
        return false;
      }

      // Transcript received
      _transcriptSubscription = _geminiService.transcriptStream.listen((
        transcript,
      ) {
        print('📝 Got transcript: $transcript');
        final message = VoiceMessage(
          id: _uuid.v4(),
          role: 'user',
          content: transcript,
          timestamp: DateTime.now(),
        );
        _updateState(
          (s) => s.copyWith(
            messages: [...s.messages, message],
            clearPartialTranscript: true,
          ),
        );
      });

      // Response text stream
      _responseSubscription = _geminiService.responseStream.listen((response) {
        print('💬 Got response text: $response');
        // Add response message immediately for Gemini (since we don't have streaming audio)
        final message = VoiceMessage(
          id: _uuid.v4(),
          role: 'assistant',
          content: response,
          timestamp: DateTime.now(),
        );
        _updateState(
          (s) => s.copyWith(
            messages: [...s.messages, message],
            partialResponse: response,
          ),
        );
      });

      // Service state changes
      _stateSubscription = _geminiService.stateStream.listen((apiState) {
        print('📡 API state changed: $apiState');
        switch (apiState) {
          case 'speech_started':
          case 'speech_listening':
            _updateState((s) => s.copyWith(state: VoiceSessionState.listening));
            break;
          case 'speech_stopped':
          case 'speech_notListening':
            _updateState((s) => s.copyWith(state: VoiceSessionState.thinking));
            break;
          case 'response_started':
          case 'speaking_started':
            _updateState((s) => s.copyWith(state: VoiceSessionState.speaking));
            break;
          case 'speaking_complete':
            // For Gemini service, auto-restart listening after TTS completes
            if (_continuousMode && _mounted) {
              _autoRestartListening();
            } else {
              _updateState((s) => s.copyWith(state: VoiceSessionState.idle));
            }
            break;
          case 'error':
            _updateState(
              (s) => s.copyWith(
                state: VoiceSessionState.error,
                error: 'API error occurred.',
              ),
            );
            break;
        }
      });

      return true;
    } catch (e) {
      print('❌ Init error: $e');
      _updateState(
        (s) => s.copyWith(
          state: VoiceSessionState.error,
          error: 'Failed to initialize: $e',
        ),
      );
      return false;
    }
  }

  /// TAP TO START - enables continuous listening mode
  Future<void> startListening() async {
    // Don't start if already active
    if (state.state == VoiceSessionState.listening ||
        state.state == VoiceSessionState.speaking ||
        state.state == VoiceSessionState.thinking) {
      return;
    }

    // Enable continuous mode
    _continuousMode = true;

    // Stop any current TTS
    await _geminiService.stopSpeaking();

    // Start listening with Gemini service
    await _geminiService.startListening();

    _updateState((s) => s.copyWith(state: VoiceSessionState.listening));
    print('🎤 Started continuous listening mode');
  }

  /// TAP TO STOP SPEAKING (sends audio for processing)
  Future<void> stopListening() async {
    if (state.state != VoiceSessionState.listening) return;

    await _geminiService.stopListening();

    _updateState((s) => s.copyWith(state: VoiceSessionState.thinking));
    print('⏹️ Stopped listening, processing...');
  }

  /// Pause listening (stop mic) but keep continuous mode enabled
  void _pauseListening() {
    _geminiService.stopListening();
    print('⏸️ Paused listening (bot is speaking)');
  }

  /// TAP TO INTERRUPT (stops playback, goes to idle)
  void interrupt() {
    print('🛑 Stopping voice session...');

    // Stop continuous mode
    _continuousMode = false;

    // Stop listening and speaking
    _geminiService.stopListening();
    _geminiService.stopSpeaking();

    // Go to idle
    _updateState(
      (s) =>
          s.copyWith(state: VoiceSessionState.idle, clearPartialResponse: true),
    );
  }

  /// Auto-restart listening after bot finishes speaking
  Future<void> _autoRestartListening() async {
    if (!_continuousMode || !_mounted) return;

    // Small delay before restarting
    await Future.delayed(const Duration(milliseconds: 300));

    if (!_continuousMode || !_mounted) return;

    // Start listening again
    await _geminiService.startListening();

    _updateState((s) => s.copyWith(state: VoiceSessionState.listening));
    print('🎤 Auto-restarted listening');
  }

  /// Stop continuous mode (when leaving screen)
  void stopAll() {
    _continuousMode = false;
    _geminiService.stopListening();
    _geminiService.stopSpeaking();
  }

  void clearMessages() {
    _updateState((s) => s.copyWith(messages: []));
  }

  void disposeResources() {
    _mounted = false;

    _transcriptSubscription?.cancel();
    _responseSubscription?.cancel();
    _stateSubscription?.cancel();

    _geminiService.dispose();
  }
}
