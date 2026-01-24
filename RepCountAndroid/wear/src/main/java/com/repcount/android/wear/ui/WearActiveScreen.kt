package com.repcount.android.wear.ui

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.CircularProgressIndicator
import androidx.wear.compose.material3.FilledIconButton
import androidx.wear.compose.material3.IconButtonDefaults
import androidx.wear.compose.material3.Text
import com.repcount.android.wear.WearWorkoutState

@Composable
fun WearActiveScreen(
    state: WearWorkoutState,
    formatTime: (Int) -> String,
    onCompleteSet: (Int) -> Unit,
    onEndWorkout: () -> Unit
) {
    var adjustedReps by remember { mutableIntStateOf(state.targetReps) }

    LaunchedEffect(state.targetReps) {
        adjustedReps = state.targetReps
    }

    val listState = rememberScalingLazyListState()

    ScalingLazyColumn(
        modifier = Modifier.fillMaxSize(),
        state = listState,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Elapsed time
        item {
            Text(
                text = formatTime(state.elapsedSeconds),
                fontSize = 12.sp,
                color = Color.Gray
            )
        }

        // Progress
        item {
            Box(contentAlignment = Alignment.Center) {
                CircularProgressIndicator(
                    progress = { state.progressPercent },
                    modifier = Modifier.size(60.dp),
                    strokeWidth = 6.dp
                )
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "${state.completedReps}/${state.targetTotalReps}",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "Set ${state.currentSetNumber}",
                        fontSize = 10.sp,
                        color = Color.Gray
                    )
                }
            }
        }

        // Rep adjuster
        item {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center,
                modifier = Modifier.padding(vertical = 8.dp)
            ) {
                FilledIconButton(
                    onClick = { if (adjustedReps > 0) adjustedReps-- },
                    colors = IconButtonDefaults.filledIconButtonColors(
                        containerColor = Color(0xFFE57373)
                    ),
                    modifier = Modifier.size(36.dp)
                ) {
                    Text("-", fontWeight = FontWeight.Bold, fontSize = 18.sp)
                }

                Text(
                    text = adjustedReps.toString(),
                    fontSize = 36.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(horizontal = 16.dp),
                    textAlign = TextAlign.Center
                )

                FilledIconButton(
                    onClick = { adjustedReps++ },
                    colors = IconButtonDefaults.filledIconButtonColors(
                        containerColor = Color(0xFF81C784)
                    ),
                    modifier = Modifier.size(36.dp)
                ) {
                    Text("+", fontWeight = FontWeight.Bold, fontSize = 18.sp)
                }
            }
        }

        // Done button
        item {
            Button(
                onClick = {
                    onCompleteSet(adjustedReps)
                    adjustedReps = state.targetReps
                },
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF4A90D9)
                ),
                modifier = Modifier.fillMaxWidth(0.8f)
            ) {
                Text(
                    text = "Done +$adjustedReps",
                    fontWeight = FontWeight.Bold
                )
            }
        }

        // End button
        item {
            Button(
                onClick = onEndWorkout,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFFE57373)
                ),
                modifier = Modifier.fillMaxWidth(0.6f)
            ) {
                Text(
                    text = "End",
                    fontSize = 12.sp
                )
            }
        }
    }
}
