# Flutter Native Persistent Blocking Integration Guide

## Overview

The Lock-In app now has complete integration between Flutter (Firestore) and native Android persistent blocking. This allows users to manage always-on blocking from the Flutter UI that synchronizes with the native blocking system.

## Architecture

```
Flutter UI (Dart)
      ↕
blocked_content_provider.dart (Riverpod)
      ↕
NativeService (Method Channel)
      ↕
MainActivity.kt (Android)
      ↕
FocusModeManager.kt (Native Storage)
      ↕
AppMonitoringService.kt (Blocking Logic)
```

## Key Components

### 1. **NativeService** (Flutter → Android Bridge)

Located: `lib/services/native_service.dart`

New methods added:
```dart
// App Blocking
static Future<bool> setPersistentAppBlocking({required bool enabled, List<String>? blockedApps})
static Future<bool> isPersistentAppBlockingEnabled()
static Future<List<String>> getPersistentBlockedApps()

// Website Blocking  
static Future<bool> setPersistentWebsiteBlocking({required bool enabled, List<Map<String, dynamic>>? blockedWebsites})
static Future<bool> isPersistentWebsiteBlockingEnabled()
static Future<List<Map<String, dynamic>>> getPersistentBlockedWebsites()

// Short-Form Content Blocking
static Future<bool> setPersistentShortFormBlocking({required bool enabled, Map<String, dynamic>? shortFormBlocks})
static Future<bool> isPersistentShortFormBlockingEnabled()
static Future<Map<String, dynamic>> getPersistentShortFormBlocks()

// Notification Blocking
static Future<bool> setPersistentNotificationBlocking({required bool enabled, Map<String, dynamic>? notificationBlocks})
static Future<bool> isPersistentNotificationBlockingEnabled()
static Future<Map<String, dynamic>> getPersistentNotificationBlocks()
```

### 2. **BlockedContentNotifier** (State Management)

Located: `lib/presentation/providers/blocked_content_provider.dart`

New features:
- **Persistent blocking control** with native integration
- **Sync methods** between Firestore and native
- **Combined providers** showing both Firestore and native status

Key methods:
```dart
// Set persistent blocking (updates both native + Firestore)
Future<void> setPersistentAppBlocking({required String userId, required bool enabled, List<String>? blockedApps, bool syncToFirestore = true})

// Sync between platforms
Future<void> syncFirestoreToNative(String userId)
Future<void> syncNativeToFirestore(String userId)
```

### 3. **Native Providers** (Real-time Status)

```dart
// Check native blocking status
final nativePersistentAppBlockingProvider = FutureProvider<bool>
final nativePersistentBlockedAppsProvider = FutureProvider<List<String>>

// Combined status (Firestore + Native)
final isAppBlockingActiveProvider = Provider.family<bool, String>
final blockingSummaryProvider = Provider.family<Map<String, bool>, String>
```

## Usage Examples

### Basic App Blocking Control

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value!;
    final notifier = ref.watch(blockedContentNotifierProvider.notifier);
    
    return ElevatedButton(
      onPressed: () async {
        // Enable persistent Instagram blocking
        await notifier.setPersistentAppBlocking(
          userId: user.uid,
          enabled: true,
          blockedApps: ['com.instagram.android'],
        );
      },
      child: Text('Block Instagram Forever'),
    );
  }
}
```

### Check Blocking Status

```dart
class BlockingStatusWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value!;
    final summary = ref.watch(blockingSummaryProvider(user.uid));
    
    return Column(
      children: [
        Text('Apps: ${summary['apps'] ? 'Blocked' : 'Allowed'}'),
        Text('Websites: ${summary['websites'] ? 'Blocked' : 'Allowed'}'),
        Text('Short Form: ${summary['shortForm'] ? 'Blocked' : 'Allowed'}'),
      ],
    );
  }
}
```

### Sync Between Platforms

```dart
class SyncControls extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value!;
    final notifier = ref.watch(blockedContentNotifierProvider.notifier);
    
    return Row(
      children: [
        ElevatedButton(
          onPressed: () => notifier.syncFirestoreToNative(user.uid),
          child: Text('Sync Firestore → Native'),
        ),
        ElevatedButton(
          onPressed: () => notifier.syncNativeToFirestore(user.uid),
          child: Text('Sync Native → Firestore'),
        ),
      ],
    );
  }
}
```

## Data Flow

### Enable Persistent Blocking
1. **User action** in Flutter UI
2. **Flutter** calls `setPersistentAppBlocking()` 
3. **Native method channel** receives call
4. **FocusModeManager** stores settings in SharedPreferences
5. **AppMonitoringService** starts/updates blocking
6. **Firestore** synced (if enabled)
7. **UI refreshes** automatically via providers

### Check Status
1. **Provider watches** native status via `NativeService`
2. **Method channel** queries native settings
3. **FocusModeManager** returns stored preferences
4. **UI updates** reactively when status changes

## Benefits

### ✅ **Unified Control**
- Single Flutter UI controls both Firestore and native blocking
- Consistent experience across platforms

### ✅ **Real-time Sync**
- Changes instantly reflected in both systems
- Automatic cache invalidation refreshes UI

### ✅ **Flexible Integration**
- Can sync bidirectionally (Firestore ↔ Native)
- Option to update only native or both systems

### ✅ **Robust State Management**
- Riverpod providers handle loading/error states
- Combined providers show unified status

### ✅ **Always-on Protection**
- Native blocking works even when app is closed
- Persistent across device reboots

## Best Practices

### 1. **Initialize Sync on App Start**
```dart
// In your app initialization
final notifier = ref.read(blockedContentNotifierProvider.notifier);
await notifier.syncFirestoreToNative(userId);
```

### 2. **Handle Errors Gracefully**
```dart
final notifier = ref.watch(blockedContentNotifierProvider);
notifier.when(
  data: (_) => Text('Success'),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### 3. **Use Combined Providers for Status**
```dart
// Don't query native and Firestore separately
// Use combined providers instead
final isActive = ref.watch(isAppBlockingActiveProvider(userId));
```

### 4. **Batch Operations**
```dart
// Enable multiple blocking types together
await Future.wait([
  notifier.setPersistentAppBlocking(userId: userId, enabled: true, blockedApps: apps),
  notifier.setPersistentWebsiteBlocking(userId: userId, enabled: true, blockedWebsites: sites),
]);
```

## Example Implementation

See `lib/presentation/widgets/persistent_blocking_control.dart` for a complete working example showing:
- Status display for all blocking types
- Enable/disable controls
- Sync functionality
- Error handling

This creates a seamless experience where Flutter UI changes immediately take effect in the native blocking system! 🎯
