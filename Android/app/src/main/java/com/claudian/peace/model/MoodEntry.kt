package com.claudian.peace.model

import java.time.Instant
import java.util.UUID

data class MoodEntry(
    val id: UUID = UUID.randomUUID(),
    val date: Instant = Instant.now(),
    val mood: MoodLevel,
    var note: String = ""
)
