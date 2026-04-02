package com.claudian.peace.model

enum class MoodLevel {
    ANXIOUS,
    NEUTRAL,
    OKAY,
    GOOD,
    EXCELLENT;

    val energyValue: Double
        get() = when (this) {
            ANXIOUS -> 0.30
            NEUTRAL -> 0.48
            OKAY -> 0.64
            GOOD -> 0.80
            EXCELLENT -> 1.0
        }

    val symbolName: String
        get() = when (this) {
            ANXIOUS -> "bolt.fill"
            NEUTRAL -> "heart.fill"
            OKAY -> "gauge.with.needle"
            GOOD -> "sun.max.fill"
            EXCELLENT -> "star.fill"
        }
}