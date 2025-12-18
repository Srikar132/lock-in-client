# Lock-In Focus App - Complete Architecture Documentation

## 🏗️ Project Overview

This is a comprehensive Flutter-Android hybrid application that helps users manage focus sessions and block distracting content. The app features both session-based blocking (during active focus sessions) and persistent blocking (always active regardless of session state).

## 📱 Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Authentication, Firestore, Analytics)
- **Native Android**: Kotlin services for deep system integration
- **State Management**: Riverpod 3.0
- **Database**: 
  - Cloud Firestore (primary)
  - SharedPreferences (native settings)
  - Hive (local cache - deprecated in favor of Firebase)

## 🔄 High-Level Data Flow

```
┌─────────────────┐    Method Channels    ┌──────────────────────┐
│   Flutter UI    │ ←→ ←→ ←→ ←→ ←→ ←→ ←→ │  Android Services   │
│                 │                       │                      │
│ Riverpod State  │                       │ FocusModeManager     │
│ Providers       │                       │ AppMonitoringService │
│                 │                       │ WebBlockingVPN       │
└─────────────────┘                       │ ShortFormBlocking    │
         ↕                                │ NotificationBlocking │
┌─────────────────┐                       └──────────────────────┘
│   Firebase      │                                ↕
│   Firestore     │                       ┌──────────────────────┐
│                 │                       │ SharedPreferences    │
│ User Data       │                       │ (Native Settings)    │
│ Sessions        │                       └──────────────────────┘
│ Blocked Content │
└─────────────────┘
```

---

## 🎯 Core Android Services Architecture

### 1. **FocusModeManager.kt** - Central Coordinator
**Role**: Master controller for all focus operations and persistent blocking
**Location**: `android/app/src/main/kotlin/com/example/lock_in/managers/FocusModeManager.kt`

```kotlin
class FocusModeManager(private val context: Context) {
    // Session Management
    - startFocusSession()
    - pauseSession()
    - resumeSession()
    - endSession()
    
    // Persistent Blocking Control
    - setPersistentAppBlocking(enabled: Boolean)
    - setPersistentWebsiteBlocking(enabled: Boolean) 
    - setPersistentShortFormBlocking(enabled: Boolean)
    - setPersistentNotificationBlocking(enabled: Boolean)
    
    // Service Coordination
    - startAllServices()
    - stopAllServices()
    - restartServices()
}
```

**Key Data Flow**:
1. Receives commands from Flutter via MainActivity method channels
2. Stores persistent settings in SharedPreferences
3. Coordinates all other services (App, Web, ShortForm, Notification blocking)
4. Manages session lifecycle and blocking enforcement

---

### 2. **AppMonitoringService.kt** - App Blocking Engine
**Role**: Foreground service that monitors running apps and enforces blocking
**Location**: `android/app/src/main/kotlin/com/example/lock_in/services/AppMonitoringService.kt`

```kotlin
class AppMonitoringService : Service() {
    // Core Monitoring
    - startMonitoring()
    - stopMonitoring()
    - checkCurrentApp()
    
    // Blocking Logic
    - shouldBlockApp(packageName: String): Boolean
    - loadBlockedApps()
    - showOverlay(packageName: String)
    
    // Lifecycle
    - onCreate()
    - onStartCommand()
    - onDestroy()
}
```

**Data Flow**:
```
User Opens App → Service Detects → Check Blocking Rules → Show Overlay/Allow
                     ↓
                SharedPreferences ← FocusModeManager ← Flutter Commands
                     ↓
            [Session Rules] + [Persistent Rules] = Final Decision
```

**Blocking Decision Matrix**:
```kotlin
fun shouldBlockApp(packageName: String): Boolean {
    val persistentBlocked = isPersistentAppBlocked(packageName)
    val sessionBlocked = isSessionBlocked(packageName) 
    val sessionActive = isSessionActive()
    
    return persistentBlocked || (sessionBlocked && sessionActive)
}
```

