package com.example.lock_in.managers

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import kotlinx.coroutines.*
import org.json.JSONArray
import org.json.JSONObject

/**
 * PermanentBlockManager - Manages permanently blocked apps
 * 
 * This manager handles apps that are blocked independently of focus sessions.
 * Permanently blocked apps are always blocked, not just during focus time.
 */
class PermanentBlockManager private constructor(private val context: Context) {
    
    companion object {
        private const val TAG = "PermanentBlockManager"
        private const val PREFS_NAME = "permanent_blocks"
        private const val KEY_BLOCKED_APPS = "blocked_apps"
        
        @Volatile
        private var instance: PermanentBlockManager? = null
        
        fun getInstance(context: Context): PermanentBlockManager {
            return instance ?: synchronized(this) {
                instance ?: PermanentBlockManager(context.applicationContext).also {
                    instance = it
                }
            }
        }
    }
    
    private val prefs: SharedPreferences = 
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    
    private var blockedApps: MutableSet<String> = mutableSetOf()
    
    init {
        loadBlockedApps()
    }
    
    /**
     * Load blocked apps from SharedPreferences
     */
    private fun loadBlockedApps() {
        try {
            val jsonString = prefs.getString(KEY_BLOCKED_APPS, "[]")
            val jsonArray = JSONArray(jsonString)
            
            blockedApps.clear()
            for (i in 0 until jsonArray.length()) {
                blockedApps.add(jsonArray.getString(i))
            }
            
            Log.i(TAG, "Loaded ${blockedApps.size} permanently blocked apps")
        } catch (e: Exception) {
            Log.e(TAG, "Error loading blocked apps", e)
            blockedApps.clear()
        }
    }
    
    /**
     * Save blocked apps to SharedPreferences
     */
    private fun saveBlockedApps() {
        try {
            val jsonArray = JSONArray(blockedApps.toList())
            prefs.edit()
                .putString(KEY_BLOCKED_APPS, jsonArray.toString())
                .apply()
            
            Log.i(TAG, "Saved ${blockedApps.size} permanently blocked apps")
        } catch (e: Exception) {
            Log.e(TAG, "Error saving blocked apps", e)
        }
    }
    
    /**
     * Set the complete list of permanently blocked apps
     */
    fun setBlockedApps(packageNames: Set<String>) {
        blockedApps = packageNames.toMutableSet()
        saveBlockedApps()
        Log.i(TAG, "Set permanently blocked apps: ${blockedApps.size} apps")
    }
    
    /**
     * Add a single app to permanent block list
     */
    fun addBlockedApp(packageName: String) {
        if (blockedApps.add(packageName)) {
            saveBlockedApps()
            Log.i(TAG, "Added permanently blocked app: $packageName")
        }
    }
    
    /**
     * Remove a single app from permanent block list
     */
    fun removeBlockedApp(packageName: String) {
        if (blockedApps.remove(packageName)) {
            saveBlockedApps()
            Log.i(TAG, "Removed permanently blocked app: $packageName")
        }
    }
    
    /**
     * Check if an app is permanently blocked
     */
    fun isAppBlocked(packageName: String): Boolean {
        return blockedApps.contains(packageName)
    }
    
    /**
     * Get all permanently blocked apps
     */
    fun getBlockedApps(): Set<String> {
        return blockedApps.toSet()
    }
    
    /**
     * Clear all permanently blocked apps
     */
    fun clearAllBlocks() {
        blockedApps.clear()
        saveBlockedApps()
        Log.i(TAG, "Cleared all permanently blocked apps")
    }
    
    /**
     * Get count of blocked apps
     */
    fun getBlockedAppsCount(): Int {
        return blockedApps.size
    }
}
