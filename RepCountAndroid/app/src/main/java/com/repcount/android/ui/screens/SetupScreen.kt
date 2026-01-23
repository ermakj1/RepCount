package com.repcount.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.repcount.android.WorkoutState

@Composable
fun SetupScreen(
    state: WorkoutState,
    onTargetTotalRepsChange: (Int) -> Unit,
    onTargetRepsChange: (Int) -> Unit,
    onRestSecondsChange: (Int) -> Unit,
    onStartWorkout: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Set Up Your Workout",
            fontSize = 24.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(bottom = 32.dp)
        )

        // Total Goal
        SettingSection(
            title = "Total Goal",
            value = state.targetTotalReps,
            onDecrease = { if (state.targetTotalReps > 1) onTargetTotalRepsChange(state.targetTotalReps - 1) },
            onIncrease = { onTargetTotalRepsChange(state.targetTotalReps + 1) },
            quickValues = listOf(50, 100, 150, 200),
            onQuickSelect = onTargetTotalRepsChange
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Reps per Set
        SettingSection(
            title = "Reps per Set",
            value = state.targetReps,
            onDecrease = { if (state.targetReps > 1) onTargetRepsChange(state.targetReps - 1) },
            onIncrease = { onTargetRepsChange(state.targetReps + 1) },
            quickValues = listOf(5, 10, 12, 15, 20),
            onQuickSelect = onTargetRepsChange
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Rest Between Sets
        SettingSection(
            title = "Rest Between Sets",
            value = state.restSeconds,
            displayValue = formatRestTime(state.restSeconds),
            onDecrease = { if (state.restSeconds > 1) onRestSecondsChange(state.restSeconds - 1) },
            onIncrease = { onRestSecondsChange(state.restSeconds + 1) },
            quickValues = listOf(30, 45, 60, 90, 120),
            quickValueLabels = listOf("30s", "45s", "1:00", "1:30", "2:00"),
            onQuickSelect = onRestSecondsChange
        )

        Spacer(modifier = Modifier.height(40.dp))

        // Start Button
        Button(
            onClick = onStartWorkout,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50))
        ) {
            Text(
                text = "Start Workout",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
private fun SettingSection(
    title: String,
    value: Int,
    displayValue: String = value.toString(),
    onDecrease: () -> Unit,
    onIncrease: () -> Unit,
    quickValues: List<Int>,
    quickValueLabels: List<String>? = null,
    onQuickSelect: (Int) -> Unit
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = title,
            fontSize = 16.sp,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
            fontWeight = FontWeight.Medium
        )

        Spacer(modifier = Modifier.height(8.dp))

        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            FilledIconButton(
                onClick = onDecrease,
                colors = IconButtonDefaults.filledIconButtonColors(
                    containerColor = Color(0xFFE57373)
                ),
                modifier = Modifier.size(48.dp)
            ) {
                Text("-", fontSize = 24.sp, fontWeight = FontWeight.Bold)
            }

            Text(
                text = displayValue,
                fontSize = 48.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(horizontal = 24.dp)
            )

            FilledIconButton(
                onClick = onIncrease,
                colors = IconButtonDefaults.filledIconButtonColors(
                    containerColor = Color(0xFF81C784)
                ),
                modifier = Modifier.size(48.dp)
            ) {
                Text("+", fontSize = 24.sp, fontWeight = FontWeight.Bold)
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Quick select buttons
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            quickValues.forEachIndexed { index, quickValue ->
                val label = quickValueLabels?.getOrNull(index) ?: quickValue.toString()
                val isSelected = value == quickValue
                FilterChip(
                    selected = isSelected,
                    onClick = { onQuickSelect(quickValue) },
                    label = { Text(label, fontWeight = FontWeight.Bold) },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = MaterialTheme.colorScheme.primary,
                        selectedLabelColor = MaterialTheme.colorScheme.onPrimary
                    )
                )
            }
        }
    }
}

private fun formatRestTime(seconds: Int): String {
    val mins = seconds / 60
    val secs = seconds % 60
    return if (mins > 0) {
        String.format("%d:%02d", mins, secs)
    } else {
        "${secs}s"
    }
}
