package com.repcount.android

import android.app.Application
import android.content.Context
import android.content.SharedPreferences
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class WorkoutViewModelTest {

    private lateinit var viewModel: WorkoutViewModel
    private lateinit var application: Application
    private val testDispatcher = StandardTestDispatcher()

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        application = ApplicationProvider.getApplicationContext()
        // Clear any saved preferences
        application.getSharedPreferences("repcount_prefs", Context.MODE_PRIVATE)
            .edit()
            .clear()
            .apply()
        viewModel = WorkoutViewModel(application)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // MARK: - Initial State Tests

    @Test
    fun `initial state has default values`() {
        val state = viewModel.state.value
        assertEquals(10, state.targetReps)
        assertEquals(60, state.restSeconds)
        assertEquals(100, state.targetTotalReps)
        assertEquals(WorkoutScreen.SETUP, state.currentScreen)
        assertEquals(0, state.completedReps)
        assertEquals(1, state.currentSetNumber)
    }

    // MARK: - Settings Tests

    @Test
    fun `setTargetReps updates state`() {
        viewModel.setTargetReps(15)
        assertEquals(15, viewModel.state.value.targetReps)
    }

    @Test
    fun `setTargetReps ignores values less than 1`() {
        viewModel.setTargetReps(0)
        assertEquals(10, viewModel.state.value.targetReps)

        viewModel.setTargetReps(-5)
        assertEquals(10, viewModel.state.value.targetReps)
    }

    @Test
    fun `setRestSeconds updates state`() {
        viewModel.setRestSeconds(90)
        assertEquals(90, viewModel.state.value.restSeconds)
    }

    @Test
    fun `setRestSeconds ignores values less than 1`() {
        viewModel.setRestSeconds(0)
        assertEquals(60, viewModel.state.value.restSeconds)
    }

    @Test
    fun `setTargetTotalReps updates state`() {
        viewModel.setTargetTotalReps(200)
        assertEquals(200, viewModel.state.value.targetTotalReps)
    }

    @Test
    fun `setTargetTotalReps ignores values less than 1`() {
        viewModel.setTargetTotalReps(0)
        assertEquals(100, viewModel.state.value.targetTotalReps)
    }

    // MARK: - Workout Session Tests

    @Test
    fun `startWorkout changes screen to ACTIVE`() {
        viewModel.startWorkout()
        assertEquals(WorkoutScreen.ACTIVE, viewModel.state.value.currentScreen)
    }

    @Test
    fun `startWorkout resets workout state`() {
        // Complete a set first
        viewModel.startWorkout()
        viewModel.completeSet(10)
        viewModel.endWorkout()

        // Start new workout
        viewModel.dismissSummary()
        viewModel.startWorkout()

        val state = viewModel.state.value
        assertEquals(1, state.currentSetNumber)
        assertEquals(0, state.completedReps)
        assertEquals(emptyList<Int>(), state.completedSets)
    }

    @Test
    fun `completeSet adds reps to completed sets`() {
        viewModel.startWorkout()
        viewModel.completeSet(10)

        val state = viewModel.state.value
        assertEquals(listOf(10), state.completedSets)
        assertEquals(10, state.completedReps)
    }

    @Test
    fun `completeSet changes screen to REST`() {
        viewModel.startWorkout()
        viewModel.completeSet(10)

        assertEquals(WorkoutScreen.REST, viewModel.state.value.currentScreen)
    }

    @Test
    fun `completeSet sets rest time remaining`() {
        viewModel.setRestSeconds(45)
        viewModel.startWorkout()
        viewModel.completeSet(10)

        assertEquals(45, viewModel.state.value.restTimeRemaining)
    }

    @Test
    fun `multiple sets accumulate reps correctly`() {
        viewModel.startWorkout()
        viewModel.completeSet(10)
        viewModel.skipRest()
        viewModel.completeSet(8)
        viewModel.skipRest()
        viewModel.completeSet(12)

        val state = viewModel.state.value
        assertEquals(listOf(10, 8, 12), state.completedSets)
        assertEquals(30, state.completedReps)
    }

    // MARK: - Progress Tests

    @Test
    fun `progressPercent calculates correctly`() {
        viewModel.setTargetTotalReps(100)
        viewModel.startWorkout()
        viewModel.completeSet(25)

        assertEquals(0.25f, viewModel.state.value.progressPercent, 0.01f)
    }

    @Test
    fun `progressPercent caps at 1`() {
        viewModel.setTargetTotalReps(50)
        viewModel.startWorkout()
        viewModel.completeSet(60)

        assertEquals(1f, viewModel.state.value.progressPercent, 0.01f)
    }

    @Test
    fun `isGoalComplete is true when reps reach target`() {
        viewModel.setTargetTotalReps(20)
        viewModel.startWorkout()
        viewModel.completeSet(10)
        viewModel.skipRest()
        viewModel.completeSet(10)

        assertTrue(viewModel.state.value.isGoalComplete)
    }

    @Test
    fun `isGoalComplete is true when reps exceed target`() {
        viewModel.setTargetTotalReps(20)
        viewModel.startWorkout()
        viewModel.completeSet(25)

        assertTrue(viewModel.state.value.isGoalComplete)
    }

    // MARK: - Rest Timer Tests

    @Test
    fun `skipRest changes screen to ACTIVE`() {
        viewModel.startWorkout()
        viewModel.completeSet(10)
        viewModel.skipRest()

        assertEquals(WorkoutScreen.ACTIVE, viewModel.state.value.currentScreen)
    }

    @Test
    fun `skipRest increments set number`() {
        viewModel.startWorkout()
        viewModel.completeSet(10)
        viewModel.skipRest()

        assertEquals(2, viewModel.state.value.currentSetNumber)
    }

    @Test
    fun `addRestTime increases rest time remaining`() {
        viewModel.setRestSeconds(30)
        viewModel.startWorkout()
        viewModel.completeSet(10)

        val initialRest = viewModel.state.value.restTimeRemaining
        viewModel.addRestTime(10)

        assertEquals(initialRest + 10, viewModel.state.value.restTimeRemaining)
    }

    @Test
    fun `addRestTime also increases future rest duration`() {
        viewModel.setRestSeconds(30)
        viewModel.startWorkout()
        viewModel.completeSet(10)
        viewModel.addRestTime(10)

        assertEquals(40, viewModel.state.value.restSeconds)
    }

    // MARK: - End Workout Tests

    @Test
    fun `endWorkout shows summary with correct stats`() {
        viewModel.setTargetTotalReps(50)
        viewModel.startWorkout()
        viewModel.completeSet(10)
        viewModel.skipRest()
        viewModel.completeSet(8)
        viewModel.endWorkout()

        val state = viewModel.state.value
        assertEquals(WorkoutScreen.SUMMARY, state.currentScreen)
        assertEquals(18, state.summaryTotalReps)
        assertEquals(2, state.summarySetsCompleted)
    }

    @Test
    fun `dismissSummary returns to setup screen`() {
        viewModel.startWorkout()
        viewModel.completeSet(10)
        viewModel.endWorkout()
        viewModel.dismissSummary()

        assertEquals(WorkoutScreen.SETUP, viewModel.state.value.currentScreen)
    }

    @Test
    fun `dismissSummary clears summary data`() {
        viewModel.startWorkout()
        viewModel.completeSet(10)
        viewModel.endWorkout()
        viewModel.dismissSummary()

        val state = viewModel.state.value
        assertEquals(0, state.summaryTotalReps)
        assertEquals(0, state.summaryElapsedTime)
        assertEquals(0, state.summarySetsCompleted)
    }

    // MARK: - Format Helpers Tests

    @Test
    fun `formatTime formats correctly for seconds only`() {
        assertEquals("0:30", viewModel.formatTime(30))
    }

    @Test
    fun `formatTime formats correctly for minutes and seconds`() {
        assertEquals("1:30", viewModel.formatTime(90))
    }

    @Test
    fun `formatTime formats correctly for multiple minutes`() {
        assertEquals("5:00", viewModel.formatTime(300))
    }

    @Test
    fun `formatElapsedTime formats correctly without hours`() {
        assertEquals("5:30", viewModel.formatElapsedTime(330))
    }

    @Test
    fun `formatElapsedTime formats correctly with hours`() {
        assertEquals("1:05:30", viewModel.formatElapsedTime(3930))
    }

    // MARK: - Persistence Tests

    @Test
    fun `settings are persisted`() {
        viewModel.setTargetReps(15)
        viewModel.setRestSeconds(90)
        viewModel.setTargetTotalReps(150)
        viewModel.startWorkout() // This saves settings

        // Create new ViewModel to test loading
        val newViewModel = WorkoutViewModel(application)

        val state = newViewModel.state.value
        assertEquals(15, state.targetReps)
        assertEquals(90, state.restSeconds)
        assertEquals(150, state.targetTotalReps)
    }
}
