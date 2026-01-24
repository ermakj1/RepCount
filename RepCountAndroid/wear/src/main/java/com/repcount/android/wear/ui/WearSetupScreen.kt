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
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.FilledIconButton
import androidx.wear.compose.material3.IconButtonDefaults
import androidx.wear.compose.material3.Text
import com.repcount.android.wear.WearWorkoutState

@Composable
fun WearSetupScreen(
    state: WearWorkoutState,
    onTargetTotalRepsChange: (Int) -> Unit,
    onTargetRepsChange: (Int) -> Unit,
    onRestSecondsChange: (Int) -> Unit,
    onStartWorkout: () -> Unit
) {
    val listState = rememberScalingLazyListState()

    ScalingLazyColumn(
        modifier = Modifier.fillMaxSize(),
        state = listState,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Goal
        item {
            SettingRow(
                label = "Goal",
                value = state.targetTotalReps.toString(),
                onDecrease = { if (state.targetTotalReps > 1) onTargetTotalRepsChange(state.targetTotalReps - 1) },
                onIncrease = { onTargetTotalRepsChange(state.targetTotalReps + 1) }
            )
        }

        // Per Set
        item {
            SettingRow(
                label = "Per Set",
                value = state.targetReps.toString(),
                onDecrease = { if (state.targetReps > 1) onTargetRepsChange(state.targetReps - 1) },
                onIncrease = { onTargetRepsChange(state.targetReps + 1) }
            )
        }

        // Rest
        item {
            SettingRow(
                label = "Rest",
                value = formatRestTime(state.restSeconds),
                onDecrease = { if (state.restSeconds > 1) onRestSecondsChange(state.restSeconds - 1) },
                onIncrease = { onRestSecondsChange(state.restSeconds + 1) }
            )
        }

        // Start button
        item {
            Spacer(modifier = Modifier.height(8.dp))
            Button(
                onClick = onStartWorkout,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF4CAF50)
                ),
                modifier = Modifier.fillMaxWidth(0.8f)
            ) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "Start",
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Composable
private fun SettingRow(
    label: String,
    value: String,
    onDecrease: () -> Unit,
    onIncrease: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.padding(vertical = 4.dp)
    ) {
        Text(
            text = label,
            fontSize = 12.sp,
            color = Color.Gray
        )

        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            FilledIconButton(
                onClick = onDecrease,
                colors = IconButtonDefaults.filledIconButtonColors(
                    containerColor = Color(0xFFE57373)
                ),
                modifier = Modifier.size(32.dp)
            ) {
                Text("-", fontWeight = FontWeight.Bold)
            }

            Text(
                text = value,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(horizontal = 16.dp),
                textAlign = TextAlign.Center
            )

            FilledIconButton(
                onClick = onIncrease,
                colors = IconButtonDefaults.filledIconButtonColors(
                    containerColor = Color(0xFF81C784)
                ),
                modifier = Modifier.size(32.dp)
            ) {
                Text("+", fontWeight = FontWeight.Bold)
            }
        }
    }
}

private fun formatRestTime(seconds: Int): String {
    val mins = seconds / 60
    val secs = seconds % 60
    return if (mins > 0 && secs == 0) {
        "${mins}m"
    } else if (mins > 0) {
        "$mins:${String.format("%02d", secs)}"
    } else {
        "${secs}s"
    }
}
