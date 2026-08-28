package com.everittventures.salonboothmath

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class SavedWeek(val startMillis: Long, val services: Double, val tips: Double, val supplies: Double, val takeHome: Double)

class AppStore(context: Context) {
    private val prefs = context.getSharedPreferences("salon_booth_math", Context.MODE_PRIVATE)

    var onboardingDone: Boolean
        get() = prefs.getBoolean("onboardingDone", false)
        set(value) = prefs.edit().putBoolean("onboardingDone", value).apply()

    var trade: String
        get() = prefs.getString("trade", "nail") ?: "nail"
        set(value) = prefs.edit().putString("trade", value).apply()

    var payModel: String
        get() = prefs.getString("payModel", "booth") ?: "booth"
        set(value) = prefs.edit().putString("payModel", value).apply()

    var weeklyRent: Double
        get() = java.lang.Double.longBitsToDouble(prefs.getLong("weeklyRent", java.lang.Double.doubleToLongBits(250.0)))
        set(value) = prefs.edit().putLong("weeklyRent", java.lang.Double.doubleToLongBits(value)).apply()

    var commissionCut: Double
        get() = java.lang.Double.longBitsToDouble(prefs.getLong("commissionCut", java.lang.Double.doubleToLongBits(.55)))
        set(value) = prefs.edit().putLong("commissionCut", java.lang.Double.doubleToLongBits(value)).apply()

    fun saveWeek(week: SavedWeek) {
        val weeks = loadWeeks().filterNot { sameWeek(it.startMillis, week.startMillis) }.toMutableList()
        weeks.add(week)
        weeks.sortByDescending { it.startMillis }
        val array = JSONArray()
        weeks.take(52).forEach { w -> array.put(JSONObject().put("start", w.startMillis).put("services", w.services).put("tips", w.tips).put("supplies", w.supplies).put("takeHome", w.takeHome)) }
        prefs.edit().putString("weeks", array.toString()).apply()
    }

    fun loadWeeks(): List<SavedWeek> {
        val raw = prefs.getString("weeks", "[]") ?: "[]"
        return runCatching {
            val a = JSONArray(raw)
            (0 until a.length()).map { i -> a.getJSONObject(i).let { SavedWeek(it.getLong("start"), it.getDouble("services"), it.getDouble("tips"), it.getDouble("supplies"), it.getDouble("takeHome")) } }
        }.getOrDefault(emptyList())
    }

    private fun sameWeek(a: Long, b: Long): Boolean {
        val week = 7L * 24 * 60 * 60 * 1000
        return kotlin.math.abs(a - b) < week / 2
    }
}
