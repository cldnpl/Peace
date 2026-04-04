package com.claudian.peace

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.claudian.peace.ui.PeaceAppRoot
import com.claudian.peace.ui.theme.PeaceTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            PeaceTheme {
                PeaceAppRoot()
            }
        }
    }
}
