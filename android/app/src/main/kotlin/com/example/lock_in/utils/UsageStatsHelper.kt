package com.example.lock_in.utils

import android.app.usage.UsageStatsManager
import android.content.Context
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * UsageStatsHelper - Utility functions for app usage statistics
 */
object UsageStatsHelper {

    private const val TAG = "UsageStatsHelper"

    /**
     * Get app usage statistics for the specified number of days
     */
    suspend fun getAppUsageStats(context: Context, days: Int): Map<String, Any> {
        return withContext(Dispatchers.IO) {
            try {
                val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val calendar = Calendar.getInstance()

                val endTime = calendar.timeInMillis
                calendar.add(Calendar. DAY_OF_YEAR, -days)
                val startTime = calendar.timeInMillis

                val usageStats = usageStatsManager.queryUsageStats(
                    UsageStatsManager. INTERVAL_DAILY,
                    startTime,
                    endTime
                )

                val appStats = mutableMapOf<String, MutableMap<String, Any>>()
                val totalStats = mutableMapOf<String, Long>()

                usageStats?.forEach { stats ->
                    if (stats.totalTimeInForeground > 0) {
                        val packageName = stats.packageName
                        val appName = AppUtils.getAppInfo(context, packageName)?.get("appName") as? String ?: packageName

                        if (! appStats.containsKey(packageName)) {
                            appStats[packageName] = mutableMapOf(
                                "appName" to appName,
                                "packageName" to packageName,
                                "totalUsageMs" to 0L,
                                "totalUsageMinutes" to 0,
                                "totalUsageHours" to 0.0,
                                "sessions" to 0,
                                "lastUsed" to 0L,
                                "dailyUsage" to mutableMapOf<String, Int>()
                            )
                        }

                        val appData = appStats[packageName]!!
                        appData["totalUsageMs"] = (appData["totalUsageMs"] as Long) + stats.totalTimeInForeground
                        appData["sessions"] = (appData["sessions"] as Int) + 1
                        appData["lastUsed"] = maxOf(appData["lastUsed"] as Long, stats.lastTimeUsed)

                        // Store daily usage
                        val dailyUsage = appData["dailyUsage"] as MutableMap<String, Int>
                        val dayKey = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date(stats.lastTimeStamp))
                        dailyUsage[dayKey] = (dailyUsage[dayKey] ?: 0) + (stats.totalTimeInForeground / 60000).toInt()

                        // Update totals
                        totalStats["totalUsageMs"] = (totalStats["totalUsageMs"] ?: 0L) + stats.totalTimeInForeground
                        totalStats["totalApps"] = appStats.size. toLong()
                    }
                }

                // Convert milliseconds to minutes and hours, sort by usage
                val sortedApps = appStats. values.map { app ->
                    val totalUsageMs = app["totalUsageMs"] as Long
                    app["totalUsageMinutes"] = (totalUsageMs / 60000).toInt()
                    app["totalUsageHours"] = (totalUsageMs / 3600000.0)
                    app
                }.sortedByDescending { it["totalUsageMs"] as Long }

                // Calculate summary statistics
                val summary = mapOf(
                    "totalAppsUsed" to appStats.size,
                    "totalUsageMs" to (totalStats["totalUsageMs"] ?:  0L),
                    "totalUsageMinutes" to ((totalStats["totalUsageMs"] ?:  0L) / 60000).toInt(),
                    "totalUsageHours" to ((totalStats["totalUsageMs"] ?: 0L) / 3600000.0),
                    "averageUsagePerApp" to if (appStats.isNotEmpty()) {
                        ((totalStats["totalUsageMs"] ?: 0L) / appStats.size / 60000).toInt()
                    } else 0,
                    "topApp" to if (sortedApps.isNotEmpty()) {
                        sortedApps.first()["appName"]
                    } else "None",
                    "daysAnalyzed" to days
                )

                mapOf(
                    "apps" to sortedApps,
                    "summary" to summary,
                    "period" to mapOf(
                        "startTime" to startTime,
                        "endTime" to endTime,
                        "days" to days
                    )
                )

            } catch (e: Exception) {
                Log.e(TAG, "Error getting usage stats", e)
                mapOf(
                    "apps" to emptyList<Map<String, Any>>(),
                    "summary" to mapOf(
                        "totalAppsUsed" to 0,
                        "totalUsageMinutes" to 0,
                        "error" to e.message
                    ),
                    "period" to mapOf(
                        "days" to days,
                        "error" to "Failed to retrieve usage statistics"
                    )
                )
            }
        }
    }

    /**
     * Get usage stats for today only
     */
    suspend fun getTodayUsageStats(context: Context): Map<String, Any> {
        return withContext(Dispatchers. IO) {
            try {
                val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val calendar = Calendar.getInstance()

                // Set to start of today
                calendar.set(Calendar.HOUR_OF_DAY, 0)
                calendar.set(Calendar.MINUTE, 0)
                calendar.set(Calendar.SECOND, 0)
                calendar.set(Calendar.MILLISECOND, 0)
                val startTime = calendar. timeInMillis

                val endTime = System.currentTimeMillis()

                val usageStats = usageStatsManager.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    startTime,
                    endTime
                )

                val todayStats = usageStats?. map { stats ->
                    val appName = AppUtils.getAppInfo(context, stats.packageName)?.get("appName") as? String ?: stats.packageName
                    val todayKey = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
                    
                    mapOf(
                        "appName" to appName,
                        "packageName" to stats.packageName,
                        "totalUsageMs" to stats.totalTimeInForeground,
                        "totalUsageMinutes" to (stats.totalTimeInForeground / 60000).toInt(),
                        "totalUsageHours" to (stats.totalTimeInForeground / 3600000.0),
                        "sessions" to 1, // This is approximate for today
                        "lastUsed" to stats.lastTimeUsed,
                        "dailyUsage" to mapOf(
                            todayKey to (stats.totalTimeInForeground / 60000).toInt()
                        )
                    )
                }?.filter { (it["totalUsageMs"] as Long) > 0 }
                    ?.sortedByDescending { it["totalUsageMs"] as Long } ?: emptyList()

                val totalUsage = todayStats. sumOf { it["totalUsageMs"] as Long }

                mapOf(
                    "apps" to todayStats,
                    "summary" to mapOf(
                        "totalAppsUsed" to todayStats.size,
                        "totalUsageMs" to totalUsage,
                        "totalUsageMinutes" to (totalUsage / 60000).toInt(),
                        "totalUsageHours" to (totalUsage / 3600000.0),
                        "averageUsagePerApp" to if (todayStats.isNotEmpty()) {
                            ((totalUsage / todayStats.size) / 60000).toInt()
                        } else 0,
                        "topApp" to if (todayStats.isNotEmpty()) {
                            todayStats.first()["appName"]
                        } else "None",
                        "daysAnalyzed" to 1
                    ),
                    "period" to mapOf(
                        "startTime" to startTime,
                        "endTime" to endTime,
                        "days" to 1
                    )
                )

            } catch (e: Exception) {
                Log.e(TAG, "Error getting today's usage stats", e)
                mapOf(
                    "apps" to emptyList<Map<String, Any>>(),
                    "summary" to mapOf(
                        "totalAppsUsed" to 0,
                        "totalUsageMs" to 0L,
                        "totalUsageMinutes" to 0,
                        "totalUsageHours" to 0.0,
                        "averageUsagePerApp" to 0,
                        "topApp" to "None",
                        "daysAnalyzed" to 1,
                        "error" to e.message
                    ),
                    "period" to mapOf(
                        "startTime" to Calendar.getInstance().apply {
                            set(Calendar.HOUR_OF_DAY, 0)
                            set(Calendar.MINUTE, 0)
                            set(Calendar.SECOND, 0)
                            set(Calendar.MILLISECOND, 0)
                        }.timeInMillis,
                        "endTime" to System.currentTimeMillis(),
                        "days" to 1,
                        "error" to "Failed to retrieve today's usage statistics"
                    )
                )
            }
        }
    }


    /**
     * Gets specific usage statistics for a single app over a defined period.
     * Explicitly cast to Map<String, Any> to avoid Kotlin type inference mismatches.
     */
    suspend fun getAppSpecificUsage(context: Context, packageName: String, days: Int): Map<String, Any> {
        return withContext(Dispatchers.IO) {
            try {
                // Ensure days is at least 1 to avoid division by zero
                val safeDays = if (days <= 0) 1 else days

                val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val calendar = Calendar.getInstance()

                val endTime = calendar.timeInMillis
                calendar.add(Calendar.DAY_OF_YEAR, -safeDays)
                val startTime = calendar.timeInMillis

                val usageStats = usageStatsManager.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    startTime,
                    endTime
                )

                // Filter stats for the specific package
                val appStats = usageStats?.filter { it.packageName == packageName }
                val totalUsage = appStats?.sumOf { it.totalTimeInForeground } ?: 0L
                val lastUsed = appStats?.maxOfOrNull { it.lastTimeUsed } ?: 0L

                // Daily breakdown formatting
                val dailyUsage = mutableMapOf<String, Long>()
                val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())

                appStats?.forEach { stats ->
                    val dayKey = dateFormat.format(Date(stats.lastTimeStamp))
                    dailyUsage[dayKey] = (dailyUsage[dayKey] ?: 0L) + stats.totalTimeInForeground
                }

                // Get app info (label/name) using your existing utility
                val appLabel = try {
                    val pm = context.packageManager
                    val info = pm.getApplicationInfo(packageName, 0)
                    pm.getApplicationLabel(info).toString()
                } catch (e: Exception) {
                    packageName
                }

                // EXPLICITLY type the map as <String, Any> to fix the return type mismatch
                mapOf<String, Any>(
                    "appName" to appLabel,
                    "packageName" to packageName,
                    "totalUsageMs" to totalUsage,
                    "totalUsageMinutes" to (totalUsage / 60000).toInt(),
                    "totalUsageHours" to (totalUsage / 3600000.0),
                    "averageDailyMs" to (totalUsage / safeDays),
                    "averageDailyMinutes" to ((totalUsage / safeDays) / 60000).toInt(),
                    "lastUsed" to lastUsed,
                    "dailyUsage" to dailyUsage,
                    "period" to mapOf<String, Any>(
                        "startTime" to startTime,
                        "endTime" to endTime,
                        "days" to safeDays
                    )
                )

            } catch (e: Exception) {
                Log.e("AppUtils", "Error getting app-specific usage for $packageName", e)
                // Return a fallback map typed as <String, Any>
                mapOf<String, Any>(
                    "appName" to packageName,
                    "packageName" to packageName,
                    "totalUsageMinutes" to 0,
                    "error" to (e.message ?: "Unknown error occurred")
                )
            }
        }
    }
    /**
     * Get usage patterns (hourly breakdown for today)
     */
    suspend fun getTodayUsagePatterns(context: Context): Map<String, Any> {
        return withContext(Dispatchers.IO) {
            try {
                val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

                // Get hourly stats for today
                val calendar = Calendar.getInstance()
                calendar. set(Calendar.HOUR_OF_DAY, 0)
                calendar.set(Calendar.MINUTE, 0)
                calendar.set(Calendar.SECOND, 0)
                calendar.set(Calendar.MILLISECOND, 0)
                val startTime = calendar. timeInMillis

                val endTime = System.currentTimeMillis()

                val usageStats = usageStatsManager.queryUsageStats(
                    UsageStatsManager.INTERVAL_BEST,
                    startTime,
                    endTime
                )

                // Create hourly breakdown
                val hourlyUsage = Array(24) { 0L }
                val currentHour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)

                usageStats?.forEach { stats ->
                    if (stats.totalTimeInForeground > 0) {
                        val hour = Calendar.getInstance().apply { timeInMillis = stats.lastTimeUsed }.get(Calendar. HOUR_OF_DAY)
                        if (hour in 0.. 23) {
                            hourlyUsage[hour] += stats.totalTimeInForeground
                        }
                    }
                }

                // Convert to list of maps for easier Flutter consumption
                val hourlyData = hourlyUsage.mapIndexed { hour, usage ->
                    mapOf(
                        "hour" to hour,
                        "usageMinutes" to (usage / 60000).toInt(),
                        "isCurrentHour" to (hour == currentHour)
                    )
                }

                val peakHour = hourlyUsage.withIndex().maxByOrNull { it.value }
                val totalUsage = hourlyUsage.sum()

                mapOf(
                    "hourlyUsage" to hourlyData,
                    "summary" to mapOf(
                        "totalUsageToday" to (totalUsage / 60000).toInt(),
                        "peakHour" to (peakHour?. index ?: 0),
                        "peakUsage" to ((peakHour?.value ?: 0L) / 60000).toInt(),
                        "currentHour" to currentHour
                    )
                )

            } catch (e: Exception) {
                Log.e(TAG, "Error getting usage patterns", e)
                mapOf(
                    "hourlyUsage" to emptyList<Map<String, Any>>(),
                    "summary" to mapOf(
                        "totalUsageToday" to 0,
                        "peakHour" to 0,
                        "peakUsage" to 0,
                        "currentHour" to Calendar.getInstance().get(Calendar.HOUR_OF_DAY),
                        "error" to e.message
                    )
                )
            }
        }
    }
}