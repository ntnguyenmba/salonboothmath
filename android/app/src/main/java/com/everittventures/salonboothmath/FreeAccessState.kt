package com.everittventures.salonboothmath

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue

enum class PremiumFeature {
    SAVE,
    HISTORY,
    COMPARE,
    PAY_CHECKUP
}

class FreeAccessState(context: Context) {
    private val prefs = context.getSharedPreferences("salon_booth_math", Context.MODE_PRIVATE)

    private var usedSave by mutableStateOf(prefs.getBoolean(KEY_SAVE, false))
    private var usedHistory by mutableStateOf(prefs.getBoolean(KEY_HISTORY, false))
    private var usedCompare by mutableStateOf(prefs.getBoolean(KEY_COMPARE, false))
    private var usedPayCheckup by mutableStateOf(prefs.getBoolean(KEY_PAY_CHECKUP, false))

    fun used(feature: PremiumFeature): Boolean = when (feature) {
        PremiumFeature.SAVE -> usedSave
        PremiumFeature.HISTORY -> usedHistory
        PremiumFeature.COMPARE -> usedCompare
        PremiumFeature.PAY_CHECKUP -> usedPayCheckup
    }

    fun claim(feature: PremiumFeature, isUnlocked: Boolean): Boolean {
        if (isUnlocked) return true
        if (used(feature)) return false
        setUsed(feature)
        return true
    }

    private fun setUsed(feature: PremiumFeature) {
        val key = when (feature) {
            PremiumFeature.SAVE -> {
                usedSave = true
                KEY_SAVE
            }
            PremiumFeature.HISTORY -> {
                usedHistory = true
                KEY_HISTORY
            }
            PremiumFeature.COMPARE -> {
                usedCompare = true
                KEY_COMPARE
            }
            PremiumFeature.PAY_CHECKUP -> {
                usedPayCheckup = true
                KEY_PAY_CHECKUP
            }
        }
        prefs.edit().putBoolean(key, true).apply()
    }

    private companion object {
        const val KEY_SAVE = "did_use_free_save"
        const val KEY_HISTORY = "did_use_free_history"
        const val KEY_COMPARE = "did_use_free_compare"
        const val KEY_PAY_CHECKUP = "did_use_free_pay_checkup"
    }
}

@Composable
fun rememberFreeAccessState(context: Context): FreeAccessState =
    remember(context) { FreeAccessState(context) }
