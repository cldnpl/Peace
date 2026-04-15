package com.claudian.peace.storage

import android.content.Context

class PeacePreferences(context: Context) {
    private val prefs = context.getSharedPreferences("peace_prefs", Context.MODE_PRIVATE)

    fun hasSeenOnboarding(): Boolean {
        return prefs.getBoolean("has_seen_onboarding", false)
    }

    fun setHasSeenOnboarding(value: Boolean) {
        prefs.edit().putBoolean("has_seen_onboarding", value).apply()
    }

    fun userName(): String {
        return prefs.getString("user_name", "") ?: ""
    }

    fun setUserName(value: String) {
        prefs.edit().putString("user_name", value).apply()
    }
}
