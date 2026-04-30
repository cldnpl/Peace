package com.claudian.stikar

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.tooling.preview.Preview
import com.claudian.stikar.ui.theme.StikARTheme
import androidx.compose.foundation.background
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

@Composable
fun LaunchScreen(
    onStartClick: () -> Unit
) {
    Box(
        modifier = Modifier.fillMaxSize()
    ) {
        Image(
            painter = painterResource(id = R.drawable.home2),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize()
        )
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            Color(0xE6000000),
                            Color(0xCC140A03),
                            Color(0xE62A1004)
                        )
                    )
                )
        )
    }
}

@Preview(showBackground = true, showSystemUi = true)
@Composable
private fun LaunchScreenPreview() {
    StikARTheme(
        darkTheme = true,
        dynamicColor = false
    ) {
        LaunchScreen(onStartClick = {})
    }
}
