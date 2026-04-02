package com.claudian.peace.localization

enum class AppLanguage(val code: String, val displayName: String) {
    ITALIAN("it", "Italiano"),
    ENGLISH("en", "English"),
    SPANISH("es", "Español"),
    FRENCH("fr", "Français"),
    CHINESE("zh-Hans", "中文"),
    ARABIC("ar", "العربية"),
    DANISH("da", "Dansk"),
    NORWEGIAN("nb", "Norsk"),
    SWEDISH("sv", "Svenska");

    companion object {
        fun bestMatch(localeIdentifier: String): AppLanguage {
            val lowered = localeIdentifier.lowercase()

            return when {
                lowered.startsWith("it") -> ITALIAN
                lowered.startsWith("en") -> ENGLISH
                lowered.startsWith("es") -> SPANISH
                lowered.startsWith("fr") -> FRENCH
                lowered.startsWith("zh") -> CHINESE
                lowered.startsWith("ar") -> ARABIC
                lowered.startsWith("da") -> DANISH
                lowered.startsWith("nb") || lowered.startsWith("no") -> NORWEGIAN
                lowered.startsWith("sv") -> SWEDISH
                else -> ENGLISH
            }
        }
    }
}