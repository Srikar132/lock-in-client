# 🎤 Lumo Voice Assistant - Visual Architecture

## 🏗️ System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface                          │
│                   (LumoVoiceBotScreen)                          │
│                                                                 │
│  ┌─────────┐  ┌─────────────┐  ┌──────────┐  ┌─────────────┐ │
│  │ Message │  │   Audio      │  │  Control │  │   State     │ │
│  │ Bubbles │  │ Visualizer   │  │  Button  │  │  Indicator  │ │
│  └─────────┘  └─────────────┘  └──────────┘  └─────────────┘ │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    State Management Layer                        │
│                  (VoiceSessionProvider)                         │
│                       [Riverpod]                                │
│                                                                 │
│  States: IDLE → LISTENING → THINKING → SPEAKING → IDLE         │
└───┬─────────────────┬─────────────────┬─────────────────────┬───┘
    │                 │                 │                     │
    ▼                 ▼                 ▼                     ▼
┌─────────┐    ┌─────────────┐   ┌──────────────┐   ┌─────────────┐
│ Audio   │    │  Realtime   │   │    Audio     │   │   Player    │
│ Stream  │───▶│   Service   │──▶│   Response   │──▶│   Service   │
│ Service │    │ (WebSocket) │   │   Handler    │   │   Service   │
└─────────┘    └─────────────┘   └──────────────┘   └─────────────┘
    │                 │                 │                     │
    ▼                 ▼                 ▼                     ▼
┌─────────┐    ┌─────────────┐   ┌──────────────┐   ┌─────────────┐
│Mic Input│    │  OpenAI     │   │  Streaming   │   │  Speaker    │
│24kHz PCM│    │  Realtime   │   │  TTS Audio   │   │  Output     │
│         │    │    API      │   │   Chunks     │   │             │
└─────────┘    └─────────────┘   └──────────────┘   └─────────────┘
```

---

## 🔄 Data Flow Sequence

### 1. User Starts Speaking

```
User speaks
    ↓
Microphone captures PCM audio (24kHz, 16-bit)
    ↓
AudioStreamService processes chunks
    ↓
Chunks sent to RealtimeService
    ↓
WebSocket sends to OpenAI API
    ↓
VAD detects speech start
    ↓
UI updates to "LISTENING" state
    ↓
Audio visualizer animates
```

### 2. Speech Recognition

```
OpenAI processes audio stream
    ↓
Partial transcripts generated
    ↓
RealtimeService receives transcript events
    ↓
VoiceSessionProvider updates state
    ↓
User message added to conversation
    ↓
UI displays message bubble (right side)
```

### 3. AI Response Generation

```
OpenAI generates response
    ↓
Tokens stream in real-time
    ↓
RealtimeService accumulates response
    ↓
VoiceSessionProvider updates partial response
    ↓
UI displays streaming text (left side)
    ↓
TTS audio chunks generated simultaneously
    ↓
AudioPlayerService queues chunks
    ↓
Audio plays while more chunks arrive
```

### 4. Conversation Continues

```
Response completes
    ↓
Final message saved
    ↓
State returns to IDLE or LISTENING
    ↓
User can interrupt at any time
    ↓
Cycle repeats
```

---

## 🔀 State Machine Flow

```
                    ┌─────┐
                    │     │
                    │IDLE │
                    │     │
                    └──┬──┘
                       │
              Tap Mic Button
                       │
                       ▼
                  ┌─────────┐
       ┌──────────│         │
       │          │LISTENING│◀──────────┐
       │          │         │           │
       │          └────┬────┘           │
       │               │                │
       │       Speech Detected          │
       │               │                │
       │               ▼                │
       │          ┌─────────┐           │
       │          │         │           │
Stop   │          │THINKING │           │ Interrupt
       │          │         │           │
       │          └────┬────┘           │
       │               │                │
       │      Response Ready           │
       │               │                │
       │               ▼                │
       │          ┌─────────┐           │
       │          │         │───────────┘
       └─────────▶│SPEAKING │
                  │         │
                  └────┬────┘
                       │
               Response Complete
                       │
                       ▼
                  ┌─────────┐
                  │         │
                  │  IDLE   │
                  │         │
                  └─────────┘
```

---

## 📦 Component Hierarchy

```
LumoVoiceBotScreen
├── Header
│   ├── App Icon
│   ├── Title & State Text
│   └── Clear Button
│
├── Message List (ScrollView)
│   ├── Empty State (if no messages)
│   │   ├── Icon
│   │   ├── Welcome Text
│   │   └── Instruction Text
│   │
│   ├── User Messages (forEach)
│   │   └── Message Bubble (Right, Gradient)
│   │
│   ├── Assistant Messages (forEach)
│   │   └── Message Bubble (Left, Transparent)
│   │
│   └── Partial Response (if streaming)
│       └── Message Bubble with Loader
│
├── Audio Visualizer
│   └── 25 Animated Bars
│       └── Height based on audio level
│
└── Controls
    ├── Main Button (Animated)
    │   ├── Gradient Background
    │   ├── State-based Icon
    │   └── Pulse Animation
    │
    └── Hint Text
        └── State-based instruction
