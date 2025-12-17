package com.example.lock_in.focus

import android.content.Context
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

/**
 * Singleton FocusModeManager that serves as the central coordinator for all focus mode operations.
 * 
 * Features:
 * - Thread-safe singleton pattern
 * - Session management (start/pause/resume/end)
 * - Timer management for different modes (Timer/Stopwatch/Pomodoro)
 * - Event broadcasting to Flutter via EventChannel
 * - Service coordination for all blocking services
 * - Persistent session storage using SharedPreferences
 */
class FocusModeManager private constructor(private val context: Context) {

    companion object {
        private const val TAG = "FocusModeManager"
        private const val PREFS_NAME = "focus_mode_prefs"
        private const val KEY_SESSION_DATA = "current_session_data"
        private const val KEY_SESSION_STATE = "current_session_state"
        
        @Volatile
        private var instance: FocusModeManager? = null
        
        /**
         * Thread-safe singleton instance getter
         */
        fun getInstance(context: Context): FocusModeManager {
            return instance ?: synchronized(this) {
                instance ?: FocusModeManager(context.applicationContext).also {
                    instance = it
                }
            }
        }
    }
    
    // SharedPreferences for persistent storage
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    
    // Coroutine scope for async operations
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    
    // Handler for main thread operations
    private val mainHandler = Handler(Looper.getMainLooper())
    
    // Current session state (thread-safe)
    private val currentSession = AtomicReference<SessionState?>(null)
    
    // Session active flag (thread-safe)
    private val isSessionActive = AtomicBoolean(false)
    
    // Timer job reference
    private var timerJob: Job? = null
    
    // Event channel sink for broadcasting to Flutter
    private var eventSink: EventChannel.EventSink? = null
    
    init {
        Log.d(TAG, "FocusModeManager initialized")
        // Restore session from persistent storage if exists
        restoreSessionFromPrefs()
    }
    
    /**
     * Set the EventChannel sink for broadcasting events to Flutter
     */
    fun setEventSink(sink: EventChannel.EventSink?) {
        synchronized(this) {
            eventSink = sink
            Log.d(TAG, "EventSink ${if (sink != null) "connected" else "disconnected"}")
        }
    }
    