---

### 3. **WebBlockingVPNService.kt** - Website Filtering
**Role**: VPN-based service for blocking websites and web content
**Location**: `android/app/src/main/kotlin/com/example/lock_in/services/WebBlockingVPNService.kt`

```kotlin
class WebBlockingVPNService : VpnService() {
    // VPN Management
    - startVPN()
    - stopVPN()
    - setupVPNInterface()
    
    // Traffic Filtering  
    - filterPackets()
    - checkBlockedDomains()
    - handleDNSRequests()
    
    // Configuration
    - loadBlockedWebsites()
    - updateBlockingRules()
}
```

**Data Flow**:
```
Network Request → VPN Interface → DNS Resolution → Block/Allow Decision
                                        ↓
                              Blocked Domains List ← Persistent + Session Rules
```

---

### 4. **ShortFormBlockingService.kt** - Reels/Shorts Filtering  
**Role**: Blocks short-form content (YouTube Shorts, Instagram Reels, TikTok)
**Location**: `android/app/src/main/kotlin/com/example/lock_in/services/ShortFormBlockingService.kt`

```kotlin
class ShortFormBlockingService : AccessibilityService() {
    // Content Detection
    - analyzeScreenContent()
    - detectShortFormElements()
    - checkBlockingRules()
    
    // Blocking Actions
    - blockYouTubeShorts()
    - blockInstagramReels() 
    - blockTikTokVideos()
    
    // Configuration
    - loadShortFormBlocks()
    - isPlatformBlocked(platform: String): Boolean
}
```

**Short-Form Blocking Matrix**:
```
Platform + Feature → Check Rules → Action
YouTube + Shorts   → Blocked?    → Hide/Overlay
Instagram + Reels  → Blocked?    → Navigate Away  
TikTok + Videos   → Blocked?     → Show Overlay
```

---

### 5. **NotificationBlockingService.kt** - Notification Management
**Role**: Filters and blocks notifications from specified apps
**Location**: `android/app/src/main/kotlin/com/example/lock_in/services/NotificationBlockingService.kt`

```kotlin
class NotificationBlockingService : NotificationListenerService() {
    // Notification Interception
    - onNotificationPosted()
    - onNotificationRemoved()  
    - shouldBlockNotification()
    
    // Filtering Logic
    - checkBlockedApps()
    - checkPersistentBlocks()
    - checkSessionBlocks()
    
    // Actions
    - dismissNotification()
    - allowNotification()
}
```

---

### 6. **FlutterOverlayManager.kt** - UI Integration
**Role**: Manages overlay screens shown when blocked content is accessed
**Location**: `android/app/src/main/kotlin/com/example/lock_in/managers/FlutterOverlayManager.kt`

```kotlin
class FlutterOverlayManager(private val context: Context) {
    // Overlay Management
    - showAppBlockedOverlay()
    - showWebsiteBlockedOverlay()
    - showShortsBlockedOverlay()
    - hideOverlay()
    
    // Flutter Integration
    - sendOverlayData()
    - handleFlutterEvents()
    - updateOverlayContent()
}
```

---

## 📱 Flutter Architecture

### Core Provider Structure

```dart
┌─────────────────────────┐
│   Presentation Layer    │
│                         │
│ ┌─────────────────────┐ │
│ │    UI Widgets       │ │
│ │  - Screens          │ │  
│ │  - Overlays         │ │
│ │  - Components       │ │
│ └─────────────────────┘ │
│           ↕             │
│ ┌─────────────────────┐ │
│ │ Riverpod Providers  │ │
│ │  - State Notifiers  │ │
│ │  - Stream Providers │ │
│ │  - Future Providers │ │
│ └─────────────────────┘ │
└─────────────────────────┘
          ↕
┌─────────────────────────┐
│     Data Layer         │
│                        │
│ ┌─────────────────────┐│
│ │   Repositories      ││
│ │  - Auth Repo        ││
│ │  - Session Repo     ││
│ │  - Content Repo     ││
│ └─────────────────────┘│
│           ↕            │
│ ┌─────────────────────┐│
│ │    Services        ││
│ │  - NativeService   ││
│ │  - Firebase        ││
│ └─────────────────────┘│
└─────────────────────────┘
```

