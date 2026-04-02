package com.claudian.peace.model

import java.util.UUID
import java.time.Instant

data class AIInsights(
    val id: UUID = UUID.randomUUID(),
    val type: InsightType,
    val title: String,
    val description: String,
    val score: Double,
    val tags: List<String> = emptyList(),
    val createdAt: Instant = Instant.now()
)
