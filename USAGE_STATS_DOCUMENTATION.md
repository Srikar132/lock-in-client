# Usage Statistics Feature Documentation

## Overview

The Usage Statistics feature provides comprehensive app usage analytics for the Lock-In app, allowing users to track their screen time, analyze usage patterns, and identify distracting vs productive apps. This feature is implemented with a clean architecture following Flutter best practices.

## Architecture

### 1. Data Models (`lib/models/usage_stats_models.dart`)

#### Key Models:
- **`AppUsageStats`**: Individual app usage data including time, sessions, category
- **`UsageStatsResponse`**: Complete response with apps list, summary, and period info
- **`UsageSummary`**: Aggregated statistics (total time, averages, top apps)
- **`UsagePatternsResponse`**: Hourly usage breakdown for pattern analysis
- **`DailyUsageChartData`**: Chart-specific data for weekly view
- **`AppCategory`**: Enum for categorizing apps (Distracting, Productive, Others)

#### Category Classification:
Apps are automatically categorized based on package name patterns:
- **Distracting**: Social media, entertainment (Instagram, YouTube, TikTok, etc.)
- **Productive**: Work tools, productivity apps (Office, Docs, Slack, etc.)
- **Others**: Everything else

### 2. Native Service (`lib/services/native_service.dart`)

#### Available Methods:
```dart
// Get usage stats for specified days
static Future<Map<String, dynamic>> getAppUsageStats({int days = 7})

// Get today's usage stats only
static Future<Map<String, dynamic>> getTodayUsageStats()

// Get hourly usage patterns for today
static Future<Map<String, dynamic>> getTodayUsagePatterns()

// Get specific app usage over time
static Future<Map<String, dynamic>> getAppSpecificUsage({
  required String packageName,
  int days = 7,
})
```

### 3. State Management (`lib/presentation/providers/usage_stats_provider.dart`)

#### Providers:
- **`usageStatsProvider`**: Main state management with view mode and filtering
- **`todayUsageStatsProvider`**: Today's stats (FutureProvider)
- **`weeklyUsageStatsProvider`**: Weekly stats (FutureProvider)
- **`weeklyChartDataProvider`**: Processed chart data
- **`quickStatsProvider`**: Dashboard summary stats

#### Key Features:
- View mode switching (Daily/Weekly)
- Category filtering (All, Distracting, Productive, Others)
- Auto-refresh capabilities
- Error handling with retry functionality

### 4. UI Implementation (`lib/presentation/screens/usage_stats_screen.dart`)

#### Screen Features:
- **Tab-based navigation**: Daily vs Weekly views
- **Category filters**: Chip-based filtering system
- **Pull-to-refresh**: Refresh data by pulling down
- **Search functionality**: Search through apps (ready for implementation)
- **Interactive charts**: Weekly usage visualization
- **Detailed app info**: Modal with app-specific statistics

#### UI Components (`lib/presentation/widgets/usage_stats_widgets.dart`):
- **`UsageAppListTile`**: Individual app usage display
- **`AppDetailsModal`**: Detailed app statistics modal
- **`WeeklyUsageChart`**: Stacked bar chart for weekly data
- **`UsageStatsLoadingShimmer`**: Loading state animation

### 5. Android Native Implementation

#### MainActivity.kt Methods:
```kotlin
"getAppUsageStats" -> {
    val days = (arguments as? Map<String, Any>)?.get("days") as? Int ?: 7
    // Returns detailed usage stats for specified days
}

"getTodayUsageStats" -> {
    // Returns today's usage statistics
}

"getTodayUsagePatterns" -> {
    // Returns hourly usage patterns for today
}

"getAppSpecificUsage" -> {
    val packageName = args?.get("packageName") as? String
    val days = args?.get("days") as? Int ?: 7
    // Returns usage for specific app
}
```

#### UsageStatsHelper.kt Features:
- **Permission-aware**: Handles usage stats permission gracefully
- **Efficient processing**: Processes large datasets efficiently
- **Daily breakdown**: Provides day-by-day usage information
- **Error handling**: Robust error handling with fallback data

