# Testing App Limits - Debugging Guide

## Latest Fix: Periodic Limit Checking (Dec 20, 2025)

### Problem
App limits were only enforced when switching between apps. If you stayed in an app continuously, the limit would never trigger until you switched away and back.

**Example**: Set Flipkart to 2 minutes → Open Flipkart and stay for 2+ minutes → Nothing happens until you manually refresh blocks screen.

### Solution
Added **periodic limit checking** that runs every 5 seconds while you're actively using an app with a limit. Now the app will be automatically closed as soon as the limit is exceeded, even if you stay in it continuously.

## Changes Made

### 1. Added Usage Stats Permission Check
- Added `_checkAndRequestUsageStatsPermission()` function in [blocks_screen.dart](lib/presentation/screens/blocks_screen.dart)
- Permission check is now called BEFORE allowing user to add limits
- Shows dialog explaining why Usage Access permission is needed
- Opens Android Settings to grant permission

### 2. Enhanced Logging Throughout

#### Flutter Side
- **app_limit_native_service.dart**: Added print statements for event handler initialization
- **blocks_screen.dart**: Added logging when permission check is called

#### Kotlin Side
- **AppLimitTracker.kt**: 
  - Logs when checking limits for each app
  - Logs total usage vs limit
  - Logs percentage used
  - Clear warning when limit exceeded
  
- **LockInAccessibilityService.kt**:
  - Logs when enforcing limits
  - Logs BACK action results
  - Logs when sending events to Flutter
  - Warns if event channel is null
  
- **MainActivity.kt**:
  - Logs when receiving updateLimits call
  - Logs each limit being set
  - Logs successful update
  
- **LockInNativeLimitsHolder.kt**:
  - Logs all limits being updated
  - Shows current active limits

## Test Plan

### Step 1: Check Permissions
1. Run the app: `flutter run`
2. Go to "Blocks" tab
3. Tap the "+" button to add a limit
4. **Expected**: Dialog should appear asking for Usage Access permission
5. Tap "Open Settings"
6. Enable "LockIn" in the Usage Access settings
7. Return to the app

### Step 2: Add a Test Limit
1. Tap "+" again
2. Search for "Chrome" (or any browser you have)
3. Select Chrome
4. Set limit to **1 minute** (for quick testing)
5. Tap "Add Limit"
6. **Expected**: Chrome should appear in the list with 1 minute limit

### Step 3: Watch Logcat (Android Studio or Terminal)
Open a terminal and run:
```bash
adb logcat | grep -E "LockIn|AppLimit|MainActivity"
```

Or in Android Studio: View > Tool Windows > Logcat

### Step 4: Test Enforcement
1. Open Flipkart on your phone
2. **Stay in Flipkart** without switching apps
3. Wait for more than 1 minute
4. **Watch the logs for**:
   ```
   ⏰ Starting periodic limit check for com.flipkart.android every 5s
   ⏱️ Periodic check: Checking limit for com.flipkart.android
   🔍 checkLimit for com.flipkart.android
   🚫 LIMIT EXCEEDED!
   ⏱️ Periodic check: LIMIT EXCEEDED during active use!
   ⚠️⚠️⚠️ ENFORCING APP LIMIT FOR com.flipkart.android
   ✅ Successfully sent limit reached event to Flutter
   ```

5. **Expected Behavior**:
   - After **exactly 1 minute** (or within 5 seconds of that), Flipkart automatically closes
   - A dialog appears in LockIn showing limit exceeded
   - You're taken back to home screen or previous app

### Step 5: Debug if Not Working

#### If permission dialog doesn't appear:
- Check logs for: `📊 Checking usage stats permission`
- Check if `NativeService.hasUsageStatsPermission()` is being called
- Manually grant permission in Android Settings > Apps > Special app access > Usage access

#### If limit not enforcing:
Check logs for these key indicators:

**1. Is limit being set?**
```
🔄 updateLimits called
✅ Set limit for com.android.chrome: 1 minutes
✅ Updated 1 app limits
```

**2. Is app switch being detected?**
```
Event: TYPE_WINDOW_STATE_CHANGED for com.android.chrome
```

**3. Is tracker checking the limit?**
```
🔍 checkLimit for com.android.chrome
➡️ com.android.chrome HAS a limit set
```

**4. Is usage being tracked?**
```
Usage for com.android.chrome: historical=XXXs, session=XXXs, total=XXXs
```

**5. Is limit being exceeded?**
```
🚫 LIMIT EXCEEDED! Usage: XXXmin >= Limit: 1min
```

**6. Is enforcement triggered?**
```
⚠️⚠️⚠️ ENFORCING APP LIMIT FOR com.android.chrome
```

**7. Is event sent to Flutter?**
```
✅ Successfully sent limit reached event to Flutter
```

#### Common Issues:

**Issue 1: No limit set logs**
- Means Flutter didn't sync limits to Kotlin
- Check if `_syncLimitsToNative()` is called in blocks_screen
- Check if `updateLimits()` is called in NativeService

**Issue 2: Limit set but not checking**
- Means AccessibilityService might not be enabled
- Go to Settings > Accessibility > LockIn > Enable

**Issue 3: Checking but not exceeding**
- Means UsageStatsManager isn't returning usage data
- Make sure Usage Access permission is granted
- Try using the app for longer than the limit

**Issue 4: Exceeding but not enforcing**
- Check if `enforceAppLimit()` is being called
- Check if `limitEventsChannel` is null
- Check if AccessibilityService can perform BACK action

**Issue 5: Enforcing but no Flutter dialog**
- Check if event handler is initialized: `🎧 Limit events handler initialized`
- Check if handler receives event: `📥 Limit reached event received`
- Check if blocks_screen is mounted and listening

## Expected Log Flow (Successful Enforcement)

```
// When app starts
📥 Received updateLimits call from Flutter
✅ Set limit for com.android.chrome: 1 minutes
✅ Updated 1 app limits

// When user opens Chrome
Event: TYPE_WINDOW_STATE_CHANGED for com.android.chrome
🔍 checkLimit for com.android.chrome
➡️ com.android.chrome HAS a limit set
➡️ Total usage: 65000ms (1min), Limit: 60000ms (1min)
🚫 LIMIT EXCEEDED! Usage: 1min >= Limit: 1min

// Enforcement
⚠️⚠️⚠️ ENFORCING APP LIMIT FOR com.android.chrome ⚠️⚠️⚠️
First BACK action result: true
Sending limit reached event to Flutter for com.android.chrome
✅ Successfully sent limit reached event to Flutter

// Flutter receives event
📥 Limit reached event received for: com.android.chrome
```

## Next Steps After Testing

Based on test results, we may need to:
1. Ensure AccessibilityService is properly enabled
2. Ensure Usage Access permission is granted
3. Verify MethodChannel communication is working
4. Add more fallback mechanisms for enforcement
5. Implement Block/Warn/Notify modes differently

## Quick Commands

```bash
# View filtered logs
adb logcat | grep -E "LockIn|AppLimit|MainActivity"

# Clear logs before testing
adb logcat -c

# Check if AccessibilityService is running
adb shell dumpsys accessibility | grep -A 10 LockIn

# Check app permissions
adb shell dumpsys package com.example.lock_in | grep permission
```
