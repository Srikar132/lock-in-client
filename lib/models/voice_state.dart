enum VoiceSessionState {
  idle,
  listening,
  thinking,
  speaking,
  interrupted,
  error,
}

class VoiceMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isPartial;

  VoiceMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isPartial = false,
  });

  VoiceMessage copyWith({String? content, bool? isPartial}) {
    return VoiceMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      isPartial: isPartial ?? this.isPartial,
    );
  }
}

class VoiceSessionStateModel {
  final VoiceSessionState state;
  final List<VoiceMessage> messages;
  final String? partialTranscript;
  final String? partialResponse;
  final String? error;
  final double audioLevel;

  VoiceSessionStateModel({
    this.state = VoiceSessionState.idle,
    this.messages = const [],
    this.partialTranscript,
    this.partialResponse,
    this.error,
    this.audioLevel = 0.0,
  });

  VoiceSessionStateModel copyWith({
    VoiceSessionState? state,
    List<VoiceMessage>? messages,
    String? partialTranscript,
    String? partialResponse,
    String? error,
    double? audioLevel,
    bool clearPartialTranscript = false,
    bool clearPartialResponse = false,
    bool clearError = false,
  }) {
    return VoiceSessionStateModel(
      state: state ?? this.state,
      messages: messages ?? this.messages,
      partialTranscript: clearPartialTranscript
          ? null
          : (partialTranscript ?? this.partialTranscript),
      partialResponse: clearPartialResponse
          ? null
          : (partialResponse ?? this.partialResponse),
      error: clearError ? null : (error ?? this.error),
      audioLevel: audioLevel ?? this.audioLevel,
    );
  }
}
