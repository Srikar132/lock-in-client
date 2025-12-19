# Allowed Apps Feature Implementation

## Overview
This document describes the implementation of the **Allowed Apps Drawer** feature, which displays all non-blocked apps during an active focus session in a mobile app drawer-style interface.

## Components Created

### 1. Provider: `allowedAppsProvider`
**Location:** `lib/presentation/providers/app_management_provide.dart`

**Purpose:** Filters installed apps to show only those that are NOT in the blocked list.

**Key Features:**
- Takes `userId` as a parameter to fetch user-specific blocked apps
- Combines `installedAppsProvider` and `permanentlyBlockedAppsProvider`
- Filters out both blocked apps and system apps
- Sorts the allowed apps alphabetically by app name
- Returns an `AsyncValue<List<InstalledApp>>` for proper loading/error state handling

**Implementation:**
```dart
final allowedAppsProvider = Provider.family<AsyncValue<List<InstalledApp>>, String>((ref, userId) {
  final appsAsync = ref.watch(installedAppsProvider);
  final blockedAppsAsync = ref.watch(permanentlyBlockedAppsProvider(userId));

  return appsAsync.when(
    data: (apps) {
      return blockedAppsAsync.when(
        data: (blockedPackages) {
          final allowed = apps.where((app) {
            final isNotBlocked = !blockedPackages.contains(app.packageName);
            final isNotSystem = !app.isSystemApp;
            return isNotBlocked && isNotSystem;
          }).toList();
          
          allowed.sort((a, b) => a.appName.compareTo(b.appName));
          return AsyncValue.data(allowed);
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
```

### 2. Widget: `AllowedAppsDrawer`
**Location:** `lib/widgets/allowed_apps_drawer.dart`

**Purpose:** Displays allowed apps in a bottom sheet with a mobile app drawer-style grid layout.

**Key Features:**
- **Responsive Design:** Takes up 75% of screen height
- **Grid Layout:** 4 columns with proper spacing
- **App Icons:** Uses `appIconProvider` to fetch and display app icons
- **Loading States:** Shows loading indicators while fetching apps and icons
- **Error Handling:** Displays user-friendly error messages
- **Empty State:** Shows a message when all apps are blocked
- **Drag Handle:** Visual indicator for bottom sheet
- **Close Button:** Easy dismissal of the drawer

**UI Components:**
1. **Header Section:**
   - Drag handle for visual feedback
   - Apps icon and "Allowed Apps" title
   - Close button (X icon)

2. **Grid View:**
   - 4 columns per row
   - Each app tile shows:
     - App icon (56x56 pixels) with rounded corners and shadow
     - App name (max 2 lines, ellipsis overflow)
     - Loading indicator while icon loads
     - Fallback Android icon if icon fails to load

3. **Empty State:**
   - Block icon
   - "All apps are blocked" message
   - Descriptive subtitle

4. **Error State:**
   - Error icon
   - Error message
   - Technical error details (for debugging)

### 3. Integration: `ActiveFocusScreen`
**Location:** `lib/presentation/screens/active_focus_screen.dart`

**Changes Made:**

1. **Added Import:**
   ```dart
   import 'package:lock_in/widgets/allowed_apps_drawer.dart';
   ```

2. **Added Method:**
   ```dart
   void _showAllowedAppsDrawer() {
     final user = ref.read(currentUserProvider).value;
     if (user != null) {
       BottomSheetManager.show(
         context: context,
         height: MediaQuery.of(context).size.height * 0.75,
         child: AllowedAppsDrawer(userId: user.uid),
       );
     }
   }
   ```

3. **Updated Apps Navigation Icon:**
   - Added `onTap: _showAllowedAppsDrawer` callback to the Apps icon
   - Now when users tap the Apps icon in the bottom navigation, it opens the allowed apps drawer

## Usage Flow

1. User is in an active focus session (`ActiveFocusScreen`)
2. User taps the "Apps" icon in the bottom navigation bar
3. `_showAllowedAppsDrawer()` method is called
4. Method checks if user is authenticated
5. `BottomSheetManager.show()` displays the `AllowedAppsDrawer` widget
6. The drawer:
   - Fetches allowed apps using `allowedAppsProvider(userId)`
   - Displays apps in a 4-column grid
   - Loads each app icon using `appIconProvider(packageName)`
   - Shows loading/error/empty states as needed
7. User can:
   - View all allowed apps
   - Scroll through the list if there are many apps
   - Tap the close button or drag down to dismiss

## Technical Details

### State Management
- Uses **Riverpod** for state management
- `ConsumerWidget` for reactive UI updates
- `AsyncValue` for handling loading/error/data states
- Provider families for parameterized providers

### Performance Optimizations
- **Icon Caching:** `appIconProvider` uses family provider for individual icon caching
- **Lazy Loading:** Icons load individually as needed
- **Efficient Filtering:** Filters happen in provider, not in UI
- **Sorted Display:** Pre-sorted alphabetically for better UX

### Error Handling
- Graceful fallback to default Android icon if app icon fails to load
- Error messages displayed to user with technical details
- Loading indicators prevent blank screens

### Styling
- **Colors:** White background with grey accents
- **Shadows:** Subtle shadows on app icons for depth
- **Rounded Corners:** 12px border radius on icons and drawer
- **Typography:** 
  - Title: 22px, bold
  - App names: 12px, 2 lines max
  - Messages: 14-18px depending on importance

## Dependencies Used

- `flutter_riverpod`: State management
- `InstalledApp` model: App data structure
- `NativeService`: Fetching installed apps and icons
- `BottomSheetManager`: Displaying bottom sheets
- `blockedContentProvider`: Getting blocked apps list
- `currentUserProvider`: User authentication state

## Future Enhancements (Optional)

1. **Search Functionality:** Add search bar to filter allowed apps
2. **Categories:** Group apps by category
3. **Launch Apps:** Add ability to launch apps directly (if allowed during focus)
4. **Recently Used:** Show recently used allowed apps at the top
5. **Favorites:** Let users mark favorite allowed apps
6. **App Details:** Tap app to show more details (version, size, etc.)
7. **Custom Icons:** Allow users to set custom icons for apps

## Testing Checklist

- [x] Provider compiles without errors
- [x] Widget compiles without errors
- [x] Integration in ActiveFocusScreen successful
- [ ] Test with no blocked apps (all apps shown)
- [ ] Test with all apps blocked (empty state shown)
- [ ] Test with some apps blocked (filtered list shown)
- [ ] Test icon loading performance
- [ ] Test error states (network issues, permission issues)
- [ ] Test on different screen sizes
- [ ] Test scroll performance with many apps

## Files Modified/Created

### Created:
- `lib/widgets/allowed_apps_drawer.dart` - New widget

### Modified:
- `lib/presentation/providers/app_management_provide.dart` - Added `allowedAppsProvider`
- `lib/presentation/screens/active_focus_screen.dart` - Added integration

### Documentation:
- `ALLOWED_APPS_FEATURE.md` - This file
