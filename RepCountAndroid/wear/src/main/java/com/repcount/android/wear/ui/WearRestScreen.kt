package com.repcount.android.wear.ui

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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
    onEndWorkout: () -> Unit
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

        // REST label
        Text(
            text = "REST",
            fontSize = 16.sp,
            fontWeight = FontWeight.Black,
            color = Color(0xFFFF9800)
        )

        // Timer
        Text(
            text = formatTime(state.restTimeRemaining),
            fontSize = 40.sp,
            fontWeight = FontWeight.Bold
        )

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
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFFFF9800)
                    ),
                    modifier = Modifier.height(32.dp)
                ) {
                    Text("+10s", fontSize = 11.sp, textAlign = TextAlign.Center)
                }
            }

            Button(
                onClick = onSkipRest,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF4A90D9)
                ),
                modifier = Modifier.height(32.dp)
            ) {
                Text("Skip", fontSize = 11.sp, textAlign = TextAlign.Center)
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
            Text("End", fontSize = 10.sp, textAlign = TextAlign.Center)
        }
    }
}
