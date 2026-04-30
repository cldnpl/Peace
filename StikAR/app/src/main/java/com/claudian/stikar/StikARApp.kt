package com.claudian.stikar

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue

private enum class AppScreen {
    Launch,
    Terms,
    Nickname,
    Home
}

@Composable
fun StikARApp() {
    var currentScreen by remember { mutableStateOf(AppScreen.Launch) }

    when (currentScreen) {
        AppScreen.Launch -> {
            LaunchScreen(
                onStartClick = {
                    currentScreen = AppScreen.Terms
                }
            )
        }

        AppScreen.Terms -> {
            TermsScreen(
                onAccept = {
                    currentScreen = AppScreen.Nickname
                },
                onDecline = {
                    currentScreen = AppScreen.Launch
                }
            )
        }

        AppScreen.Nickname -> {
            NicknameScreen(
                onContinue = {
                    currentScreen = AppScreen.Home
                }
            )
        }

        AppScreen.Home -> {
            HomeScreen()
        }
    }
}
