package com.claudian.peace.model
import java.time.Instant
import java.util.UUID

data class SupportChatMessage(
    val id: UUID,
    val role: SupportMessageRole,
    val text: String,
    val createdAt: Instant
)


