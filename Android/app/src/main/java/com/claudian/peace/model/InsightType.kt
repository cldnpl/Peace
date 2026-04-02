package com.claudian.peace.model

enum class InsightType {
    COGNITIVE_BIAS,
    PATTERN,
    SENTIMENT,
    RECOMMENDATION;

    val symbolName: String
        get() = when (this) {
            COGNITIVE_BIAS -> "exclamationmark.triangle.fill"
            PATTERN -> "point.bottomleft.forward.to.point.topright.scurvepath"
            SENTIMENT -> "bubble.left.and.bubble.right.fill"
            RECOMMENDATION -> "lightbulb.fill"
        }
}