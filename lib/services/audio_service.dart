import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Enum for different audio types
enum AudioType {
  sound,
  song,
  notification,
  background,
}

/// Enum for player state
enum AudioPlayerState {
  stopped,
  playing,
  paused,
  loading,
  error,
}

/// Audio track model
class AudioTrack {
  final String id;
  final String name;
  final String path;
  final AudioType type;
  final Duration? duration;
  final Map<String, dynamic>? metadata;

  const AudioTrack({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    this.duration,
    this.metadata,
  });

  AudioTrack copyWith({
    String? id,
    String? name,
    String? path,
    AudioType? type,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Audio service for managing sound and song playback
class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Audio players for different purposes
  final AudioPlayer _soundPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _backgroundPlayer = AudioPlayer();

  // Current state tracking
  AudioPlayerState _soundState = AudioPlayerState.stopped;
  AudioPlayerState _musicState = AudioPlayerState.stopped;
  AudioPlayerState _backgroundState = AudioPlayerState.stopped;

  AudioTrack? _currentSoundTrack;
  AudioTrack? _currentMusicTrack;
  AudioTrack? _currentBackgroundTrack;

  // Audio settings
  double _soundVolume = 1.0;
  double _musicVolume = 0.7;
  double _backgroundVolume = 0.3;
  double _playbackSpeed = 1.0;
  bool _isMuted = false;

  // Position tracking
  Duration _soundPosition = Duration.zero;
  Duration _musicPosition = Duration.zero;
  Duration _backgroundPosition = Duration.zero;

  Duration? _soundDuration;
  Duration? _musicDuration;
  Duration? _backgroundDuration;

  // Stream subscriptions
  late StreamSubscription _soundPositionSubscription;
  late StreamSubscription _musicPositionSubscription;
  late StreamSubscription _backgroundPositionSubscription;

  late StreamSubscription _soundDurationSubscription;
  late StreamSubscription _musicDurationSubscription;
  late StreamSubscription _backgroundDurationSubscription;

  late StreamSubscription _soundStateSubscription;
  late StreamSubscription _musicStateSubscription;
  late StreamSubscription _backgroundStateSubscription;

  // Getters
  AudioPlayerState get soundState => _soundState;
  AudioPlayerState get musicState => _musicState;
  AudioPlayerState get backgroundState => _backgroundState;

  AudioTrack? get currentSoundTrack => _currentSoundTrack;
  AudioTrack? get currentMusicTrack => _currentMusicTrack;
  AudioTrack? get currentBackgroundTrack => _currentBackgroundTrack;

  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;
  double get backgroundVolume => _backgroundVolume;
  double get playbackSpeed => _playbackSpeed;
  bool get isMuted => _isMuted;

  Duration get soundPosition => _soundPosition;
  Duration get musicPosition => _musicPosition;
  Duration get backgroundPosition => _backgroundPosition;

  Duration? get soundDuration => _soundDuration;
  Duration? get musicDuration => _musicDuration;
  Duration? get backgroundDuration => _backgroundDuration;

  /// Initialize the audio service
  Future<void> initialize() async {
    try {
      // Set audio context for better performance
      await _soundPlayer.setReleaseMode(ReleaseMode.stop);
      await _musicPlayer.setReleaseMode(ReleaseMode.stop);
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);

      // Set initial volumes
      await _soundPlayer.setVolume(_soundVolume);
      await _musicPlayer.setVolume(_musicVolume);
      await _backgroundPlayer.setVolume(_backgroundVolume);

      // Set initial playback speed
      await _soundPlayer.setPlaybackRate(_playbackSpeed);
      await _musicPlayer.setPlaybackRate(_playbackSpeed);
      await _backgroundPlayer.setPlaybackRate(_playbackSpeed);

      _setupEventListeners();
      
      if (kDebugMode) {
        print('🎵 Audio Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize audio service: $e');
      }
    }
  }

  /// Setup event listeners for audio players
  void _setupEventListeners() {
    // Sound player listeners
    _soundPositionSubscription = _soundPlayer.onPositionChanged.listen((position) {
      _soundPosition = position;
      notifyListeners();
    });

    _soundDurationSubscription = _soundPlayer.onDurationChanged.listen((duration) {
      _soundDuration = duration;
      notifyListeners();
    });

    _soundStateSubscription = _soundPlayer.onPlayerStateChanged.listen((state) {
      _soundState = _mapPlayerState(state);
      notifyListeners();
    });

    // Music player listeners
    _musicPositionSubscription = _musicPlayer.onPositionChanged.listen((position) {
      _musicPosition = position;
      notifyListeners();
    });

    _musicDurationSubscription = _musicPlayer.onDurationChanged.listen((duration) {
      _musicDuration = duration;
      notifyListeners();
    });

    _musicStateSubscription = _musicPlayer.onPlayerStateChanged.listen((state) {
      _musicState = _mapPlayerState(state);
      notifyListeners();
    });

    // Background player listeners
    _backgroundPositionSubscription = _backgroundPlayer.onPositionChanged.listen((position) {
      _backgroundPosition = position;
      notifyListeners();
    });

    _backgroundDurationSubscription = _backgroundPlayer.onDurationChanged.listen((duration) {
      _backgroundDuration = duration;
      notifyListeners();
    });

    _backgroundStateSubscription = _backgroundPlayer.onPlayerStateChanged.listen((state) {
      _backgroundState = _mapPlayerState(state);
      notifyListeners();
    });
  }

  /// Map AudioPlayers PlayerState to our AudioPlayerState
  AudioPlayerState _mapPlayerState(PlayerState state) {
    switch (state) {
      case PlayerState.stopped:
        return AudioPlayerState.stopped;
      case PlayerState.playing:
        return AudioPlayerState.playing;
      case PlayerState.paused:
        return AudioPlayerState.paused;
      case PlayerState.completed:
        return AudioPlayerState.stopped;
      case PlayerState.disposed:
        return AudioPlayerState.stopped;
    }
  }

  /// Get appropriate player based on audio type
  AudioPlayer _getPlayerForType(AudioType type) {
    switch (type) {
      case AudioType.sound:
      case AudioType.notification:
        return _soundPlayer;
      case AudioType.song:
        return _musicPlayer;
      case AudioType.background:
        return _backgroundPlayer;
    }
  }

  /// Play audio from assets
  Future<bool> playAsset({
    required String assetPath,
    required AudioType type,
    String? trackId,
    String? trackName,
    bool loop = false,
    double? volume,
  }) async {
    try {
      final player = _getPlayerForType(type);
      final source = AssetSource(assetPath);

      // Set loop mode for background audio
      if (type == AudioType.background || loop) {
        await player.setReleaseMode(ReleaseMode.loop);
      } else {
        await player.setReleaseMode(ReleaseMode.stop);
      }

      // Set volume if provided
      if (volume != null) {
        await player.setVolume(volume);
      }

      await player.play(source);

      // Update current track
      final track = AudioTrack(
        id: trackId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: trackName ?? assetPath.split('/').last,
        path: assetPath,
        type: type,
      );

      _setCurrentTrack(type, track);

      if (kDebugMode) {
        print('🎵 Playing asset: $assetPath');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to play asset: $e');
      }
      return false;
    }
  }

  /// Play audio from file path
  Future<bool> playFile({
    required String filePath,
    required AudioType type,
    String? trackId,
    String? trackName,
    bool loop = false,
    double? volume,
  }) async {
    try {
      final player = _getPlayerForType(type);
      final source = DeviceFileSource(filePath);

      // Set loop mode for background audio
      if (type == AudioType.background || loop) {
        await player.setReleaseMode(ReleaseMode.loop);
      } else {
        await player.setReleaseMode(ReleaseMode.stop);
      }

      // Set volume if provided
      if (volume != null) {
        await player.setVolume(volume);
      }

      await player.play(source);

      // Update current track
      final track = AudioTrack(
        id: trackId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: trackName ?? filePath.split(Platform.pathSeparator).last,
        path: filePath,
        type: type,
      );

      _setCurrentTrack(type, track);

      if (kDebugMode) {
        print('🎵 Playing file: $filePath');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to play file: $e');
      }
      return false;
    }
  }

  /// Play audio from URL
  Future<bool> playUrl({
    required String url,
    required AudioType type,
    String? trackId,
    String? trackName,
    bool loop = false,
    double? volume,
  }) async {
    try {
      final player = _getPlayerForType(type);
      final source = UrlSource(url);

      // Set loop mode for background audio
      if (type == AudioType.background || loop) {
        await player.setReleaseMode(ReleaseMode.loop);
      } else {
        await player.setReleaseMode(ReleaseMode.stop);
      }

      // Set volume if provided
      if (volume != null) {
        await player.setVolume(volume);
      }

      await player.play(source);

      // Update current track
      final track = AudioTrack(
        id: trackId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: trackName ?? url.split('/').last,
        path: url,
        type: type,
      );

      _setCurrentTrack(type, track);

      if (kDebugMode) {
        print('🎵 Playing URL: $url');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to play URL: $e');
      }
      return false;
    }
  }

  /// Pause audio by type
  Future<void> pause(AudioType type) async {
    try {
      final player = _getPlayerForType(type);
      await player.pause();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to pause audio: $e');
      }
    }
  }

