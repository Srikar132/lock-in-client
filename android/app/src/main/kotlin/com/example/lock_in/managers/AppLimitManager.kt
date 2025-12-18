package com.example.lock_in.managers

import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.concurrent.ConcurrentHashMap

/**
 * AppLimitManager - Tracks app usage time and enforces daily limits
 * 
 * Manages app time limits (e.g., 25 minutes per day) and tracks usage
 * Shows block overlay when limit is exceeded
 */
class AppLimitManager private constructor(private val context: Context) {
    
    companion object {
        private const val TAG = "AppLimitManager"
        private const val PREFS_NAME = "app_limits"
        private const val KEY_APP_LIMITS = "app_limits"
        private const val KEY_DAILY_USAGE = "daily_usage"
        private const val KEY_LAST_RESET_DATE = "last_reset_date"
        
        @Volatile
        private var instance: AppLimitManager? = null
        
        fun getInstance(context: Context): AppLimitManager {
            return instance ?: synchronized(this) {
                instance ?: AppLimitManager(context.applicationContext).also {
                    instance = it
                }
            }
        }
    }
    
    data class AppLimitData(
        val packageName: String,
        val limitMinutes: Int,
        val usedMinutes: Int = 0
    )
    
    private val prefs: SharedPreferences = 
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    
    private val usageStatsManager: UsageStatsManager = 
        context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    
    // App limits: Package name -> limit in minutes
    private val appLimits = ConcurrentHashMap<String, Int>()
    
    // Daily usage: Package name -> used minutes today
    private val dailyUsage = ConcurrentHashMap<String, Int>()
    
    // Track app usage during focus session (for backward compatibility)
    private val sessionUsageMap = ConcurrentHashMap<String, Long>()
    private var blockedApps: Set<String> = emptySet()
    
    init {
        loadAppLimits()
        loadDailyUsage()
        checkAndResetDaily()
    }
    
    /**
     * Load app limits from SharedPreferences
     */
    private fun loadAppLimits() {
        try {
            val jsonString = prefs.getString(KEY_APP_LIMITS, "[]")
            val jsonArray = JSONArray(jsonString)
            
            appLimits.clear()
            for (i in 0 until jsonArray.length()) {
                val jsonObj = jsonArray.getJSONObject(i)
                val packageName = jsonObj.getString("packageName")
                val limitMinutes = jsonObj.getInt("limitMinutes")
                appLimits[packageName] = limitMinutes
            }
            
            Log.i(TAG, "Loaded ${appLimits.size} app limits")
        } catch (e: Exception) {
            Log.e(TAG, "Error loading app limits", e)
            appLimits.clear()
        }
    }
    
    /**
     * Save app limits to SharedPreferences
     */
    private fun saveAppLimits() {
        try {
            val jsonArray = JSONArray()
            appLimits.forEach { (packageName, limitMinutes) ->
                val jsonObj = JSONObject().apply {
                    put("packageName", packageName)
                    put("limitMinutes", limitMinutes)
                }
                jsonArray.put(jsonObj)
            }
            
            prefs.edit()
                .putString(KEY_APP_LIMITS, jsonArray.toString())
                .apply()
            
            Log.i(TAG, "Saved ${appLimits.size} app limits")
        } catch (e: Exception) {
            Log.e(TAG, "Error saving app limits", e)
        }
    }
    
    /**
     * Load daily usage from SharedPreferences
     */
    private fun loadDailyUsage() {
        try {
            val jsonString = prefs.getString(KEY_DAILY_USAGE, "{}")
            val jsonObj = JSONObject(jsonString)
            
            dailyUsage.clear()
            jsonObj.keys().forEach { packageName ->
                val usedMinutes = jsonObj.getInt(packageName)
                dailyUsage[packageName] = usedMinutes
            }
            
            Log.i(TAG, "Loaded usage data for ${dailyUsage.size} apps")
        } catch (e: Exception) {
            Log.e(TAG, "Error loading daily usage", e)
            dailyUsage.clear()
        }
    }
    