## Integration Guide

### 1. Navigation Integration

The feature is integrated into the Insights screen (`insights_screen.dart`):

```dart
// Navigate to usage stats
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const UsageStatsScreen(),
  ),
);
```

### 2. Theme Integration

Uses the app's dark theme (`app_theme.dart`) with:
- Consistent color scheme (Green: #7ED957, Orange: #FF8C00, Grey: #8A8A8A)
- Material 3 components
- Dark mode optimized colors
- Proper contrast ratios

### 3. Permission Requirements

Requires Usage Access permission from Android system settings:
- Automatically handled by existing permission system
- Graceful fallback when permission not granted
- User-friendly error messages and retry options

## Usage Examples

### Basic Usage Stats Display

```dart
Consumer(
  builder: (context, ref, child) {
    final usageStats = ref.watch(todayUsageStatsProvider);
    
    return usageStats.when(
      data: (data) => Text('Today: ${data.summary.formattedTotalTime}'),
      loading: () => CircularProgressIndicator(),
      error: (error, _) => Text('Error: $error'),
    );
  },
)
```

### Category Filtering

```dart
final usageState = ref.watch(usageStatsProvider);
final notifier = ref.read(usageStatsProvider.notifier);

// Set filter
notifier.setFilter(AppCategory.distracting);

// Get filtered apps
final filteredApps = usageState.filteredApps;
```

### Weekly Chart Display

```dart
Consumer(
  builder: (context, ref, child) {
    final chartData = ref.watch(weeklyChartDataProvider);
    
    return chartData.when(
      data: (data) => WeeklyUsageChart(data: data),
      loading: () => CircularProgressIndicator(),
      error: (_, __) => Text('Chart unavailable'),
    );
  },
)
```

## Data Flow

1. **User opens Usage Stats screen**
2. **Provider loads data** from native service
3. **Native service queries** Android UsageStatsManager
4. **Data is processed** and categorized
5. **UI displays** formatted results with charts
6. **User can filter/refresh** to update view

## Performance Considerations

- **Lazy loading**: Data only loaded when needed
- **Caching**: Providers cache results until refresh
- **Efficient queries**: Native code optimized for large datasets
- **Background processing**: Heavy computations on background threads
- **Memory management**: Proper disposal of controllers and animations

## Error Handling

- **Permission errors**: Clear messages with action buttons
- **Network timeouts**: Retry mechanisms with exponential backoff
- **Data parsing errors**: Fallback to empty states
- **Native crashes**: Graceful error boundaries

## Future Enhancements

1. **Search functionality**: Filter apps by name
2. **Export data**: CSV/JSON export capabilities
3. **Usage goals**: Set and track daily/weekly limits
4. **Notifications**: Usage alerts and reports
5. **Advanced analytics**: Trends, predictions, insights
6. **Comparison views**: Week-over-week, month-over-month

## Testing

### Unit Tests
- Model serialization/deserialization
- Category classification logic
- Time formatting functions
- Provider state management

### Integration Tests
- Native service communication
- UI navigation flow
- Data refresh mechanisms
- Error state handling

### Widget Tests
- Chart rendering
- List tile interactions
- Modal presentations
- Loading states

## Troubleshooting

### Common Issues:

1. **"No data available"**
   - Ensure Usage Access permission is granted
   - Check if device has recent app usage
   - Verify native service connection

2. **"Permission denied"**
   - Navigate user to Android Settings > Usage Access
   - Grant permission for Lock-In app
   - Restart app after granting permission

3. **"Chart not loading"**
   - Check network connectivity
   - Verify sufficient usage data exists
   - Try refreshing the screen

4. **Performance issues**
   - Reduce query range (fewer days)
   - Clear app cache and restart
   - Check available device memory

## Dependencies

- `flutter_riverpod`: State management
- `flutter/services`: Method channel communication
- Native Android `UsageStatsManager`: Usage data access

This implementation provides a robust, scalable, and user-friendly usage statistics feature that matches the design requirements while maintaining good performance and user experience.