```

---

## 🔌 Service Connections

```
VoiceSessionProvider
│
├── AudioStreamService
│   ├── AudioRecorder (record package)
│   ├── audioStream (Uint8List stream)
│   └── audioLevelStream (double stream)
│
├── RealtimeService
│   ├── WebSocketChannel
│   ├── transcriptStream (String stream)
│   ├── responseStream (String stream)
│   ├── audioResponseStream (Uint8List stream)
│   └── stateStream (String stream)
│
└── AudioPlayerService
    ├── AudioPlayer (audioplayers package)
    ├── Queue (List<Uint8List>)
    └── playbackStream (bool stream)
```

---

## 🎯 Event Flow Matrix

| User Action | Service Triggered | State Change | UI Update |
|-------------|------------------|--------------|-----------|
| Tap Mic | AudioStreamService.startRecording() | IDLE → LISTENING | Button turns red, bars animate |
| Speak | RealtimeService.sendAudio() | LISTENING (maintains) | Bars respond to audio |
| Stop Speaking | RealtimeService.commitAudio() | LISTENING → THINKING | Button turns orange |
| Transcript Ready | VoiceSessionProvider adds message | THINKING (maintains) | Message bubble appears |
| Response Starts | AudioPlayerService.queueAudioChunk() | THINKING → SPEAKING | Button turns green |
| Tap During Speaking | AudioPlayerService.stop() | SPEAKING → INTERRUPTED | Stops playback, returns to listening |
| Response Complete | VoiceSessionProvider finalizes | SPEAKING → IDLE | Button returns to blue |

---

## 🧩 Key Integration Points

### 1. Permission Handling
```
App Launch
    ↓
VoiceSessionProvider.initialize()
    ↓
AudioStreamService.startRecording()
    ↓
Check Microphone Permission
    ↓
Request if needed (Android/iOS)
    ↓
Grant/Deny
    ↓
Update UI state accordingly
```

### 2. Error Recovery
```
Error Occurs
    ↓
Service catches exception
    ↓
Logs error with emoji prefix
    ↓
Updates state to ERROR
    ↓
UI shows error background & message
    ↓
User can retry
```

### 3. Barge-in Mechanism
```
User taps during SPEAKING
    ↓
AudioPlayerService.stop()
    ↓
RealtimeService.cancelResponse()
    ↓
State → INTERRUPTED
    ↓
Clear partial response
    ↓
AudioStreamService.startRecording()
    ↓
State → LISTENING
```

---

## 📊 Performance Optimization Points

### Audio Processing
- Chunk size: 100ms (configurable)
- Sample rate: 24kHz (optimal for API)
- Encoding: PCM 16-bit (no compression delay)

### Network
- WebSocket persistent connection
- Base64 encoding for binary data
- Minimal protocol overhead

### UI
- StreamBuilder for reactive updates
- AnimatedContainer for smooth transitions
- Conditional rendering based on state

### Memory
- Audio chunk queue management
- Temporary file cleanup
- Stream subscription disposal

---

## 🔐 Security Layers

```
Flutter App
    │
    ├── API Key (Environment Variable)
    │   └── Never in source code
    │
    ├── WebSocket Connection (WSS)
    │   └── TLS encryption
    │
    ├── Audio Data
    │   ├── Temporary files only
    │   └── Deleted after playback
    │
    └── User Permissions
        ├── Microphone (runtime)
        └── Storage (runtime)

Production:
    Backend Proxy
        │
        ├── User Authentication
        ├── Rate Limiting
        ├── API Key Storage
        └── Usage Monitoring
```

---

## 🎨 UI State Visualization

```
IDLE State
┌─────────────────┐
│ Lumo Assistant  │
│ Ready to listen │
├─────────────────┤
│                 │
│   (No messages) │
│                 │
├─────────────────┤
│ ▂▂▂▂▂▂▂▂▂▂▂▂   │ (Flat bars)
├─────────────────┤
│     [🎤]        │ (Blue button)
│ Tap to start    │
└─────────────────┘

LISTENING State
┌─────────────────┐
│ Lumo Assistant  │
│ Listening...    │
├─────────────────┤
│ "How can I..."  │ (User message appears)
├─────────────────┤
│ ▂█▃▇▂█▃▇▂█▃▇   │ (Active bars)
├─────────────────┤
│     [⏸]        │ (Red button)
│ Tap to stop     │
└─────────────────┘

SPEAKING State
┌─────────────────┐
│ Lumo Assistant  │
│ Speaking...     │
├─────────────────┤
│ User: "Help me" │
│ Lumo: "I can..."│ (Streaming)
├─────────────────┤
│ ▂▃▂▃▂▃▂▃▂▃▂▃   │ (Subtle animation)
├─────────────────┤
│     [⏹]        │ (Green button)
│ Tap to interrupt│
└─────────────────┘
```

---

This visual architecture guide helps understand how all components work together to create a seamless voice assistant experience!