    /**
     * Start a new focus session
     * 
     * @param sessionData Session configuration data
     * @return Success status
     */
    fun startSession(sessionData: SessionData): Result<Boolean> {
        return try {
            synchronized(this) {
                if (isSessionActive.get()) {
                    return Result.failure(IllegalStateException("Session already active"))
                }
                
                Log.d(TAG, "Starting session: ${sessionData.sessionType}")
                
                // Create new session state
                val sessionState = SessionState(
                    sessionId = generateSessionId(),
                    sessionData = sessionData,
                    status = SessionStatus.ACTIVE,
                    startTime = System.currentTimeMillis(),
                    elapsedTime = 0L,
                    pausedTime = 0L
                )
                
                currentSession.set(sessionState)
                isSessionActive.set(true)
                
                // Save to persistent storage
                saveSessionToPrefs(sessionState)
                
                // Start timer based on session type
                startTimer(sessionState)
                
                // Activate blocking services
                activateBlockingServices(sessionData)
                
                // Broadcast session started event
                broadcastEvent(mapOf(
                    "type" to "SESSION_STARTED",
                    "sessionId" to sessionState.sessionId,
                    "sessionType" to sessionData.sessionType.name,
                    "plannedDuration" to sessionData.plannedDuration
                ))
                
                Log.d(TAG, "Session started successfully: ${sessionState.sessionId}")
                Result.success(true)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting session", e)
            Result.failure(e)
        }
    }
    
    /**
     * Pause the current session
     * 
     * @return Success status
     */
    fun pauseSession(): Result<Boolean> {
        return try {
            synchronized(this) {
                val session = currentSession.get()
                    ?: return Result.failure(IllegalStateException("No active session"))
                
                if (session.status != SessionStatus.ACTIVE) {
                    return Result.failure(IllegalStateException("Session is not active"))
                }
                
                Log.d(TAG, "Pausing session: ${session.sessionId}")
                
                // Stop timer
                stopTimer()
                
                // Update session state
                val pausedSession = session.copy(
                    status = SessionStatus.PAUSED,
                    pausedTime = System.currentTimeMillis()
                )
                
                currentSession.set(pausedSession)
                
                // Save to persistent storage
                saveSessionToPrefs(pausedSession)
                
                // Deactivate blocking services temporarily
                deactivateBlockingServices()
                
                // Broadcast paused event
                broadcastEvent(mapOf(
                    "type" to "SESSION_PAUSED",
                    "sessionId" to session.sessionId,
                    "elapsedTime" to session.elapsedTime
                ))
                
                Log.d(TAG, "Session paused successfully")
                Result.success(true)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error pausing session", e)
            Result.failure(e)
        }
    }
    
    /**
     * Resume the paused session
     * 
     * @return Success status
     */
    fun resumeSession(): Result<Boolean> {
        return try {
            synchronized(this) {
                val session = currentSession.get()
                    ?: return Result.failure(IllegalStateException("No session to resume"))
                
                if (session.status != SessionStatus.PAUSED) {
                    return Result.failure(IllegalStateException("Session is not paused"))
                }
                
                Log.d(TAG, "Resuming session: ${session.sessionId}")
                
                // Calculate pause duration
                val pauseDuration = if (session.pausedTime > 0) {
                    System.currentTimeMillis() - session.pausedTime
                } else {
                    0L
                }
                
                // Update session state
                val resumedSession = session.copy(
                    status = SessionStatus.ACTIVE,
                    startTime = session.startTime + pauseDuration,
                    pausedTime = 0L
                )
                
                currentSession.set(resumedSession)
                
                // Save to persistent storage
                saveSessionToPrefs(resumedSession)
                
                // Restart timer
                startTimer(resumedSession)
                
                // Reactivate blocking services
                activateBlockingServices(session.sessionData)
                
                // Broadcast resumed event
                broadcastEvent(mapOf(
                    "type" to "SESSION_RESUMED",
                    "sessionId" to session.sessionId
                ))
                
                Log.d(TAG, "Session resumed successfully")
                Result.success(true)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error resuming session", e)
            Result.failure(e)
        }
    }
    
    /**
     * End the current session
     * 
     * @return Session statistics
     */
    fun endSession(): Result<SessionStats> {
        return try {
            synchronized(this) {
                val session = currentSession.get()
                    ?: return Result.failure(IllegalStateException("No active session"))
                
                Log.d(TAG, "Ending session: ${session.sessionId}")
                
                // Stop timer
                stopTimer()
                
                // Calculate final statistics
                val endTime = System.currentTimeMillis()
                val totalDuration = endTime - session.startTime
                val stats = SessionStats(
                    sessionId = session.sessionId,
                    sessionType = session.sessionData.sessionType,
                    plannedDuration = session.sessionData.plannedDuration,
                    actualDuration = session.elapsedTime,
                    completionRate = calculateCompletionRate(session),
                    startTime = session.startTime,
                    endTime = endTime,
                    interruptions = 0 // TODO: Track interruptions
                )
                
                // Deactivate blocking services
                deactivateBlockingServices()
                
                // Clear session state
                currentSession.set(null)
                isSessionActive.set(false)
                
                // Clear from persistent storage
                clearSessionFromPrefs()
                
                // Broadcast session ended event
                broadcastEvent(mapOf(
                    "type" to "SESSION_ENDED",
                    "sessionId" to session.sessionId,
                    "stats" to mapOf(
                        "plannedDuration" to stats.plannedDuration,
                        "actualDuration" to stats.actualDuration,
                        "completionRate" to stats.completionRate
                    )
                ))
                
                Log.d(TAG, "Session ended successfully. Duration: ${stats.actualDuration}ms")
                Result.success(stats)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error ending session", e)
            Result.failure(e)
        }
    }
    
    /**
     * Get the current session status
     * 
     * @return Current session state or null if no active session
     */
    fun getCurrentSessionStatus(): SessionState? {
        return currentSession.get()?.copy() // Return a copy to prevent external modification
    }
    
    /**
     * Check if a session is currently active
     */
    fun isSessionRunning(): Boolean {
        return isSessionActive.get()
    }
    
    // ==================== Timer Management ====================
    
    /**
     * Start the timer based on session type
     */
    private fun startTimer(session: SessionState) {
        // Cancel any existing timer
        stopTimer()
        
        timerJob = scope.launch {
            try {
                when (session.sessionData.sessionType) {
                    SessionType.TIMER -> runTimerMode(session)
                    SessionType.STOPWATCH -> runStopwatchMode(session)
                    SessionType.POMODORO -> runPomodoroMode(session)
                }
            } catch (e: CancellationException) {
                Log.d(TAG, "Timer cancelled")
            } catch (e: Exception) {
                Log.e(TAG, "Error in timer", e)
            }
        }
    }
    
    /**
     * Stop the current timer
     */
    private fun stopTimer() {
        timerJob?.cancel()
        timerJob = null
    }
    
    /**
     * Timer Mode: Fixed duration with auto-completion
     */
    private suspend fun runTimerMode(session: SessionState) {
        val plannedDuration = session.sessionData.plannedDuration
        val startTime = System.currentTimeMillis()
        
        while (isActive && isSessionActive.get()) {
            val elapsed = System.currentTimeMillis() - startTime + session.elapsedTime
            
            // Update elapsed time in session
            currentSession.get()?.let { current ->
                currentSession.set(current.copy(elapsedTime = elapsed))
            }
            
            // Broadcast timer update
            broadcastTimerUpdate(elapsed, plannedDuration)
            
            // Check if timer completed
            if (elapsed >= plannedDuration) {
                handleTimerCompletion(session)
                break
            }
            
            delay(1000) // Update every second
        }
    }
    
    /**
     * Stopwatch Mode: Unlimited duration, manual stop
     */
    private suspend fun runStopwatchMode(session: SessionState) {
        val startTime = System.currentTimeMillis()
        
        while (isActive && isSessionActive.get()) {
            val elapsed = System.currentTimeMillis() - startTime + session.elapsedTime
            
            // Update elapsed time in session
            currentSession.get()?.let { current ->
                currentSession.set(current.copy(elapsedTime = elapsed))
            }
            
            // Broadcast timer update (no planned duration for stopwatch)
            broadcastTimerUpdate(elapsed, 0L)
            
            delay(1000) // Update every second
        }
    }
    
    /**
     * Pomodoro Mode: Work/break cycles
     * 25min work, 5min short break, 15min long break (after 4 cycles)
     */
    private suspend fun runPomodoroMode(session: SessionState) {
        val workDuration = 25 * 60 * 1000L // 25 minutes
        val shortBreakDuration = 5 * 60 * 1000L // 5 minutes
        val longBreakDuration = 15 * 60 * 1000L // 15 minutes
        val cyclesBeforeLongBreak = 4
        
        var cycleCount = 0
        var isWorkPhase = true
        var phaseStartTime = System.currentTimeMillis()
        
        while (isActive && isSessionActive.get()) {
            val elapsed = System.currentTimeMillis() - phaseStartTime
            val phaseDuration = if (isWorkPhase) {
                workDuration
            } else {
                if (cycleCount % cyclesBeforeLongBreak == 0 && cycleCount > 0) {
                    longBreakDuration
                } else {
                    shortBreakDuration
                }
            }
            
            // Update total elapsed time
            val totalElapsed = currentSession.get()?.elapsedTime?.plus(elapsed) ?: elapsed
            currentSession.get()?.let { current ->
                currentSession.set(current.copy(elapsedTime = totalElapsed))
            }
            
            // Broadcast pomodoro update
            broadcastPomodoroUpdate(elapsed, phaseDuration, isWorkPhase, cycleCount)
            
            // Check if phase completed
            if (elapsed >= phaseDuration) {
                if (isWorkPhase) {
                    cycleCount++
                }
                
                // Switch phase
                isWorkPhase = !isWorkPhase
                phaseStartTime = System.currentTimeMillis()
                
                // Broadcast phase change
                broadcastEvent(mapOf(
                    "type" to "POMODORO_PHASE_CHANGE",
                    "isWorkPhase" to isWorkPhase,
                    "cycleCount" to cycleCount
                ))
            }
            
            delay(1000) // Update every second
        }
    }
    
    /**
     * Handle timer completion
     */
    private fun handleTimerCompletion(session: SessionState) {
        Log.d(TAG, "Timer completed for session: ${session.sessionId}")
        
        broadcastEvent(mapOf(
            "type" to "TIMER_COMPLETED",
            "sessionId" to session.sessionId
        ))
        
        // Note: Don't auto-end the session here, let the user decide
        // They might want to continue or review stats first
    }
    
    // ==================== Event Broadcasting ====================
    
    /**
     * Broadcast timer update to Flutter
     */
    private fun broadcastTimerUpdate(elapsed: Long, planned: Long) {
        broadcastEvent(mapOf(
            "type" to "TIMER_UPDATE",
            "elapsed" to elapsed,
            "planned" to planned,
            "remaining" to if (planned > 0) maxOf(0, planned - elapsed) else 0
        ))
    }
    
    /**
     * Broadcast Pomodoro update to Flutter
     */
    private fun broadcastPomodoroUpdate(elapsed: Long, phaseDuration: Long, isWorkPhase: Boolean, cycleCount: Int) {
        broadcastEvent(mapOf(
            "type" to "POMODORO_UPDATE",
            "elapsed" to elapsed,
            "phaseDuration" to phaseDuration,
            "remaining" to maxOf(0, phaseDuration - elapsed),
            "isWorkPhase" to isWorkPhase,
            "cycleCount" to cycleCount
        ))
    }
    
    /**
     * Broadcast generic event to Flutter
     */
    private fun broadcastEvent(event: Map<String, Any>) {
        mainHandler.post {
            try {
                eventSink?.success(event)
            } catch (e: Exception) {
                Log.e(TAG, "Error broadcasting event", e)
            }
        }
    }
    
    // ==================== Service Coordination ====================
    
    /**
     * Activate all blocking services based on session configuration
     */
    private fun activateBlockingServices(sessionData: SessionData) {
        scope.launch {
            try {
                Log.d(TAG, "Activating blocking services")
                
                // TODO: Start AppMonitoringService
                // This will be implemented when the service is created
                
                // TODO: Configure ShortFormBlockingService
                // Block short-form content based on session settings
                
                // TODO: Activate WebBlockingVPNService
                // Block distracting websites if configured
                
                // TODO: Setup NotificationBlockingService
                // Block notifications during focus session
                
                broadcastEvent(mapOf(
                    "type" to "SERVICES_ACTIVATED"
                ))
                
                Log.d(TAG, "Blocking services activated")
            } catch (e: Exception) {
                Log.e(TAG, "Error activating services", e)
                broadcastEvent(mapOf(
                    "type" to "SERVICES_ERROR",
                    "error" to e.message
                ))
            }
        }
    }
    
    /**
     * Deactivate all blocking services
     */
    private fun deactivateBlockingServices() {
        scope.launch {
            try {
                Log.d(TAG, "Deactivating blocking services")
                
                // TODO: Stop AppMonitoringService
                // TODO: Disable ShortFormBlockingService
                // TODO: Deactivate WebBlockingVPNService
                // TODO: Remove NotificationBlockingService
                
                broadcastEvent(mapOf(
                    "type" to "SERVICES_DEACTIVATED"
                ))
                
                Log.d(TAG, "Blocking services deactivated")
            } catch (e: Exception) {
                Log.e(TAG, "Error deactivating services", e)
            }
        }
    }
    
    // ==================== Persistent Storage ====================
    
    /**
     * Save session to SharedPreferences
     */
    private fun saveSessionToPrefs(session: SessionState) {
        try {
            val editor = prefs.edit()
            editor.putString(KEY_SESSION_DATA, session.toJson())
            editor.putString(KEY_SESSION_STATE, session.status.name)
            editor.apply()
            Log.d(TAG, "Session saved to preferences")
        } catch (e: Exception) {
            Log.e(TAG, "Error saving session to preferences", e)
        }
    }
    
    /**
     * Restore session from SharedPreferences
     */
    private fun restoreSessionFromPrefs() {
        try {
            val sessionJson = prefs.getString(KEY_SESSION_DATA, null)
            if (sessionJson != null) {
                val session = SessionState.fromJson(sessionJson)
                currentSession.set(session)
                isSessionActive.set(session.status == SessionStatus.ACTIVE)
                
                Log.d(TAG, "Session restored from preferences: ${session.sessionId}")
                
                // If session was active, restart timer
                if (session.status == SessionStatus.ACTIVE) {
                    startTimer(session)
                    activateBlockingServices(session.sessionData)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error restoring session from preferences", e)
        }
    }
    
    /**
     * Clear session from SharedPreferences
     */
    private fun clearSessionFromPrefs() {
        try {
            prefs.edit().clear().apply()
            Log.d(TAG, "Session cleared from preferences")
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing session from preferences", e)
        }
    }
    
    // ==================== Helper Methods ====================
    
    /**
     * Generate unique session ID
     */
    private fun generateSessionId(): String {
        return "session_${System.currentTimeMillis()}_${(0..9999).random()}"
    }
    
    /**
     * Calculate completion rate for a session
     */
    private fun calculateCompletionRate(session: SessionState): Double {
        return if (session.sessionData.plannedDuration > 0) {
            (session.elapsedTime.toDouble() / session.sessionData.plannedDuration.toDouble() * 100.0)
                .coerceIn(0.0, 100.0)
        } else {
            100.0 // Stopwatch mode always returns 100%
        }
    }
    
    /**
     * Cleanup resources
     */
    fun cleanup() {
        Log.d(TAG, "Cleaning up FocusModeManager")
        stopTimer()
        scope.cancel()
        eventSink = null
    }
}

// ==================== Data Classes ====================

/**
 * Session configuration data
 */
data class SessionData(
    val sessionType: SessionType,
    val plannedDuration: Long, // in milliseconds (0 for stopwatch mode)
    val userId: String,
    val blockedApps: List<String> = emptyList(),
    val blockedWebsites: List<String> = emptyList(),
    val blockNotifications: Boolean = true,
    val allowBreaks: Boolean = false
) {
    fun toMap(): Map<String, Any> {
        return mapOf(
            "sessionType" to sessionType.name,
            "plannedDuration" to plannedDuration,
            "userId" to userId,
            "blockedApps" to blockedApps,
            "blockedWebsites" to blockedWebsites,
            "blockNotifications" to blockNotifications,
            "allowBreaks" to allowBreaks
        )
    }
    
    companion object {
        fun fromMap(map: Map<String, Any>): SessionData {
            return SessionData(
                sessionType = SessionType.valueOf(map["sessionType"] as String),
                plannedDuration = (map["plannedDuration"] as Number).toLong(),
                userId = map["userId"] as String,
                blockedApps = (map["blockedApps"] as? List<*>)?.filterIsInstance<String>() ?: emptyList(),
                blockedWebsites = (map["blockedWebsites"] as? List<*>)?.filterIsInstance<String>() ?: emptyList(),
                blockNotifications = map["blockNotifications"] as? Boolean ?: true,
                allowBreaks = map["allowBreaks"] as? Boolean ?: false
            )
        }
    }
}

/**
 * Session state data
 */
data class SessionState(
    val sessionId: String,
    val sessionData: SessionData,
    val status: SessionStatus,
    val startTime: Long,
    val elapsedTime: Long,
    val pausedTime: Long
) {
    fun toJson(): String {
        // Simple JSON serialization
        return """
            {
                "sessionId": "$sessionId",
                "status": "${status.name}",
                "startTime": $startTime,
                "elapsedTime": $elapsedTime,
                "pausedTime": $pausedTime,
                "sessionData": {
                    "sessionType": "${sessionData.sessionType.name}",
                    "plannedDuration": ${sessionData.plannedDuration},
                    "userId": "${sessionData.userId}",
                    "blockNotifications": ${sessionData.blockNotifications},
                    "allowBreaks": ${sessionData.allowBreaks}
                }
            }
        """.trimIndent()
    }
    
    companion object {
        fun fromJson(json: String): SessionState {
            // Simple JSON deserialization - in production, use a proper JSON library
            // This is a basic implementation for demonstration
            val sessionIdRegex = """"sessionId":\s*"([^"]+)"""".toRegex()
            val statusRegex = """"status":\s*"([^"]+)"""".toRegex()
            val startTimeRegex = """"startTime":\s*(\d+)""".toRegex()
            val elapsedTimeRegex = """"elapsedTime":\s*(\d+)""".toRegex()
            val pausedTimeRegex = """"pausedTime":\s*(\d+)""".toRegex()
            val sessionTypeRegex = """"sessionType":\s*"([^"]+)"""".toRegex()
            val plannedDurationRegex = """"plannedDuration":\s*(\d+)""".toRegex()
            val userIdRegex = """"userId":\s*"([^"]+)"""".toRegex()
            
            return SessionState(
                sessionId = sessionIdRegex.find(json)?.groupValues?.get(1) ?: "",
                status = SessionStatus.valueOf(statusRegex.find(json)?.groupValues?.get(1) ?: "ACTIVE"),
                startTime = startTimeRegex.find(json)?.groupValues?.get(1)?.toLong() ?: 0L,
                elapsedTime = elapsedTimeRegex.find(json)?.groupValues?.get(1)?.toLong() ?: 0L,
                pausedTime = pausedTimeRegex.find(json)?.groupValues?.get(1)?.toLong() ?: 0L,
                sessionData = SessionData(
                    sessionType = SessionType.valueOf(sessionTypeRegex.find(json)?.groupValues?.get(1) ?: "TIMER"),
                    plannedDuration = plannedDurationRegex.find(json)?.groupValues?.get(1)?.toLong() ?: 0L,
                    userId = userIdRegex.find(json)?.groupValues?.get(1) ?: ""
                )
            )
        }
    }
}

/**
 * Session statistics after completion
 */
data class SessionStats(
    val sessionId: String,
    val sessionType: SessionType,
    val plannedDuration: Long,
    val actualDuration: Long,
    val completionRate: Double,
    val startTime: Long,
    val endTime: Long,
    val interruptions: Int
) {
    fun toMap(): Map<String, Any> {
        return mapOf(
            "sessionId" to sessionId,
            "sessionType" to sessionType.name,
            "plannedDuration" to plannedDuration,
            "actualDuration" to actualDuration,
            "completionRate" to completionRate,
            "startTime" to startTime,
            "endTime" to endTime,
            "interruptions" to interruptions
        )
    }
}

/**
 * Session type enumeration
 */
enum class SessionType {
    TIMER,      // Fixed duration with auto-completion
    STOPWATCH,  // Unlimited duration, manual stop
    POMODORO    // Work/break cycles
}

/**
 * Session status enumeration
 */
enum class SessionStatus {
    ACTIVE,     // Session is running
    PAUSED,     // Session is temporarily paused
    COMPLETED,  // Session has completed successfully
    CANCELLED   // Session was cancelled
}
