package com.claudian.peace.ui

import com.claudian.peace.ui.main.MainTabsScreen
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.tooling.preview.Preview
import com.claudian.peace.storage.PeacePreferences
import com.claudian.peace.ui.onboarding.OnboardingScreen
import com.claudian.peace.ui.theme.PeaceTheme


@Composable
fun PeaceAppRoot() {
    val context = LocalContext.current
    val preferences = remember { PeacePreferences(context) }
    var hasSeenOnBoarding by rememberSaveable {
        mutableStateOf(preferences.hasSeenOnboarding())
    }
    var draftName by rememberSaveable {
        mutableStateOf(preferences.userName())
    }
    val normalizedName = draftName.trim()

    if (hasSeenOnBoarding) {
        MainTabsScreen()
    } else {
        OnboardingScreen(
            draftName = draftName,
            onNameChange = { draftName = it },
            onContinue = {
                preferences.setUserName(normalizedName)
                preferences.setHasSeenOnboarding(true)
                draftName = normalizedName
                hasSeenOnBoarding = true
            }
        )
    }
}

@Composable
fun MainTabsPlaceholder() {
    Text("MainTabView Android")
}

@Preview(showBackground = true, showSystemUi = true)
@Composable
fun PeaceAppRootPreview() {
    PeaceTheme {
        PeaceAppRoot()
    }
}
