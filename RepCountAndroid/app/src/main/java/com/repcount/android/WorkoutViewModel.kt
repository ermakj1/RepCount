package com.repcount.android

import android.app.Application
import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

enum class WorkoutScreen {
    SETUP,
    ACTIVE,
    REST,
    SUMMARY
}

data class WorkoutState(
    // Setup
    val targetReps: Int = 10,
    val restSeconds: Int = 60,
    val targetTotalReps: Int = 100,

    // Workout state
    val currentScreen: WorkoutScreen = WorkoutScreen.SETUP,
    val currentSetNumber: Int = 1,
    val completedSets: List<Int> = emptyList(),
    val elapsedSeconds: Int = 0,

    // Rest timer
    val restTimeRemaining: Int = 0,

    // Pause state
    val isPaused: Boolean = false,

    // Summary
    val summaryTotalReps: Int = 0,
    val summaryElapsedTime: Int = 0,
    val summarySetsCompleted: Int = 0
) {
    val completedReps: Int get() = completedSets.sum()
    val progressPercent: Float get() = if (targetTotalReps > 0) {
        (completedReps.toFloat() / targetTotalReps).coerceAtMost(1f)
    } else 0f
    val isGoalComplete: Boolean get() = completedReps >= targetTotalReps
}

class WorkoutViewModel(application: Application) : AndroidViewModel(application) {

    private val prefs = application.getSharedPreferences("repcount_prefs", Context.MODE_PRIVATE)

