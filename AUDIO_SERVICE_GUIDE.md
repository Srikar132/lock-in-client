# Audio Service Documentation

The Audio Service provides comprehensive audio playback capabilities for the Lock-In app, including sounds, music, and background audio with speed and volume controls.

## Features

- **Multiple Audio Types**: Support for sounds, music, background audio, and notifications
- **Playback Speed Control**: Adjust speed from 0.5x to 2.0x
- **Individual Volume Controls**: Separate volume settings for different audio types
- **Multiple Audio Sources**: Play from assets, files, or URLs
- **Real-time Progress Tracking**: Monitor playback position and duration
- **State Management**: Integration with Riverpod for reactive UI updates
- **Focus Session Integration**: Built-in sounds for focus sessions

## Quick Start

### 1. Initialize the Service

Add to your app initialization:

```dart
// In main.dart or app startup
final audioService = ref.read(audioServiceProvider);
await audioService.initialize();
```

### 2. Basic Usage

```dart
// Play notification sound
AudioServiceMethods.playNotification(ref);

// Play success sound
AudioServiceMethods.playSuccess(ref);

// Play custom asset
AudioServiceMethods.playAsset(
  ref,
  assetPath: 'sounds/my-sound.wav',
  type: AudioType.sound,
  trackName: 'Custom Sound',
);

// Play from URL
AudioServiceMethods.playUrl(
  ref,
  url: 'https://example.com/song.mp3',
  type: AudioType.song,
  trackName: 'Online Music',
);
```

### 3. Control Playback

```dart
// Pause/Resume/Stop
AudioServiceMethods.pause(ref, AudioType.song);
AudioServiceMethods.resume(ref, AudioType.song);
AudioServiceMethods.stop(ref, AudioType.song);

// Volume control
AudioServiceMethods.setVolume(ref, AudioType.song, 0.8);

// Speed control
AudioServiceMethods.setPlaybackSpeed(ref, 1.5); // 1.5x speed

// Mute/Unmute
AudioServiceMethods.toggleMute(ref);
```

## Audio Types

### AudioType.sound
- UI feedback sounds
- Notification sounds
- Short sound effects

### AudioType.song
- Music tracks
- Long-form audio content
- Podcast episodes

### AudioType.background
- Ambient sounds
- Background music
- Looping audio

### AudioType.notification
- System notifications
- Alert sounds
- App notifications

## Built-in Sounds

### Focus Session Integration

```dart
// Start focus session
AudioIntegrationExample.onFocusSessionStart(ref);

// End focus session
AudioIntegrationExample.onFocusSessionEnd(ref);

// App blocked notification
AudioIntegrationExample.onAppBlocked(ref);

// Goal achieved
AudioIntegrationExample.onGoalAchieved(ref);
```

### System Feedback

```dart
// Success feedback
AudioServiceMethods.playSuccess(ref);

// Error feedback
AudioServiceMethods.playError(ref);

// Generic notification
AudioServiceMethods.playNotification(ref);
```

## Advanced Usage

### Custom Audio Tracks

```dart
final track = AudioTrack(
  id: 'unique-id',
  name: 'My Custom Track',
  path: 'sounds/custom.wav',
  type: AudioType.song,
  metadata: {'artist': 'Artist Name', 'album': 'Album Name'},
);

// Play with custom settings
AudioServiceMethods.playAsset(
  ref,
  assetPath: track.path,
  type: track.type,
  trackId: track.id,
  trackName: track.name,
  loop: true,
  volume: 0.6,
);
```

### Real-time Progress Monitoring

```dart
class AudioProgressWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioServiceProvider);
    
    return AnimatedBuilder(
      animation: audioService,
      builder: (context, _) {
        final progress = audioService.getProgress(AudioType.song);
        final position = audioService.musicPosition;
        final duration = audioService.musicDuration;
        
        return Column(
          children: [
            LinearProgressIndicator(value: progress),
            Text(
              '${AudioService.formatDuration(position)} / '
              '${AudioService.formatDuration(duration ?? Duration.zero)}',
            ),
          ],
        );
      },
    );
  }
}
```

### Seeking

```dart
// Seek to 30 seconds
AudioServiceMethods.seek(
  ref, 
  AudioType.song, 
  Duration(seconds: 30),
);

// Seek to 50% of track
final duration = ref.read(audioServiceProvider).musicDuration;
if (duration != null) {
  AudioServiceMethods.seek(
    ref,
    AudioType.song,
    Duration(milliseconds: (duration.inMilliseconds * 0.5).round()),
  );
}
```

## Audio States

Monitor audio playback state:

```dart
enum AudioPlayerState {
  stopped,   // Audio is stopped
  playing,   // Audio is currently playing
  paused,    // Audio is paused
  loading,   // Audio is loading
  error,     // Error occurred
}

// Check state
final audioService = ref.watch(audioServiceProvider);
if (audioService.isPlaying(AudioType.song)) {
  // Music is playing
}

// Get specific state
final state = audioService.getStateByType(AudioType.song);
```

## Error Handling

```dart
// Check if playback was successful
final success = await AudioServiceMethods.playAsset(
  ref,
  assetPath: 'sounds/test.wav',
  type: AudioType.sound,
);

if (!success) {
  // Handle playback error
  AudioServiceMethods.playError(ref);
}
```

## Performance Tips

1. **Initialize Early**: Initialize the audio service during app startup
2. **Preload Assets**: Assets are automatically cached by Flutter
3. **Dispose Properly**: The service handles disposal automatically
4. **Monitor Memory**: Use background audio sparingly for long sessions
5. **Network Audio**: Handle network connectivity for URL-based audio

## Integration with Focus Sessions

```dart
class FocusSessionAudio {
  static void setupFocusSession(WidgetRef ref) {
    // Start with focus sound
    AudioServiceMethods.playFocusStart(ref);
    
    // Set up background music
    AudioServiceMethods.playAsset(
      ref,
      assetPath: 'sounds/focus-background.wav',
      type: AudioType.background,
      loop: true,
      volume: 0.2,
    );
    
    // Adjust speeds for focus
    AudioServiceMethods.setPlaybackSpeed(ref, 1.0);
  }
  
  static void endFocusSession(WidgetRef ref) {
    // Stop background music
    AudioServiceMethods.stop(ref, AudioType.background);
    
    // Play completion sound
    AudioServiceMethods.playFocusEnd(ref);
  }
}
```

## Troubleshooting

### Common Issues

1. **No Sound on Device**:
   - Check device volume
   - Verify audio files exist in assets
   - Check permissions (Android)

2. **Playback Speed Not Working**:
   - Ensure speed is between 0.5x and 2.0x
   - Some audio formats may not support speed changes

3. **Memory Issues**:
   - Avoid playing too many simultaneous audio streams
   - Use background audio type for long-running audio

4. **Network Audio Issues**:
   - Check internet connectivity
   - Verify URL accessibility
   - Handle network timeouts

### Debugging

Enable debug output in development:

```dart
// Audio service automatically logs in debug mode
// Check console for audio-related messages
```

## Example Implementation

See `audio_example_page.dart` for a complete working example with:
- Audio control widgets
- Real-time progress display
- Volume and speed controls
- Multiple audio type management

## File Structure

```
lib/
├── services/
│   ├── audio_service.dart          # Main service implementation
│   └── audio_providers.dart        # Riverpod providers
├── widgets/
│   └── audio_control_widget.dart   # UI controls
└── presentation/pages/
    └── audio_example_page.dart     # Usage examples
```
