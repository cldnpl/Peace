package com.claudian.peace.ui.onboarding

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.claudian.peace.ui.theme.PeaceTheme

@Composable
fun OnboardingScreen(
    onContinue: () -> Unit
) {
    var draftName by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("Welcome to Peace")

        OutlinedTextField(
            value = draftName,
            onValueChange = { draftName = it },
            label = { Text("Your Name") }
        )
        Button(
            onClick = onContinue,
            enabled = draftName.isNotBlank()
        ) {
            Text("Continue")
        }
    }
}

@Preview(showBackground = true, showSystemUi = true)
@Composable
fun OnboardingScreenPreview() {
    PeaceTheme {
        OnboardingScreen(onContinue = {})
    }
}
