

class Audio {
  final String songAssetUrl;
  final String image;
  final String name;

  const Audio({
    required this.songAssetUrl,
    required this.image,
    required this.name,
  });
}

class AudioConstants {
  // List of audio objects
  static const List<Audio> audioList = [
    Audio(
      songAssetUrl: 'sounds/song1.mp3',
      image: 'assets/images/song-image1.png', // Using existing image as placeholder
      name: 'Song 1',
    ),
    Audio(
      songAssetUrl: 'sounds/song2.mp3',
      image: 'assets/images/song-image2.png', // Using existing image as placeholder
      name: 'Song 2',
    ),
    Audio(
      songAssetUrl: 'sounds/song3.mp3',
      image: 'assets/images/song-image3.jpeg', // Using existing image as placeholder
      name: 'Song 3',
    ),
    Audio(
      songAssetUrl: 'sounds/song4.mp3',
      image: 'assets/images/song-image4.jpeg', // Using existing image as placeholder
      name: 'Song 4',
    ),
    Audio(
      songAssetUrl: 'sounds/song5.mp3',
      image: 'assets/images/song-image5.jpeg', // Using existing image as placeholder
      name: 'Song 5',
    ),
    Audio(
      songAssetUrl: 'sounds/song6.mp3',
      image: 'assets/images/song-image6.jpeg', // Using existing image as placeholder
      name: 'Song 6',
    ),

  ];

  // Helper methods to get specific types of audio
  static List<Audio> get musicFiles => audioList
      .where((audio) => audio.songAssetUrl.contains('.mp3'))
      .toList();

  static List<Audio> get soundEffects => audioList
      .where((audio) => audio.songAssetUrl.contains('.wav'))
      .toList();

  // Get audio by name
  static Audio? getAudioByName(String name) {
    try {
      return audioList.firstWhere((audio) => audio.name == name);
    } catch (e) {
      return null;
    }
  }

  // Get all audio URLs
  static List<String> get allAudioUrls => audioList
      .map((audio) => audio.songAssetUrl)
      .toList();
}