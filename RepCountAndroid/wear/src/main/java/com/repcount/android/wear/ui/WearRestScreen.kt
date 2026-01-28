package com.repcount.android.wear.ui

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.Text
import com.repcount.android.wear.WearWorkoutState

@Composable
fun WearRestScreen(
    state: WearWorkoutState,
    formatTime: (Int) -> String,
    onAddRestTime: (Int) -> Unit,
    onSkipRest: () -> Unit,
    onEndWorkout: () -> Unit,
    onPause: () -> Unit,
    onResume: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Elapsed time
        Text(
            text = formatTime(state.elapsedSeconds),
            fontSize = 12.sp,
            color = Color.Gray
        )

        // Progress
        Text(
            text = "${state.completedReps}/${state.targetTotalReps}",
            fontSize = 12.sp,
            color = if (state.isGoalComplete) Color(0xFF4CAF50) else Color.Gray
        )

        Spacer(modifier = Modifier.height(4.dp))

        // REST/PAUSED label
        Text(
            text = if (state.isPaused) "PAUSED" else "REST",
            fontSize = 16.sp,
            fontWeight = FontWeight.Black,
            color = if (state.isPaused) Color.Gray else Color(0xFFFF9800)
        )

        // Timer
        Text(
            text = formatTime(state.restTimeRemaining),
            fontSize = 40.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.alpha(if (state.isPaused) 0.5f else 1f)
        )

        Spacer(modifier = Modifier.height(4.dp))

        // Pause/Resume button
        Button(
            onClick = { if (state.isPaused) onResume() else onPause() },
            colors = ButtonDefaults.buttonColors(
                containerColor = if (state.isPaused) Color(0xFF4CAF50) else Color.Gray
            ),
            modifier = Modifier.height(28.dp)
        ) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = if (state.isPaused) "Resume" else "Pause",
                    fontSize = 10.sp
                )
            }
        }

        // Next set
        Text(
            text = "Next: Set ${state.currentSetNumber + 1}",
            fontSize = 10.sp,
            color = Color.Gray
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Buttons row
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            if (state.restTimeRemaining <= 10) {
                Button(
                    onClick = { onAddRestTime(10) },
                    enabled = !state.isPaused,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFFF9800)
                    ),
                    modifier = Modifier
                        .height(32.dp)
                        .alpha(if (state.isPaused) 0.5f else 1f)
                ) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("+10s", fontSize = 11.sp)
                    }
                }
            }

            Button(
                onClick = onSkipRest,
                enabled = !state.isPaused,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF4A90D9)
                ),
                modifier = Modifier
                    .height(32.dp)
                    .alpha(if (state.isPaused) 0.5f else 1f)
            ) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text("Skip", fontSize = 11.sp)
                }
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        Button(
            onClick = onEndWorkout,
            colors = ButtonDefaults.buttonColors(
                containerColor = Color(0xFFE57373)
            ),
            modifier = Modifier.height(28.dp)
        ) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text("End", fontSize = 10.sp)
            }
        }
    }
}
