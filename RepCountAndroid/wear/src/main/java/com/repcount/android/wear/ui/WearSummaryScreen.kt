package com.repcount.android.wear.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.Text
import com.repcount.android.wear.WearWorkoutState

@Composable
fun WearSummaryScreen(
    state: WearWorkoutState,
    formatElapsedTime: (Int) -> String,
    onDismiss: () -> Unit
) {
    val listState = rememberScalingLazyListState()

    ScalingLazyColumn(
        modifier = Modifier.fillMaxSize(),
        state = listState,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Check icon
        item {
            Icon(
                imageVector = Icons.Filled.CheckCircle,
                contentDescription = "Complete",
                tint = Color(0xFF4CAF50),
                modifier = Modifier.size(40.dp)
            )
        }

        // Title
        item {
            Text(
                text = "Done!",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
        }

        // Stats
        item {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(vertical = 8.dp)
            ) {
                StatRow(
                    label = "Reps",
                    value = state.summaryTotalReps.toString(),
                    color = Color(0xFFFF9800)
                )
                StatRow(
                    label = "Time",
                    value = formatElapsedTime(state.summaryElapsedTime),
                    color = Color(0xFF4A90D9)
                )
                StatRow(
                    label = "Sets",
                    value = state.summarySetsCompleted.toString(),
                    color = Color(0xFF9C27B0)
                )
            }
        }

        // Done button
        item {
            Button(
                onClick = onDismiss,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF4A90D9)
                ),
                modifier = Modifier.fillMaxWidth(0.7f)
            ) {
                Text(
                    text = "Done",
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@Composable
private fun StatRow(
    label: String,
    value: String,
    color: Color
) {
    Row(
        modifier = Modifier.padding(vertical = 2.dp),
        horizontalArrangement = Arrangement.Center
    ) {
        Text(
            text = "$label: ",
            fontSize = 14.sp,
            color = Color.Gray
        )
        Text(
            text = value,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold,
            color = color
        )
    }
}
