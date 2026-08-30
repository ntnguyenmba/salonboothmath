package com.everittventures.salonboothmath

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class DayLine(val id: String, val dateStartMillis: Long, val servicesCents: Long, val cashTipsCents: Long, val cardTipsCents: Long, val suppliesCents: Long, val hours: Double? = null)
data class SavedWeek(val startMillis: Long, val servicesCents: Long, val cashTipsCents: Long, val cardTipsCents: Long, val suppliesCents: Long, val extraFeesCents: Long, val hours: Double?, val payModel: String, val takeHomeCents: Long, val days: List<DayLine> = emptyList())
data class CurrentWeekDraft(val weekStartMillis: Long, val services: String, val cashTips: String, val cardTips: String, val supplies: String, val hours: String, val days: List<DayLine> = emptyList())

class AppStore(context: Context) {
    private val prefs = context.getSharedPreferences("salon_booth_math", Context.MODE_PRIVATE)
    var onboardingDone: Boolean get() = prefs.getBoolean("onboardingDone", false); set(value) = prefs.edit().putBoolean("onboardingDone", value).apply()
    var trade: String get() = prefs.getString("trade", "nail") ?: "nail"; set(value) = prefs.edit().putString("trade", value).apply()
    var payModel: String get() = prefs.getString("payModel", "booth") ?: "booth"; set(value) = prefs.edit().putString("payModel", value).apply()
    var rentPeriod: String get() = prefs.getString("rentPeriod", "week") ?: "week"; set(value) = prefs.edit().putString("rentPeriod", value).apply()
    var rentCents: Long get() = prefs.getLong("rentCents", 25000L); set(value) = prefs.edit().putLong("rentCents", value).apply()
    val weeklyRentCents: Long get() = MoneyMath.weeklyRent(rentCents, rentPeriod == "month")
    var commissionCutBasisPoints: Int get() = prefs.getInt("commissionCutBasisPoints", 5500); set(value) = prefs.edit().putInt("commissionCutBasisPoints", value).apply()
    var tipOwner: TipOwner get() = runCatching { TipOwner.valueOf(prefs.getString("tipOwner", TipOwner.YOU.name) ?: TipOwner.YOU.name) }.getOrDefault(TipOwner.YOU); set(value) = prefs.edit().putString("tipOwner", value.name).apply()
    var workerPaysCardFees: Boolean get() = prefs.getBoolean("workerPaysCardFees", false); set(value) = prefs.edit().putBoolean("workerPaysCardFees", value).apply()
    var cardFeeBasisPoints: Int get() = prefs.getInt("cardFeeBasisPoints", 290); set(value) = prefs.edit().putInt("cardFeeBasisPoints", value).apply()
    var servicesOnCardBasisPoints: Int get() = prefs.getInt("servicesOnCardBasisPoints", 7000); set(value) = prefs.edit().putInt("servicesOnCardBasisPoints", value).apply()
    var taxBasisPoints: Int get() = prefs.getInt("taxBasisPoints", 2500); set(value) = prefs.edit().putInt("taxBasisPoints", value).apply()
    var extraFeesCents: Long get() = prefs.getLong("extraFeesCents", 0L); set(value) = prefs.edit().putLong("extraFeesCents", value).apply()

    fun updateWidgetTakeHomeCents(amount: Long) { prefs.edit().putLong("widgetTakeHomeCents", amount).apply() }

    fun loadCurrentWeekDraft(currentWeekStart: Long): CurrentWeekDraft {
        if (prefs.getLong("draft.weekStart", 0L) != currentWeekStart) {
            clearCurrentWeekDraft(currentWeekStart)
            return CurrentWeekDraft(currentWeekStart, "", "", "", "", "")
        }
        return CurrentWeekDraft(currentWeekStart, prefs.getString("draft.services", "") ?: "", prefs.getString("draft.cashTips", "") ?: "", prefs.getString("draft.cardTips", "") ?: "", prefs.getString("draft.supplies", "") ?: "", prefs.getString("draft.hours", "") ?: "", decodeDays(prefs.getString("draft.days", "[]") ?: "[]"))
    }

