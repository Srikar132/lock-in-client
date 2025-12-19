# Background Image Provider Documentation

A comprehensive Flutter provider system for managing dynamic background images using Riverpod and Firebase Firestore.

## Features

✅ **Firebase Integration** - Saves background preferences to Firestore with offline support  
✅ **Real-time Sync** - Background changes sync across devices instantly  
✅ **Offline Support** - Works offline and syncs when connection returns  
✅ **Theme Images** - Uses predefined images from assets/images folder  
✅ **Riverpod 3.0** - Modern state management with automatic cleanup  
✅ **Error Handling** - Comprehensive error states and loading indicators  
✅ **Caching** - Firebase handles local caching automatically  

## Quick Start

### 1. Import the Provider

```dart
import 'package:lock_in/presentation/providers/background_image_provider.dart';
import 'package:lock_in/widgets/background_image_selector.dart';
```

### 2. Use Background Container

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: BackgroundImageContainer(
        child: YourContent(),
      ),
    );
  }
}
```

### 3. Change Background

```dart
// Change to specific background
ref.read(backgroundImageProvider.notifier)
    .changeBackgroundImage('assets/images/home-bg1.png');

// Cycle through backgrounds
ref.read(backgroundImageProvider.notifier).nextBackground();
ref.read(backgroundImageProvider.notifier).previousBackground();

// Reset to default
ref.read(backgroundImageProvider.notifier).resetToDefault();
```

## Available Backgrounds

The provider includes these pre-configured background images:

1. **Ocean Waves** (`home-bg1.png`) - Default
2. **Galaxy Stars** (`entry_bg.jpg`)
3. **Mountain Peaks** (`image.png`)
4. **Cherry Blossoms** (`song-image1.png`)
5. **Sunset Valley** (`song-image2.png`)

## Provider Functions

### Core Functions

```dart
// Change background image
await ref.read(backgroundImageProvider.notifier)
    .changeBackgroundImage('assets/images/entry_bg.jpg');

// Get next/previous backgrounds
String next = ref.read(backgroundImageProvider.notifier).getNextBackgroundImage();
String previous = ref.read(backgroundImageProvider.notifier).getPreviousBackgroundImage();

// Navigation functions
await ref.read(backgroundImageProvider.notifier).nextBackground();
await ref.read(backgroundImageProvider.notifier).previousBackground();
await ref.read(backgroundImageProvider.notifier).resetToDefault();
```

### State Watching

```dart
// Watch current background
final currentBg = ref.watch(currentBackgroundImageProvider);

// Watch loading state
final isLoading = ref.watch(isBackgroundImageLoadingProvider);

// Watch errors
final error = ref.watch(backgroundImageErrorProvider);

// Watch background name
final bgName = ref.watch(currentBackgroundNameProvider);

// Watch all available backgrounds
final backgrounds = ref.watch(availableBackgroundsProvider);
```

## Widgets

### BackgroundImageContainer
Applies the current background to any widget:

```dart
BackgroundImageContainer(
  fit: BoxFit.cover, // Optional
  child: YourWidget(),
)
```

### BackgroundImageSelector
Complete UI for selecting backgrounds:

```dart
BackgroundImageSelector() // Shows grid of all backgrounds
```

### CurrentBackgroundImage
Just displays the current background image:

```dart
CurrentBackgroundImage() // Simple image widget
```

## Firebase Structure

The provider saves data to Firestore in this format:

```json
// Collection: userSettings
// Document: {userId}
{
  "backgroundImage": "assets/images/home-bg1.png",
  "lastUpdated": "2024-12-19T10:30:00Z"
}
```

## Error Handling

The provider handles these scenarios:

- **User not authenticated**: Shows error message
- **Invalid image path**: Validates against available backgrounds
- **Network errors**: Firebase handles offline persistence
- **Image load errors**: Fallback UI with error icon

## Advanced Usage

### Custom Background Validation

```dart
// Add custom backgrounds to BackgroundImageConstants
class BackgroundImageConstants {
  static const List<String> availableBackgrounds = [
    'assets/images/home-bg1.png',
    'assets/images/your-custom-bg.png', // Add here
  ];
  
  static const List<String> backgroundNames = [
    'Ocean Waves',
    'Your Custom Theme', // Add name here
  ];
}
```

### Listen to Background Changes

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(backgroundImageProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.error}')),
        );
      }
    });
    
    return YourWidget();
  }
}
```

### Stream-based Updates

```dart
// For real-time updates across devices
final backgroundStream = ref.watch(backgroundImageStreamProvider(userId));
backgroundStream.when(
  data: (background) => Text('Current: $background'),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

## Best Practices

1. **Always use BackgroundImageContainer** for consistent theming
2. **Handle loading states** for better UX
3. **Show error messages** to users when background changes fail
4. **Use provider listeners** for navigation or side effects
5. **Validate custom backgrounds** before adding to constants

## Integration with Settings

Add to your settings screen:

```dart
ListTile(
  title: Text('Background Theme'),
  subtitle: Text(ref.watch(currentBackgroundNameProvider)),
  trailing: Icon(Icons.wallpaper),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => BackgroundSettingsScreen()),
  ),
)
```

## Troubleshooting

**Background not changing?**
- Check if user is authenticated
- Verify image path exists in assets
- Check Firebase connection

**Images not loading?**
- Ensure images are added to pubspec.yaml assets
- Check image paths in BackgroundImageConstants
- Verify file extensions match exactly

**State not syncing?**
- Check Firebase rules allow read/write to userSettings
- Verify user authentication status
- Check network connectivity