---

## 🔄 State Management with Riverpod

### 1. **Authentication Flow**
**File**: `lib/presentation/providers/auth_provider.dart`

```dart
// Firebase Auth Stream (Single Source of Truth)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// User Data Stream  
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  return authState.when(
    data: (firebaseUser) => firebaseUser != null 
        ? userRepository.streamUserData(firebaseUser.uid)
        : Stream.value(null),
    loading: () => Stream.value(null),
    error: (error, stack) => Stream.value(null),
  );
});

// Navigation Helpers
final shouldShowOnboardingProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user != null && !user.hasCompletedOnboarding;
});
```

**Data Flow**:
```
Firebase Auth → authStateProvider → currentUserProvider → UI Navigation
                      ↓
                Navigation Providers → Screen Routing
```

---

### 2. **Focus Session Management**  
**File**: `lib/presentation/providers/focus_session_provider.dart`

```dart
class FocusSessionNotifier extends Notifier<FocusSessionState> {
  // Session Control
  Future<void> startSession({
    required int plannedDuration,
    required String sessionType,
    required List<String> blockedApps,
    // ... other params
  }) async {
    // 1. Start Native Session
    final success = await NativeService.startFocusSession(/*params*/);
    
    // 2. Create Firestore Record
    final sessionId = await sessionRepository.createSession(sessionModel);
    
    // 3. Update State
    state = state.copyWith(
      status: FocusSessionStatus.active,
      sessionId: sessionId,
      plannedDuration: plannedDuration,
    );
    
    // 4. Start Local Timer
    _startLocalTimer();
  }
}
```

**Session Lifecycle**:
```
UI Start Button → startSession() → Native Service → Android Services → Block Apps
                       ↓
                 Firestore Record → State Update → UI Updates → Timer Display
```

---

### 3. **Blocked Content Management**
**File**: `lib/presentation/providers/blocked_content_provider.dart`

```dart
// Main Data Stream from Firestore
final blockedContentProvider = StreamProvider.family<BlockedContentModel, String>(
  (ref, userId) {
    return blockedContentRepository.getBlockedContentStream(userId);
  },
);

// Derived Providers for UI
final blockedWebsitesProvider = Provider.family<AsyncValue<List<BlockedWebsite>>, String>(
  (ref, userId) {
    final contentAsync = ref.watch(blockedContentProvider(userId));
    return contentAsync.whenData((content) => content.blockedWebsites);
  },
);

// Native Integration Providers
final nativePersistentAppBlockingProvider = FutureProvider<bool>((ref) async {
  return await NativeService.isPersistentAppBlockingEnabled();
});

// Combined Status Providers  
final isAppBlockingActiveProvider = Provider.family<bool, String>((ref, userId) {
  final firestoreBlocked = ref.watch(permanentlyBlockedAppsProvider(userId));
  final nativeEnabled = ref.watch(nativePersistentAppBlockingProvider);

  return firestoreBlocked.whenData((apps) => apps.isNotEmpty).value == true ||
         nativeEnabled.whenData((enabled) => enabled).value == true;
});
```

**Blocking Data Flow**:
```
Firestore Data → blockedContentProvider → Derived Providers → UI Components
      +                                          ↕
Native Settings → nativePersistentProviders → Combined Status → Blocking Logic
```

---

## 🔗 Flutter-Android Integration

### Method Channel Communication
**File**: `lib/services/native_service.dart` ↔ `android/.../MainActivity.kt`

