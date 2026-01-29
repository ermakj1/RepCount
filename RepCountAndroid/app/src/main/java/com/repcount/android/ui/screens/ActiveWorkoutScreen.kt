package com.repcount.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.repcount.android.WorkoutState

@Composable
fun ActiveWorkoutScreen(
    state: WorkoutState,
    formatTime: (Int) -> String,
    onCompleteSet: (Int) -> Unit,
    onEndWorkout: () -> Unit,
    onPause: () -> Unit,
    onResume: () -> Unit
) {
    var adjustedReps by remember { mutableIntStateOf(state.targetReps) }

    // Reset adjustedReps when targetReps changes
    LaunchedEffect(state.targetReps) {
        adjustedReps = state.targetReps
    }

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
            fontSize = 36.sp,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(8.dp))

        LinearProgressIndicator(
            progress = { state.progressPercent },
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp)
                .padding(horizontal = 40.dp),
            color = if (state.isGoalComplete) Color(0xFF4CAF50) else MaterialTheme.colorScheme.primary
        )

        if (state.isGoalComplete) {
            Text(
                text = "Goal Complete!",
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                color = Color(0xFF4CAF50),
                modifier = Modifier.padding(top = 8.dp)
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Set counter
        Text(
            text = "Set ${state.currentSetNumber}",
            fontSize = 20.sp,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
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

        Spacer(modifier = Modifier.weight(1f))

        // Reps display
        Text(
            text = "Reps Completed",
            fontSize = 16.sp,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
            fontWeight = FontWeight.Medium
        )

        Spacer(modifier = Modifier.height(8.dp))

        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center,
            modifier = Modifier.alpha(if (state.isPaused) 0.5f else 1f)
        ) {
            FilledIconButton(
                onClick = { if (adjustedReps > 0) adjustedReps-- },
                enabled = !state.isPaused,
                colors = IconButtonDefaults.filledIconButtonColors(
                    containerColor = Color(0xFFE57373)
                ),
                modifier = Modifier.size(56.dp)
            ) {
                Text("-", fontSize = 28.sp, fontWeight = FontWeight.Bold)
            }

            Text(
                text = adjustedReps.toString(),
                fontSize = 80.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(horizontal = 32.dp)
            )

            FilledIconButton(
                onClick = { adjustedReps++ },
                enabled = !state.isPaused,
                colors = IconButtonDefaults.filledIconButtonColors(
                    containerColor = Color(0xFF81C784)
                ),
                modifier = Modifier.size(56.dp)
            ) {
                Text("+", fontSize = 28.sp, fontWeight = FontWeight.Bold)
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        // Quick complete button - larger for easy tapping when tired
        Button(
            onClick = {
                onCompleteSet(state.targetReps)
                adjustedReps = state.targetReps
            },
            enabled = !state.isPaused,
            modifier = Modifier
                .fillMaxWidth()
                .height(100.dp)
                .alpha(if (state.isPaused) 0.5f else 1f),
            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
        ) {
            Text(
                text = "Done: +${state.targetReps} reps",
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold
            )
        }

        // Adjusted reps button (if different) - also larger for easy tapping
        if (adjustedReps != state.targetReps && adjustedReps > 0) {
            Spacer(modifier = Modifier.height(12.dp))
            Button(
                onClick = { onCompleteSet(adjustedReps) },
                enabled = !state.isPaused,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(80.dp)
                    .alpha(if (state.isPaused) 0.5f else 1f),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFF9800))
            ) {
                Text(
                    text = "Done: +$adjustedReps reps",
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

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
