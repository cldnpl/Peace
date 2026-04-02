package com.claudian.peace.model

import androidx.compose.ui.graphics.Color
import java.util.UUID

data class CognitivePattern(
    val id: UUID = UUID.randomUUID(),
    val text: String,
    val color: Color
)