    /**
     * Save daily usage to SharedPreferences
     */
    private fun saveDailyUsage() {
        try {
            val jsonObj = JSONObject()
            dailyUsage.forEach { (packageName, usedMinutes) ->
                jsonObj.put(packageName, usedMinutes)
            }
            
            prefs.edit()
                .putString(KEY_DAILY_USAGE, jsonObj.toString())
                .apply()
            
            Log.d(TAG, "Saved daily usage")
        } catch (e: Exception) {
            Log.e(TAG, "Error saving daily usage", e)
        }
    }
    
    /**
     * Check if it's a new day and reset usage if needed
     */
    private fun checkAndResetDaily() {
        val today = getTodayDateString()
        val lastResetDate = prefs.getString(KEY_LAST_RESET_DATE, "")
        
        if (today != lastResetDate) {
            Log.i(TAG, "New day detected, resetting daily usage")
            dailyUsage.clear()
            saveDailyUsage()
            
            prefs.edit()
                .putString(KEY_LAST_RESET_DATE, today)
                .apply()
        }
    }
    
    /**
     * Get today's date as string (YYYY-MM-DD)
     */
    private fun getTodayDateString(): String {
        val calendar = Calendar.getInstance()
        return "${calendar.get(Calendar.YEAR)}-${calendar.get(Calendar.MONTH) + 1}-${calendar.get(Calendar.DAY_OF_MONTH)}"
    }
    
    /**
     * Set time limit for a specific app (in minutes)
     */
    fun setAppLimit(packageName: String, limitMinutes: Int) {
        appLimits[packageName] = limitMinutes
        saveAppLimits()
        Log.i(TAG, "Set limit for $packageName: $limitMinutes minutes")
    }
    
    /**
     * Remove app limit
     */
    fun removeAppLimit(packageName: String) {
        appLimits.remove(packageName)
        dailyUsage.remove(packageName)
        saveAppLimits()
        saveDailyUsage()
        Log.i(TAG, "Removed limit for $packageName")
    }
    
    /**
     * Get app limit in minutes
     */
    fun getAppLimit(packageName: String): Int? {
        return appLimits[packageName]
    }
    
    /**
     * Get today's usage for an app in minutes
     */
    fun getTodayUsage(packageName: String): Int {
        checkAndResetDaily()
        
        // Get real usage from UsageStatsManager
        val realUsage = getRealUsageToday(packageName)
        
        // Update stored usage if real usage is higher
        val storedUsage = dailyUsage.getOrDefault(packageName, 0)
        if (realUsage > storedUsage) {
            dailyUsage[packageName] = realUsage
            saveDailyUsage()
        }
        
        return dailyUsage.getOrDefault(packageName, 0)
    }
    
    /**
     * Get real usage from Android UsageStatsManager
     */
    private fun getRealUsageToday(packageName: String): Int {
        try {
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()
            
            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            
            val stats = usageStatsList?.find { it.packageName == packageName }
            val usageMillis = stats?.totalTimeInForeground ?: 0L
            return (usageMillis / 60000).toInt() // Convert to minutes
        } catch (e: Exception) {
            Log.e(TAG, "Error getting real usage for $packageName", e)
            return 0
        }
    }
    
    /**
     * Check if app has exceeded its limit
     */
    fun hasExceededLimit(packageName: String): Boolean {
        val limit = appLimits[packageName] ?: return false
        val usage = getTodayUsage(packageName)
        
        val exceeded = usage >= limit
        if (exceeded) {
            Log.w(TAG, "App $packageName exceeded limit: $usage min / $limit min")
        }
        return exceeded
    }
    
    /**
     * Get remaining time for an app in minutes
     */
    fun getRemainingTime(packageName: String): Int {
        val limit = appLimits[packageName] ?: return -1
        val usage = getTodayUsage(packageName)
        val remaining = limit - usage
        return if (remaining > 0) remaining else 0
    }
    
    /**
     * Check if app has a limit set
     */
    fun hasAppLimit(packageName: String): Boolean {
        return appLimits.containsKey(packageName)
    }
    