```dart
// Flutter Side - NativeService.dart
class NativeService {
  static const _platform = MethodChannel('com.lockin.focus/native');
  
  // Focus Session Control
  static Future<bool> startFocusSession({...}) async {
    return await _platform.invokeMethod('startFocusSession', {
      'sessionId': sessionId,
      'userId': userId,
      'plannedDuration': plannedDuration,
      // ... other params
    });
  }
  
  // Persistent Blocking Control
  static Future<void> setPersistentAppBlocking(bool enabled) async {
    await _platform.invokeMethod('setPersistentAppBlocking', {
      'enabled': enabled,
    });
  }
}
```

```kotlin
// Android Side - MainActivity.kt  
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.lockin.focus/native")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startFocusSession" -> {
                        val success = focusModeManager.startFocusSession(
                            call.argument<String>("sessionId")!!,
                            call.argument<String>("userId")!!,
                            call.argument<Int>("plannedDuration")!!,
                            // ... other params
                        )
                        result.success(success)
                    }
                    
                    "setPersistentAppBlocking" -> {
                        focusModeManager.setPersistentAppBlocking(
                            call.argument<Boolean>("enabled") ?: false
                        )
                        result.success(null)
                    }
                }
            }
    }
}
```

### Event Channel Communication (Android → Flutter)
```dart
// Flutter Side - Listening to Native Events
class FocusSessionNotifier extends Notifier<FocusSessionState> {
  void _listenToNativeEvents() {
    _eventSubscription = NativeService.eventStream.listen((data) {
      switch (data['event']) {
        case 'sessionStarted':
          _handleSessionStarted(data);
          break;
        case 'sessionPaused':
          _handleSessionPaused(data);
          break;
        case 'sessionCompleted':
          _handleSessionCompleted(data);
          break;
      }
    });
  }
}
```

```kotlin
// Android Side - Sending Events
class FocusModeManager {
    private fun sendEventToFlutter(eventName: String, data: Map<String, Any>) {
        eventSink?.success(mapOf(
            "event" to eventName,
            "data" to data
        ))
    }
    
    fun startFocusSession(...) {
        // Start session logic
        sendEventToFlutter("sessionStarted", mapOf(
            "sessionId" to sessionId,
            "startTime" to System.currentTimeMillis()
        ))
    }
}
```

---

## 💾 Data Persistence Strategy

### 1. **Firebase Firestore** (Primary Database)
```
users/{userId}/
├── profile (UserModel)
├── settings (UserSettingsModel)  
├── sessions/{sessionId} (FocusSessionModel)
└── blockedContent (BlockedContentModel)
    ├── permanentlyBlockedApps: List<String>
    ├── blockedWebsites: List<BlockedWebsite>
    ├── shortFormBlocks: Map<String, ShortFormBlock>
    └── notificationBlocks: Map<String, NotificationBlock>
```

### 2. **Android SharedPreferences** (Native Settings)
```kotlin
// Persistent Blocking Settings
"persistent_app_blocking_enabled" → Boolean
"persistent_blocked_apps" → Set<String>
"persistent_website_blocking_enabled" → Boolean  
"persistent_blocked_websites" → JSON String
"persistent_shortform_blocking_enabled" → Boolean
"persistent_shortform_blocks" → JSON String
"persistent_notification_blocking_enabled" → Boolean
"persistent_notification_blocks" → JSON String

// Session Settings
"current_session_id" → String
"session_blocked_apps" → Set<String>
"session_blocked_websites" → JSON String
// ...
```

### 3. **Data Synchronization Flow**
```
Flutter UI Change → Firestore Update → Native Sync → SharedPreferences
                         ↓                    ↕
                   Real-time Listener → Provider Update → UI Refresh
```

---

## 🚀 Service Lifecycle Management

