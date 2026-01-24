package com.repcount.android.wear

import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.lifecycle.viewmodel.compose.viewModel
import com.repcount.android.wear.ui.WearActiveScreen
import com.repcount.android.wear.ui.WearRestScreen
import com.repcount.android.wear.ui.WearSetupScreen
import com.repcount.android.wear.ui.WearSummaryScreen
import com.repcount.android.wear.ui.WearTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            WearTheme {
                RepCountWearApp(
                    onKeepScreenOn = { keepOn ->
                        if (keepOn) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                    }
                )
            }
        }
    }
}

@Composable
fun RepCountWearApp(
    viewModel: WearWorkoutViewModel = viewModel(),
    onKeepScreenOn: (Boolean) -> Unit
) {
    val state by viewModel.state.collectAsState()

    // Keep screen on during workout
    LaunchedEffect(state.currentScreen) {
        val isWorkingOut = state.currentScreen == WearScreen.ACTIVE ||
                state.currentScreen == WearScreen.REST
        onKeepScreenOn(isWorkingOut)
    }

    when (state.currentScreen) {
        WearScreen.SETUP -> WearSetupScreen(
            state = state,
            onTargetTotalRepsChange = viewModel::setTargetTotalReps,
            onTargetRepsChange = viewModel::setTargetReps,
            onRestSecondsChange = viewModel::setRestSeconds,
            onStartWorkout = viewModel::startWorkout
        )

        WearScreen.ACTIVE -> WearActiveScreen(
            state = state,
            formatTime = viewModel::formatTime,
            onCompleteSet = viewModel::completeSet,
            onEndWorkout = viewModel::endWorkout
        )

        WearScreen.REST -> WearRestScreen(
            state = state,
            formatTime = viewModel::formatTime,
            onAddRestTime = viewModel::addRestTime,
            onSkipRest = viewModel::skipRest,
            onEndWorkout = viewModel::endWorkout
        )

        WearScreen.SUMMARY -> WearSummaryScreen(
            state = state,
            formatElapsedTime = viewModel::formatElapsedTime,
            onDismiss = viewModel::dismissSummary
        )
    }
}