    // Haptics
    private val vibrator: Vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val vibratorManager = application.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
        vibratorManager.defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        application.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    }

    private val _state = MutableStateFlow(WorkoutState())
    val state: StateFlow<WorkoutState> = _state.asStateFlow()

    private var elapsedTimerJob: Job? = null
    private var restTimerJob: Job? = null

    // Timer precision: track elapsed time using system time snapshots
    private var elapsedStartTime: Long = 0L
    private var accumulatedElapsed: Long = 0L

    // Timer precision: track rest timer using system time snapshots
    private var restStartTime: Long = 0L
    private var restTargetSeconds: Int = 0

    // Pause state
    private var pausedRestTimeRemaining: Int = 0

    init {
        loadSettings()
    }

    // MARK: - Settings

    fun setTargetReps(value: Int) {
        if (value >= 1) {
            _state.value = _state.value.copy(targetReps = value)
        }
    }

    fun setRestSeconds(value: Int) {
        if (value >= 1) {
            _state.value = _state.value.copy(restSeconds = value)
        }
    }

    fun setTargetTotalReps(value: Int) {
        if (value >= 1) {
            _state.value = _state.value.copy(targetTotalReps = value)
        }
    }

    // MARK: - Workout Session

    fun startWorkout() {
        saveSettings()
        accumulatedElapsed = 0L
        _state.value = _state.value.copy(
            currentScreen = WorkoutScreen.ACTIVE,
            currentSetNumber = 1,
            completedSets = emptyList(),
            elapsedSeconds = 0
        )
        playHeavyHaptic()
        startElapsedTimer()
    }

    fun completeSet(reps: Int) {
        val newSets = _state.value.completedSets + reps
        _state.value = _state.value.copy(
            completedSets = newSets,
            currentScreen = WorkoutScreen.REST,
            restTimeRemaining = _state.value.restSeconds
        )
        playHeavyHaptic()
        startRestTimer()
    }

    fun endWorkout() {
        stopElapsedTimer()
        stopRestTimer()

        val currentState = _state.value
        _state.value = currentState.copy(
            currentScreen = WorkoutScreen.SUMMARY,
            summaryTotalReps = currentState.completedReps,
            summaryElapsedTime = currentState.elapsedSeconds,
            summarySetsCompleted = currentState.completedSets.size
        )
    }

    fun dismissSummary() {
        _state.value = _state.value.copy(
            currentScreen = WorkoutScreen.SETUP,
            currentSetNumber = 1,
            completedSets = emptyList(),
            elapsedSeconds = 0,
            summaryTotalReps = 0,
            summaryElapsedTime = 0,
            summarySetsCompleted = 0
        )
    }

    // MARK: - Rest Timer

    fun skipRest() {
        stopRestTimer()
        _state.value = _state.value.copy(
            currentScreen = WorkoutScreen.ACTIVE,
            currentSetNumber = _state.value.currentSetNumber + 1,
            restTimeRemaining = 0
        )
    }

    fun addRestTime(seconds: Int) {
        _state.value = _state.value.copy(
            restTimeRemaining = _state.value.restTimeRemaining + seconds,
            restSeconds = _state.value.restSeconds + seconds
        )
        saveSettings()
    }

    private fun startRestTimer() {
        stopRestTimer()
        restStartTime = System.currentTimeMillis()
        restTargetSeconds = _state.value.restTimeRemaining

        restTimerJob = viewModelScope.launch {
            var previousRemaining = restTargetSeconds
            while (true) {
                delay(500)
                val elapsed = (System.currentTimeMillis() - restStartTime) / 1000
                val remaining = (restTargetSeconds - elapsed.toInt()).coerceAtLeast(0)

                if (remaining > 0) {
                    _state.value = _state.value.copy(restTimeRemaining = remaining)
                    // Haptic feedback for last 3 seconds (only trigger once per second)
                    if (remaining <= 3 && remaining != previousRemaining) {
                        playMediumHaptic()
                    }
                    previousRemaining = remaining
                } else {
                    // Rest complete
                    playHeavyHaptic()
                    _state.value = _state.value.copy(
                        restTimeRemaining = 0,
                        currentScreen = WorkoutScreen.ACTIVE,
                        currentSetNumber = _state.value.currentSetNumber + 1
                    )
                    break
                }
            }
        }
    }

    private fun stopRestTimer() {
        restTimerJob?.cancel()
        restTimerJob = null
        restStartTime = 0L
        restTargetSeconds = 0
    }

    // MARK: - Elapsed Timer

    private fun startElapsedTimer() {
        stopElapsedTimer()
        elapsedStartTime = System.currentTimeMillis()

        elapsedTimerJob = viewModelScope.launch {
            while (true) {
                delay(500)
                val currentElapsed = (System.currentTimeMillis() - elapsedStartTime) / 1000 + accumulatedElapsed / 1000
                _state.value = _state.value.copy(elapsedSeconds = currentElapsed.toInt())
            }
        }
    }

    private fun stopElapsedTimer() {
        // Accumulate elapsed time before stopping
        if (elapsedStartTime > 0) {
            accumulatedElapsed += System.currentTimeMillis() - elapsedStartTime
        }
        elapsedStartTime = 0L
        elapsedTimerJob?.cancel()
        elapsedTimerJob = null
    }

    // MARK: - Pause/Resume

    fun pauseWorkout() {
        if (_state.value.isPaused) return
        _state.value = _state.value.copy(isPaused = true)

        // Stop elapsed timer (accumulates time automatically)
        stopElapsedTimer()

        // If resting, save remaining time and stop rest timer
        if (_state.value.currentScreen == WorkoutScreen.REST) {
            pausedRestTimeRemaining = _state.value.restTimeRemaining
            restTimerJob?.cancel()
            restTimerJob = null
        }
    }

    fun resumeWorkout() {
        if (!_state.value.isPaused) return
        _state.value = _state.value.copy(isPaused = false)

        // Resume elapsed timer
        startElapsedTimer()

        // If was resting, resume rest timer from saved time
        if (_state.value.currentScreen == WorkoutScreen.REST && pausedRestTimeRemaining > 0) {
            restStartTime = System.currentTimeMillis()
            restTargetSeconds = pausedRestTimeRemaining
            _state.value = _state.value.copy(restTimeRemaining = pausedRestTimeRemaining)
            pausedRestTimeRemaining = 0

            restTimerJob = viewModelScope.launch {
                var previousRemaining = restTargetSeconds
                while (true) {
                    delay(500)
                    val elapsed = (System.currentTimeMillis() - restStartTime) / 1000
                    val remaining = (restTargetSeconds - elapsed.toInt()).coerceAtLeast(0)

                    if (remaining > 0) {
                        _state.value = _state.value.copy(restTimeRemaining = remaining)
                        // Haptic feedback for last 3 seconds (only trigger once per second)
                        if (remaining <= 3 && remaining != previousRemaining) {
                            playMediumHaptic()
                        }
                        previousRemaining = remaining
                    } else {
                        // Rest complete
                        playHeavyHaptic()
                        _state.value = _state.value.copy(
                            restTimeRemaining = 0,
                            currentScreen = WorkoutScreen.ACTIVE,
                            currentSetNumber = _state.value.currentSetNumber + 1
                        )
                        break
                    }
                }
            }
        }
    }

    // MARK: - Persistence

    private fun saveSettings() {
        prefs.edit()
            .putInt("targetReps", _state.value.targetReps)
            .putInt("restSeconds", _state.value.restSeconds)
            .putInt("targetTotalReps", _state.value.targetTotalReps)
            .apply()
    }

    private fun loadSettings() {
        val targetReps = prefs.getInt("targetReps", 10)
        val restSeconds = prefs.getInt("restSeconds", 60)
        val targetTotalReps = prefs.getInt("targetTotalReps", 100)
        _state.value = _state.value.copy(
            targetReps = targetReps,
            restSeconds = restSeconds,
            targetTotalReps = targetTotalReps
        )
    }

    // MARK: - Helpers

    fun formatTime(seconds: Int): String {
        val mins = seconds / 60
        val secs = seconds % 60
        return String.format("%d:%02d", mins, secs)
    }

    fun formatElapsedTime(seconds: Int): String {
        val hours = seconds / 3600
        val mins = (seconds % 3600) / 60
        val secs = seconds % 60
        return if (hours > 0) {
            String.format("%d:%02d:%02d", hours, mins, secs)
        } else {
            String.format("%d:%02d", mins, secs)
        }
    }

    // MARK: - Haptics

    private fun playMediumHaptic() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(50, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(50)
        }
    }

    private fun playHeavyHaptic() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(100)
        }
    }
}