### Service Startup Sequence
```kotlin
// 1. App Launch
MainActivity.onCreate() 
    ↓
// 2. Initialize Managers  
FocusModeManager.initialize()
    ↓
// 3. Check Persistent Settings
loadPersistentSettings()
    ↓  
// 4. Start Required Services
if (persistentAppBlocking) startService(AppMonitoringService)
if (persistentWebBlocking) startService(WebBlockingVPNService)  
if (persistentShortFormBlocking) startService(ShortFormBlockingService)
if (persistentNotificationBlocking) startService(NotificationBlockingService)
```

### Service Coordination Matrix
```
┌─────────────────┬─────────┬─────────┬────────────┬──────────────┐
│ Trigger Event   │ App Svc │ Web Svc │ Short Svc  │ Notif Svc    │
├─────────────────┼─────────┼─────────┼────────────┼──────────────┤
│ Focus Start     │ ✓ Start │ ✓ Start │ ✓ Start    │ ✓ Start      │
│ Focus End       │ ? Cont  │ ? Cont  │ ? Cont     │ ? Cont       │
│ Persistent On   │ ✓ Start │ ✓ Start │ ✓ Start    │ ✓ Start      │
│ Persistent Off  │ ✗ Stop  │ ✗ Stop  │ ✗ Stop     │ ✗ Stop       │
│ App Killed      │ ↻ Auto  │ ↻ Auto  │ ↻ Auto     │ ↻ Auto       │
└─────────────────┴─────────┴─────────┴────────────┴──────────────┘

Legend: ✓ = Start, ✗ = Stop, ? = Conditional, ↻ = Restart
```

---

## 🎯 Blocking Logic Architecture

### Blocking Decision Engine
```kotlin
class BlockingDecisionEngine {
    fun shouldBlock(
        contentType: ContentType,
        identifier: String,
        context: BlockingContext
    ): BlockingDecision {
        
        val persistentRules = getPersistentRules(contentType)
        val sessionRules = getSessionRules(contentType) 
        val sessionActive = isSessionActive()
        
        return when {
            // Persistent blocking always applies
            persistentRules.isBlocked(identifier) -> BlockingDecision.BLOCK
            
            // Session blocking only applies during active session
            sessionActive && sessionRules.isBlocked(identifier) -> BlockingDecision.BLOCK
            
            // Allow by default
            else -> BlockingDecision.ALLOW
        }
    }
}
```

### Content Type Handlers
```
┌─────────────────┬─────────────────┬─────────────────┬─────────────────┐
│ Content Type    │ Identifier      │ Detection       │ Blocking Action │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ Android App     │ Package Name    │ Usage Stats API │ Show Overlay    │
│ Website         │ Domain/URL      │ VPN DNS Filter  │ Block Connection│
│ YouTube Shorts  │ UI Elements     │ Accessibility   │ Hide Elements   │
│ Instagram Reels │ Screen Content  │ Accessibility   │ Navigate Away   │
│ TikTok Videos   │ App Detection   │ Usage Stats     │ Show Overlay    │  
│ Notifications   │ Package Name    │ NotificationSvc │ Dismiss/Block   │
└─────────────────┴─────────────────┴─────────────────┴─────────────────┘
```

---

## 🔄 Real-Time Synchronization

### Firebase to Native Sync
```dart
// 1. Firestore Change Detection
class BlockedContentNotifier extends Notifier<AsyncValue<void>> {
  Future<void> syncWithNative(String userId) async {
    final content = await _repository.getBlockedContent(userId);
    
    // Sync each blocking type
    await NativeService.setPersistentBlockedApps(content.permanentlyBlockedApps);
    await NativeService.setPersistentBlockedWebsites(content.blockedWebsites);
    await NativeService.setPersistentShortFormBlocks(content.shortFormBlocks);
    await NativeService.setPersistentNotificationBlocks(content.notificationBlocks);
  }
}
```

### Native to Firebase Sync  
```kotlin
// Android services can trigger Flutter updates via events
class FocusModeManager {
    fun onPersistentSettingChanged(setting: String, value: Any) {
        // Update SharedPreferences
        saveToPreferences(setting, value)
        
        // Notify Flutter
        sendEventToFlutter("persistentSettingChanged", mapOf(
            "setting" to setting,
            "value" to value
        ))
    }
}
```

