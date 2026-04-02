package com.claudian.peace.model

import java.time.Instant
import java.util.UUID


data class SupportChatSession(
    val id: UUID,
    val title: String,
    val updatedAt: Instant,
    val messages: List<SupportChatMessage>
)