  /// Resume audio by type
  Future<void> resume(AudioType type) async {
    try {
      final player = _getPlayerForType(type);
      await player.resume();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to resume audio: $e');
      }
    }
  }

  /// Stop audio by type
  Future<void> stop(AudioType type) async {
    try {
      final player = _getPlayerForType(type);
      await player.stop();
      _setCurrentTrack(type, null);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to stop audio: $e');
      }
    }
  }

  /// Stop all audio
  Future<void> stopAll() async {
    await Future.wait([
      stop(AudioType.sound),
      stop(AudioType.song),
      stop(AudioType.background),
    ]);
  }

  /// Seek to position
  Future<void> seek(AudioType type, Duration position) async {
    try {
      final player = _getPlayerForType(type);
      await player.seek(position);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to seek: $e');
      }
    }
  }

  /// Set volume for specific audio type
  Future<void> setVolume(AudioType type, double volume) async {
    try {
      volume = volume.clamp(0.0, 1.0);
      final player = _getPlayerForType(type);
      
      if (!_isMuted) {
        await player.setVolume(volume);
      }

      switch (type) {
        case AudioType.sound:
        case AudioType.notification:
          _soundVolume = volume;
          break;
        case AudioType.song:
          _musicVolume = volume;
          break;
        case AudioType.background:
          _backgroundVolume = volume;
          break;
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to set volume: $e');
      }
    }
  }

  /// Set master volume for all audio
  Future<void> setMasterVolume(double volume) async {
    volume = volume.clamp(0.0, 1.0);
    await Future.wait([
      setVolume(AudioType.sound, volume),
      setVolume(AudioType.song, volume),
      setVolume(AudioType.background, volume),
    ]);
  }

  /// Set playback speed (0.5x to 2.0x)
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      speed = speed.clamp(0.5, 2.0);
      _playbackSpeed = speed;

      await Future.wait([
        _soundPlayer.setPlaybackRate(speed),
        _musicPlayer.setPlaybackRate(speed),
        _backgroundPlayer.setPlaybackRate(speed),
      ]);

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to set playback speed: $e');
      }
    }
  }

  /// Toggle mute/unmute
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    
    if (_isMuted) {
      await Future.wait([
        _soundPlayer.setVolume(0),
        _musicPlayer.setVolume(0),
        _backgroundPlayer.setVolume(0),
      ]);
    } else {
      await Future.wait([
        _soundPlayer.setVolume(_soundVolume),
        _musicPlayer.setVolume(_musicVolume),
        _backgroundPlayer.setVolume(_backgroundVolume),
      ]);
    }

    notifyListeners();
  }

  /// Set current track for type
  void _setCurrentTrack(AudioType type, AudioTrack? track) {
    switch (type) {
      case AudioType.sound:
      case AudioType.notification:
        _currentSoundTrack = track;
        break;
      case AudioType.song:
        _currentMusicTrack = track;
        break;
      case AudioType.background:
        _currentBackgroundTrack = track;
        break;
    }
    notifyListeners();
  }

  /// Play notification sound
  Future<void> playNotificationSound([String? customPath]) async {
    final path = customPath ?? 'sounds/lumo-sound.wav';
    await playAsset(
      assetPath: path,
      type: AudioType.notification,
      trackName: 'Notification Sound',
    );
  }

  /// Play success sound
  Future<void> playSuccessSound() async {
    // You can add a success sound file to assets
    await playAsset(
      assetPath: 'sounds/lumo-sound.wav', // Replace with actual success sound
      type: AudioType.sound,
      trackName: 'Success Sound',
    );
  }

  /// Play error sound
  Future<void> playErrorSound() async {
    // You can add an error sound file to assets
    await playAsset(
      assetPath: 'sounds/lumo-sound.wav', // Replace with actual error sound
      type: AudioType.sound,
      trackName: 'Error Sound',
    );
  }

  /// Play focus session start sound
  Future<void> playFocusStartSound() async {
    await playAsset(
      assetPath: 'sounds/lumo-sound.wav',
      type: AudioType.sound,
      trackName: 'Focus Start',
    );
  }

  /// Play focus session end sound
  Future<void> playFocusEndSound() async {
    await playAsset(
      assetPath: 'sounds/lumo-sound.wav',
      type: AudioType.sound,
      trackName: 'Focus End',
    );
  }

  /// Get audio state by type
  AudioPlayerState getStateByType(AudioType type) {
    switch (type) {
      case AudioType.sound:
      case AudioType.notification:
        return _soundState;
      case AudioType.song:
        return _musicState;
      case AudioType.background:
        return _backgroundState;
    }
  }

  /// Check if any audio is playing
  bool get isAnyPlaying {
    return _soundState == AudioPlayerState.playing ||
           _musicState == AudioPlayerState.playing ||
           _backgroundState == AudioPlayerState.playing;
  }

  /// Check if specific type is playing
  bool isPlaying(AudioType type) {
    return getStateByType(type) == AudioPlayerState.playing;
  }

  /// Get progress percentage (0.0 to 1.0)
  double getProgress(AudioType type) {
    Duration? duration;
    Duration position;

    switch (type) {
      case AudioType.sound:
      case AudioType.notification:
        duration = _soundDuration;
        position = _soundPosition;
        break;
      case AudioType.song:
        duration = _musicDuration;
        position = _musicPosition;
        break;
      case AudioType.background:
        duration = _backgroundDuration;
        position = _backgroundPosition;
        break;
    }

    if (duration == null || duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Format duration to string (MM:SS)
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// Dispose audio service
  @override
  void dispose() {
    _soundPositionSubscription.cancel();
    _musicPositionSubscription.cancel();
    _backgroundPositionSubscription.cancel();
    
    _soundDurationSubscription.cancel();
    _musicDurationSubscription.cancel();
    _backgroundDurationSubscription.cancel();
    
    _soundStateSubscription.cancel();
    _musicStateSubscription.cancel();
    _backgroundStateSubscription.cancel();

    _soundPlayer.dispose();
    _musicPlayer.dispose();
    _backgroundPlayer.dispose();

    super.dispose();
  }
}
