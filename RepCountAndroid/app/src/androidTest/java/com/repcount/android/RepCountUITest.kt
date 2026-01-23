package com.repcount.android

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import com.repcount.android.ui.screens.ActiveWorkoutScreen
import com.repcount.android.ui.screens.RestTimerScreen
import com.repcount.android.ui.screens.SetupScreen
import com.repcount.android.ui.screens.SummaryScreen
import com.repcount.android.ui.theme.RepCountAndroidTheme
import org.junit.Rule
import org.junit.Test

class RepCountUITest {

    @get:Rule
    val composeTestRule = createComposeRule()

    // MARK: - Setup Screen Tests

    @Test
    fun setupScreen_displaysAllElements() {
        val state = WorkoutState()

        composeTestRule.setContent {
            RepCountAndroidTheme {
                SetupScreen(
                    state = state,
                    onTargetTotalRepsChange = {},
                    onTargetRepsChange = {},
                    onRestSecondsChange = {},
                    onStartWorkout = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Set Up Your Workout").assertIsDisplayed()
        composeTestRule.onNodeWithText("Total Goal").assertIsDisplayed()
        composeTestRule.onNodeWithText("Reps per Set").assertIsDisplayed()
        composeTestRule.onNodeWithText("Rest Between Sets").assertIsDisplayed()
        composeTestRule.onNodeWithText("Start Workout").assertIsDisplayed()
    }

    @Test
    fun setupScreen_displaysCorrectValues() {
        val state = WorkoutState(
            targetTotalReps = 150,
            targetReps = 12,
            restSeconds = 90
        )

        composeTestRule.setContent {
            RepCountAndroidTheme {
                SetupScreen(
                    state = state,
                    onTargetTotalRepsChange = {},
                    onTargetRepsChange = {},
                    onRestSecondsChange = {},
                    onStartWorkout = {}
                )
            }
        }

        composeTestRule.onNodeWithText("150").assertIsDisplayed()
        composeTestRule.onNodeWithText("12").assertIsDisplayed()
        composeTestRule.onNodeWithText("1:30").assertIsDisplayed()
    }

    @Test
    fun setupScreen_startButtonCallsCallback() {
        var startClicked = false

        composeTestRule.setContent {
            RepCountAndroidTheme {
                SetupScreen(
                    state = WorkoutState(),
                    onTargetTotalRepsChange = {},
                    onTargetRepsChange = {},
                    onRestSecondsChange = {},
                    onStartWorkout = { startClicked = true }
                )
            }
        }

        composeTestRule.onNodeWithText("Start Workout").performClick()
        assert(startClicked)
    }

    @Test
    fun setupScreen_quickSelectButtonsWork() {
        var selectedValue = 0

        composeTestRule.setContent {
            RepCountAndroidTheme {
                SetupScreen(
                    state = WorkoutState(),
                    onTargetTotalRepsChange = { selectedValue = it },
                    onTargetRepsChange = {},
                    onRestSecondsChange = {},
                    onStartWorkout = {}
                )
            }
        }

        composeTestRule.onNodeWithText("200").performClick()
        assert(selectedValue == 200)
    }

    // MARK: - Active Workout Screen Tests

    @Test
    fun activeWorkoutScreen_displaysProgress() {
        val state = WorkoutState(
            currentScreen = WorkoutScreen.ACTIVE,
            targetTotalReps = 100,
            completedSets = listOf(10, 10),
            currentSetNumber = 3,
            elapsedSeconds = 125
        )

        composeTestRule.setContent {
            RepCountAndroidTheme {
                ActiveWorkoutScreen(
                    state = state,
                    formatTime = { seconds -> "${seconds / 60}:${String.format("%02d", seconds % 60)}" },
                    onCompleteSet = {},
                    onEndWorkout = {}
                )
            }
        }

        composeTestRule.onNodeWithText("20/100").assertIsDisplayed()
        composeTestRule.onNodeWithText("Set 3").assertIsDisplayed()
        composeTestRule.onNodeWithText("2:05").assertIsDisplayed()
    }

    @Test
    fun activeWorkoutScreen_showsGoalComplete() {
        val state = WorkoutState(
            currentScreen = WorkoutScreen.ACTIVE,
            targetTotalReps = 20,
            completedSets = listOf(10, 10)
        )

        composeTestRule.setContent {
            RepCountAndroidTheme {
                ActiveWorkoutScreen(
                    state = state,
                    formatTime = { "0:00" },
                    onCompleteSet = {},
                    onEndWorkout = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Goal Complete!").assertIsDisplayed()
    }

    @Test
    fun activeWorkoutScreen_doneButtonCallsCallback() {
        var completedReps = 0

        composeTestRule.setContent {
            RepCountAndroidTheme {
                ActiveWorkoutScreen(
                    state = WorkoutState(targetReps = 10),
                    formatTime = { "0:00" },
                    onCompleteSet = { completedReps = it },
                    onEndWorkout = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Done: +10 reps").performClick()
        assert(completedReps == 10)
    }

    @Test
    fun activeWorkoutScreen_endWorkoutButtonCallsCallback() {
        var endClicked = false

        composeTestRule.setContent {
            RepCountAndroidTheme {
                ActiveWorkoutScreen(
                    state = WorkoutState(),
                    formatTime = { "0:00" },
                    onCompleteSet = {},
                    onEndWorkout = { endClicked = true }
                )
            }
        }

        composeTestRule.onNodeWithText("End Workout").performClick()
        assert(endClicked)
    }

    // MARK: - Rest Timer Screen Tests

    @Test
    fun restTimerScreen_displaysRestTime() {
        val state = WorkoutState(
            currentScreen = WorkoutScreen.REST,
            restTimeRemaining = 45,
            currentSetNumber = 2
        )

        composeTestRule.setContent {
            RepCountAndroidTheme {
                RestTimerScreen(
                    state = state,
                    formatTime = { seconds -> "${seconds / 60}:${String.format("%02d", seconds % 60)}" },
                    onAddRestTime = {},
                    onSkipRest = {},
                    onEndWorkout = {}
                )
            }
        }

        composeTestRule.onNodeWithText("REST").assertIsDisplayed()
        composeTestRule.onNodeWithText("0:45").assertIsDisplayed()
        composeTestRule.onNodeWithText("Next: Set 3").assertIsDisplayed()
    }

    @Test
    fun restTimerScreen_showsAddTimeButtonWhenLow() {
        val state = WorkoutState(
            currentScreen = WorkoutScreen.REST,
            restTimeRemaining = 5
        )

        composeTestRule.setContent {
            RepCountAndroidTheme {
                RestTimerScreen(
                    state = state,
                    formatTime = { "0:05" },
                    onAddRestTime = {},
                    onSkipRest = {},
                    onEndWorkout = {}
                )
            }
        }

        composeTestRule.onNodeWithText("+10 seconds").assertIsDisplayed()
    }

    @Test
    fun restTimerScreen_hidesAddTimeButtonWhenHigh() {
        val state = WorkoutState(
            currentScreen = WorkoutScreen.REST,
            restTimeRemaining = 30
        )

        composeTestRule.setContent {
            RepCountAndroidTheme {
                RestTimerScreen(
                    state = state,
                    formatTime = { "0:30" },
                    onAddRestTime = {},
                    onSkipRest = {},
                    onEndWorkout = {}
                )
            }
        }

        composeTestRule.onNodeWithText("+10 seconds").assertDoesNotExist()
    }

    @Test
    fun restTimerScreen_skipRestCallsCallback() {
        var skipClicked = false

        composeTestRule.setContent {
            RepCountAndroidTheme {
                RestTimerScreen(
                    state = WorkoutState(restTimeRemaining = 30),
                    formatTime = { "0:30" },
                    onAddRestTime = {},
                    onSkipRest = { skipClicked = true },
                    onEndWorkout = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Skip Rest").performClick()
        assert(skipClicked)
    }

    // MARK: - Summary Screen Tests

    @Test
    fun summaryScreen_displaysStats() {
        val state = WorkoutState(
            currentScreen = WorkoutScreen.SUMMARY,
            summaryTotalReps = 75,
            summaryElapsedTime = 1800,
            summarySetsCompleted = 8
        )

        composeTestRule.setContent {
            RepCountAndroidTheme {
                SummaryScreen(
                    state = state,
                    formatElapsedTime = { "30:00" },
                    onDismiss = {}
                )
            }
        }

        composeTestRule.onNodeWithText("Workout Complete!").assertIsDisplayed()
        composeTestRule.onNodeWithText("75").assertIsDisplayed()
        composeTestRule.onNodeWithText("30:00").assertIsDisplayed()
        composeTestRule.onNodeWithText("8").assertIsDisplayed()
        composeTestRule.onNodeWithText("Done").assertIsDisplayed()
    }

    @Test
    fun summaryScreen_doneButtonCallsCallback() {
        var doneClicked = false

        composeTestRule.setContent {
            RepCountAndroidTheme {
                SummaryScreen(
                    state = WorkoutState(),
                    formatElapsedTime = { "0:00" },
                    onDismiss = { doneClicked = true }
                )
            }
        }

        composeTestRule.onNodeWithText("Done").performClick()
        assert(doneClicked)
    }
}
