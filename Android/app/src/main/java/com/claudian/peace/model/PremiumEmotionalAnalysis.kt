package com.claudian.peace.model

import java.time.Instant

data class PremiumEmotionalAnalysis(
    val signature: String,
    val title: String,
    val content: String,
    val generatedAt: Instant
)