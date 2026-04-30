package com.claudian.stikar

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.tooling.preview.Preview
import com.claudian.stikar.ui.theme.StikARTheme
import androidx.compose.foundation.background
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.Alignment
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.material3.Button



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
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Image(
                painter = painterResource(id = R.drawable.stikar_logo),
                contentDescription = "StikAR logo",
                modifier = Modifier.fillMaxWidth(0.70f),
                contentScale = ContentScale.Fit
            )

            Spacer(modifier = Modifier.height(1.dp))

            Text(
                text = "Drop stickers into the real world",
                color = Color.White,
                fontSize = 22.sp,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(20.dp))

            Text(
                text = "Create playful AR moments, explore shared zones and leave your mark everywhere.",
                color = Color.White,
                fontSize = 22.sp,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center
                )

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = { onStartClick() }
            ) {
                Text("START")
            }

        }
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