---

## 🧪 Testing & Debugging

### Debug Information Flow
```dart
// 1. Flutter Debug Info
final debugInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final sessionState = ref.watch(focusSessionProvider);
  final authState = ref.watch(authStateProvider);
  
  return {
    'sessionActive': sessionState.isActive,
    'currentUser': authState.value?.uid,
    'persistentBlocking': {
      'apps': ref.watch(nativePersistentAppBlockingProvider).value,
      'websites': ref.watch(nativePersistentWebsiteBlockingProvider).value,
    },
  };
});
```

```kotlin
// 2. Native Debug Logging
class DebugLogger {
    companion object {
        fun logBlockingDecision(
            contentType: String,
            identifier: String, 
            decision: String,
            reason: String
        ) {
            Log.d("BlockingEngine", 
                "[$contentType] $identifier -> $decision ($reason)"
            )
        }
    }
}
```

---

## 📊 Performance Considerations

### 1. **Service Optimization**
- AppMonitoringService polls every 1 second (configurable)
- WebBlockingVPN uses efficient packet filtering
- ShortFormBlocking uses targeted accessibility events
- NotificationBlocking intercepts at system level

### 2. **Memory Management**  
- Services use foreground notifications to prevent killing
- Shared data structures to minimize memory usage
- Proper cleanup in service onDestroy() methods

### 3. **Battery Optimization**
- VPN service uses minimal CPU for packet inspection
- Accessibility service only listens to relevant apps
- Usage Stats API called efficiently with caching

---

## 🔧 Configuration & Settings

### Environment Configuration
```dart
// firebase_options.dart (Auto-generated)
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;
  
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'your-api-key',
    appId: 'your-app-id', 
    projectId: 'your-project-id',
    // ...
  );
}
```

### Build Configuration
```gradle
// android/app/build.gradle.kts
android {
    compileSdk = 34
    
    defaultConfig {
        applicationId = "com.example.lock_in"
        minSdk = 24
        targetSdk = 34
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-auth-ktx")
}
```

---

## 🚀 Deployment & Distribution

### Release Process
1. **Flutter Build**: `flutter build apk --release`
2. **Firebase Configuration**: Production environment setup
3. **Android Permissions**: Verify all required permissions granted
4. **Service Testing**: Ensure all blocking services work correctly
5. **Play Store**: Upload with proper privacy policy and permissions declaration

### Required Permissions
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.USAGE_STATS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.BIND_ACCESSIBILITY_SERVICE" />
<uses-permission android:name="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE" />
<uses-permission android:name="android.permission.BIND_VPN_SERVICE" />
```

---

## 📈 Future Enhancements

1. **iOS Support**: Extend architecture to support iOS Screen Time controls
2. **Machine Learning**: AI-powered distraction detection and blocking
3. **Team Features**: Multi-user focus sessions and challenges
4. **Advanced Analytics**: Detailed productivity insights and reporting
5. **Custom Rules**: User-defined blocking rules and exceptions

---

## 🎯 Summary

This architecture provides a robust, scalable foundation for a focus management app with the following key strengths:

- **Separation of Concerns**: Clear boundaries between Flutter UI, Android services, and data layers
- **Persistent + Session Blocking**: Flexible blocking that works with or without active focus sessions  
- **Real-time Sync**: Bidirectional synchronization between Flutter and native Android
- **Service Resilience**: Auto-restarting services with proper lifecycle management
- **Scalable State Management**: Riverpod providers for clean, reactive UI updates
- **Performance Optimized**: Efficient native services with minimal battery impact

The data flows seamlessly from user interactions through Riverpod providers to Firebase cloud storage, while native Android services enforce blocking rules in real-time, creating a comprehensive focus management system.
