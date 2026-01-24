package com.repcount.android.wear

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

enum class WearScreen {
    SETUP,
    ACTIVE,
    REST,
    SUMMARY
}

data class WearWorkoutState(
    // Setup
    val targetReps: Int = 10,
    val restSeconds: Int = 60,
    val targetTotalReps: Int = 100,

    // Workout state
    val currentScreen: WearScreen = WearScreen.SETUP,
    val currentSetNumber: Int = 1,
    val completedSets: List<Int> = emptyList(),
    val elapsedSeconds: Int = 0,

    // Rest timer
    val restTimeRemaining: Int = 0,

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

class WearWorkoutViewModel(application: Application) : AndroidViewModel(application) {

    private val prefs = application.getSharedPreferences("repcount_wear_prefs", Context.MODE_PRIVATE)

    private val _state = MutableStateFlow(WearWorkoutState())
    val state: StateFlow<WearWorkoutState> = _state.asStateFlow()

    private var elapsedTimerJob: Job? = null
    private var restTimerJob: Job? = null

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
        _state.value = _state.value.copy(
            currentScreen = WearScreen.ACTIVE,
            currentSetNumber = 1,
            completedSets = emptyList(),
            elapsedSeconds = 0
        )
        startElapsedTimer()
    }

    fun completeSet(reps: Int) {
        val newSets = _state.value.completedSets + reps
        _state.value = _state.value.copy(
            completedSets = newSets,
            currentScreen = WearScreen.REST,
            restTimeRemaining = _state.value.restSeconds
        )
        startRestTimer()
    }

    fun endWorkout() {
        stopElapsedTimer()
        stopRestTimer()

        val currentState = _state.value
        _state.value = currentState.copy(
            currentScreen = WearScreen.SUMMARY,
            summaryTotalReps = currentState.completedReps,
            summaryElapsedTime = currentState.elapsedSeconds,
            summarySetsCompleted = currentState.completedSets.size
        )
    }

    fun dismissSummary() {
        _state.value = _state.value.copy(
            currentScreen = WearScreen.SETUP,
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
            currentScreen = WearScreen.ACTIVE,
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
        restTimerJob = viewModelScope.launch {
            while (_state.value.restTimeRemaining > 0) {
                delay(1000)
                _state.value = _state.value.copy(
                    restTimeRemaining = _state.value.restTimeRemaining - 1
                )
            }
            // Rest complete
            _state.value = _state.value.copy(
                currentScreen = WearScreen.ACTIVE,
                currentSetNumber = _state.value.currentSetNumber + 1
            )
        }
    }

    private fun stopRestTimer() {
        restTimerJob?.cancel()
        restTimerJob = null
    }

    // MARK: - Elapsed Timer

    private fun startElapsedTimer() {
        stopElapsedTimer()
        elapsedTimerJob = viewModelScope.launch {
            while (true) {
                delay(1000)
                _state.value = _state.value.copy(
                    elapsedSeconds = _state.value.elapsedSeconds + 1
                )
            }
        }
    }

    private fun stopElapsedTimer() {
        elapsedTimerJob?.cancel()
        elapsedTimerJob = null
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
}
