package com.repcount.android

import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.lifecycle.viewmodel.compose.viewModel
import com.repcount.android.ui.screens.ActiveWorkoutScreen
import com.repcount.android.ui.screens.RestTimerScreen
import com.repcount.android.ui.screens.SetupScreen
import com.repcount.android.ui.screens.SummaryScreen
import com.repcount.android.ui.theme.RepCountAndroidTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            RepCountAndroidTheme {
                RepCountApp(
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RepCountApp(
    viewModel: WorkoutViewModel = viewModel(),
    onKeepScreenOn: (Boolean) -> Unit
) {
    val state by viewModel.state.collectAsState()

    // Keep screen on during workout
    LaunchedEffect(state.currentScreen) {
        val isWorkingOut = state.currentScreen == WorkoutScreen.ACTIVE ||
                state.currentScreen == WorkoutScreen.REST
        onKeepScreenOn(isWorkingOut)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("RepCount") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.linearGradient(
                        colors = listOf(
                            Color(0xFF4A90D9).copy(alpha = 0.2f),
                            Color(0xFF7B68EE).copy(alpha = 0.2f)
                        )
                    )
                )
                .padding(innerPadding)
        ) {
            when (state.currentScreen) {
                WorkoutScreen.SETUP -> SetupScreen(
                    state = state,
                    onTargetTotalRepsChange = viewModel::setTargetTotalReps,
                    onTargetRepsChange = viewModel::setTargetReps,
                    onRestSecondsChange = viewModel::setRestSeconds,
                    onStartWorkout = viewModel::startWorkout
                )

                WorkoutScreen.ACTIVE -> ActiveWorkoutScreen(
                    state = state,
                    formatTime = viewModel::formatTime,
                    onCompleteSet = viewModel::completeSet,
                    onEndWorkout = viewModel::endWorkout,
                    onPause = viewModel::pauseWorkout,
                    onResume = viewModel::resumeWorkout
                )

                WorkoutScreen.REST -> RestTimerScreen(
                    state = state,
                    formatTime = viewModel::formatTime,
                    onAddRestTime = viewModel::addRestTime,
                    onSkipRest = viewModel::skipRest,
                    onEndWorkout = viewModel::endWorkout,
                    onPause = viewModel::pauseWorkout,
                    onResume = viewModel::resumeWorkout
                )

                WorkoutScreen.SUMMARY -> SummaryScreen(
                    state = state,
                    formatElapsedTime = viewModel::formatElapsedTime,
                    onDismiss = viewModel::dismissSummary
                )
            }
        }
    }
}
