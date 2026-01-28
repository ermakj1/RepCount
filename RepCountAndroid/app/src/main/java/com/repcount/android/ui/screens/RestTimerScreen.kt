package com.repcount.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.repcount.android.WorkoutState

@Composable
fun RestTimerScreen(
    state: WorkoutState,
    formatTime: (Int) -> String,
    onAddRestTime: (Int) -> Unit,
    onSkipRest: () -> Unit,
    onEndWorkout: () -> Unit,
    onPause: () -> Unit,
    onResume: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Elapsed time
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(bottom = 8.dp)
        ) {
            Icon(
                imageVector = Icons.Outlined.Timer,
                contentDescription = "Elapsed time",
                tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = formatTime(state.elapsedSeconds),
                fontSize = 18.sp,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
            )
        }

        // Progress display
        Text(
            text = "${state.completedReps}/${state.targetTotalReps}",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(8.dp))

        LinearProgressIndicator(
            progress = { state.progressPercent },
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp)
                .padding(horizontal = 50.dp),
            color = if (state.isGoalComplete) Color(0xFF4CAF50) else MaterialTheme.colorScheme.primary
        )

        if (state.isGoalComplete) {
            Text(
                text = "Goal Complete!",
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = Color(0xFF4CAF50),
                modifier = Modifier.padding(top = 8.dp)
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // REST/PAUSED label
        Text(
            text = if (state.isPaused) "PAUSED" else "REST",
            fontSize = 28.sp,
            fontWeight = FontWeight.Black,
            color = if (state.isPaused) Color.Gray else Color(0xFFFF9800)
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Timer display
        Text(
            text = formatTime(state.restTimeRemaining),
            fontSize = 72.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.alpha(if (state.isPaused) 0.5f else 1f)
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Pause/Resume button
        Button(
            onClick = { if (state.isPaused) onResume() else onPause() },
            colors = ButtonDefaults.buttonColors(
                containerColor = if (state.isPaused) Color(0xFF4CAF50) else Color.Gray
            )
        ) {
            Icon(
                imageVector = if (state.isPaused) Icons.Filled.PlayArrow else Icons.Filled.Pause,
                contentDescription = if (state.isPaused) "Resume" else "Pause",
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = if (state.isPaused) "Resume" else "Pause",
                fontWeight = FontWeight.Bold
            )
        }

        // Next set info
        Text(
            text = "Next: Set ${state.currentSetNumber + 1}",
            fontSize = 16.sp,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
            fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(top = 8.dp)
        )

        Spacer(modifier = Modifier.weight(1f))

        // Add time button (visible when timer is low)
        if (state.restTimeRemaining <= 10) {
            Button(
                onClick = { onAddRestTime(10) },
                enabled = !state.isPaused,
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFF9800)),
                modifier = Modifier
                    .padding(bottom = 16.dp)
                    .alpha(if (state.isPaused) 0.5f else 1f)
            ) {
                Text(
                    text = "+10 seconds",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        // Skip button
        TextButton(
            onClick = onSkipRest,
            enabled = !state.isPaused,
            modifier = Modifier.alpha(if (state.isPaused) 0.5f else 1f)
        ) {
            Text(
                text = "Skip Rest",
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        // End workout button
        Button(
            onClick = onEndWorkout,
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE57373))
        ) {
            Text(
                text = "End Workout",
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}