    fun saveCurrentWeekDraft(draft: CurrentWeekDraft) {
        prefs.edit().putLong("draft.weekStart", draft.weekStartMillis).putString("draft.services", draft.services).putString("draft.cashTips", draft.cashTips).putString("draft.cardTips", draft.cardTips).putString("draft.supplies", draft.supplies).putString("draft.hours", draft.hours).putString("draft.days", encodeDays(draft.days).toString()).apply()
    }

    private fun clearCurrentWeekDraft(currentWeekStart: Long) {
        prefs.edit().putLong("draft.weekStart", currentWeekStart).putString("draft.services", "").putString("draft.cashTips", "").putString("draft.cardTips", "").putString("draft.supplies", "").putString("draft.hours", "").putString("draft.days", "[]").apply()
    }

    fun saveWeek(week: SavedWeek) {
        if (sameWeek(week.startMillis, System.currentTimeMillis())) updateWidgetTakeHomeCents(week.takeHomeCents)
        val weeks = loadWeeks().filterNot { sameWeek(it.startMillis, week.startMillis) }.toMutableList(); weeks.add(week); weeks.sortByDescending { it.startMillis }
        val array = JSONArray()
        weeks.take(52).forEach { w -> array.put(JSONObject().put("start", w.startMillis).put("servicesCents", w.servicesCents).put("cashTipsCents", w.cashTipsCents).put("cardTipsCents", w.cardTipsCents).put("suppliesCents", w.suppliesCents).put("extraFeesCents", w.extraFeesCents).put("hours", w.hours).put("payModel", w.payModel).put("takeHomeCents", w.takeHomeCents).put("days", encodeDays(w.days))) }
        prefs.edit().putString("weeks.v4", array.toString()).apply()
    }

    fun loadWeeks(): List<SavedWeek> {
        val raw = prefs.getString("weeks.v4", null) ?: prefs.getString("weeks.v3", "[]") ?: "[]"
        return runCatching {
            val a = JSONArray(raw)
            (0 until a.length()).map { i -> a.getJSONObject(i).let { SavedWeek(it.getLong("start"), it.getLong("servicesCents"), it.getLong("cashTipsCents"), it.getLong("cardTipsCents"), it.getLong("suppliesCents"), it.optLong("extraFeesCents", 0L), if (it.has("hours") && !it.isNull("hours")) it.getDouble("hours") else null, it.optString("payModel", "booth"), it.getLong("takeHomeCents"), if (it.has("days")) decodeDays(it.getJSONArray("days").toString()) else emptyList()) } }
        }.getOrDefault(emptyList())
    }

    private fun encodeDays(days: List<DayLine>): JSONArray = JSONArray().also { a -> days.forEach { d -> a.put(JSONObject().put("id", d.id).put("dateStart", d.dateStartMillis).put("servicesCents", d.servicesCents).put("cashTipsCents", d.cashTipsCents).put("cardTipsCents", d.cardTipsCents).put("suppliesCents", d.suppliesCents).put("hours", d.hours)) } }
    private fun decodeDays(raw: String): List<DayLine> = runCatching { val a=JSONArray(raw); (0 until a.length()).map { i -> a.getJSONObject(i).let { DayLine(it.optString("id", java.util.UUID.randomUUID().toString()), it.getLong("dateStart"), it.optLong("servicesCents"), it.optLong("cashTipsCents"), it.optLong("cardTipsCents"), it.optLong("suppliesCents"), if(it.has("hours")&&!it.isNull("hours"))it.getDouble("hours")else null) } } }.getOrDefault(emptyList())
    private fun sameWeek(a: Long, b: Long): Boolean { val week = 7L * 24 * 60 * 60 * 1000; return kotlin.math.abs(a - b) < week / 2 }
}