    /**
     * Get all app limits
     */
    fun getAllAppLimits(): List<AppLimitData> {
        checkAndResetDaily()
        return appLimits.map { (packageName, limitMinutes) ->
            AppLimitData(
                packageName = packageName,
                limitMinutes = limitMinutes,
                usedMinutes = getTodayUsage(packageName)
            )
        }
    }
    
    /**
     * Reset daily usage (called at midnight)
     */
    fun resetDailyUsage() {
        Log.i(TAG, "Resetting daily usage")
        dailyUsage.clear()
        saveDailyUsage()
        
        val today = getTodayDateString()
        prefs.edit()
            .putString(KEY_LAST_RESET_DATE, today)
            .apply()
    }
    
    /**
     * Update usage for an app (increment by minutes)
     */
    fun incrementUsage(packageName: String, additionalMinutes: Int) {
        val current = dailyUsage.getOrDefault(packageName, 0)
        dailyUsage[packageName] = current + additionalMinutes
        saveDailyUsage()
        Log.d(TAG, "Incremented usage for $packageName: $additionalMinutes min (total: ${dailyUsage[packageName]} min)")
    }
    
    // ==================== BACKWARD COMPATIBILITY FOR FOCUS MODE ====================
    
    /**
     * Set the list of blocked apps for the current session
     */
    fun setBlockedApps(packages: Set<String>) {
        Log.i(TAG, "Setting blocked apps: ${packages.size} apps")
        blockedApps = packages.toSet()
        sessionUsageMap.clear()
    }
    
    /**
     * Clear all blocked apps
     */
    fun clearBlockedApps() {
        Log.i(TAG, "Clearing blocked apps")
        blockedApps = emptySet()
        sessionUsageMap.clear()
    }
    
    /**
     * Check if an app is currently blocked (focus mode)
     */
    fun isAppBlocked(packageName: String): Boolean {
        return blockedApps.contains(packageName)
    }
    
    /**
     * Track usage of an app (focus mode)
     */
    fun trackAppUsage(packageName: String, durationMillis: Long) {
        val currentUsage = sessionUsageMap.getOrDefault(packageName, 0L)
        sessionUsageMap[packageName] = currentUsage + durationMillis
        
        Log.d(TAG, "Tracked usage for $packageName: ${sessionUsageMap[packageName]}ms")
    }
    
    /**
     * Get session usage statistics (focus mode)
     */
    fun getSessionStats(): Map<String, Long> {
        return sessionUsageMap.toMap()
    }
    
    /**
     * Get the current foreground app package name
     */
    fun getCurrentForegroundApp(): String? {
        try {
            val endTime = System.currentTimeMillis()
            val startTime = endTime - 1000 // Last 1 second
            
            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            
            if (usageStatsList.isNullOrEmpty()) {
                return null
            }
            
            // Sort by last time used and get the most recent
            val sortedStats = usageStatsList
                .filter { it.lastTimeUsed > 0 }
                .sortedByDescending { it.lastTimeUsed }
            
            return sortedStats.firstOrNull()?.packageName
        } catch (e: Exception) {
            Log.e(TAG, "Error getting foreground app", e)
            return null
        }
    }
    
    /**
     * Get app usage time for a specific package during current session
     */
    fun getAppUsageTime(packageName: String, startTime: Long): Long {
        try {
            val endTime = System.currentTimeMillis()
            
            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            
            val stats = usageStatsList?.find { it.packageName == packageName }
            return stats?.totalTimeInForeground ?: 0L
        } catch (e: Exception) {
            Log.e(TAG, "Error getting usage time for $packageName", e)
            return 0L
        }
    }
    
    /**
     * Get all app usage stats for today
     */
    fun getTodayUsageStats(): List<UsageStats> {
        try {
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()
            
            return usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )?.filter { it.totalTimeInForeground > 0 } ?: emptyList()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting today's usage stats", e)
            return emptyList()
        }
    }
}
