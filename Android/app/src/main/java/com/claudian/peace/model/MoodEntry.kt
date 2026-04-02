package com.claudian.peace.model
import java.time.Instant
import java.util.UUID

data class MoodEntry(
    val id: UUID,
    val date: Instant,
    val mood: MoodLevel,
    var note: String
)
