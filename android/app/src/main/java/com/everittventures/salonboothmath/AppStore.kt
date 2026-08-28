package com.everittventures.salonboothmath

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class SavedWeek(
    val startMillis: Long,
    val servicesCents: Long,
    val cashTipsCents: Long,
    val cardTipsCents: Long,
    val suppliesCents: Long,
    val extraFeesCents: Long,
    val hours: Double?,
    val payModel: String,
    val takeHomeCents: Long
)

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

    var rentPeriod: String
        get() = prefs.getString("rentPeriod", "week") ?: "week"
        set(value) = prefs.edit().putString("rentPeriod", value).apply()

    var rentCents: Long
        get() = prefs.getLong("rentCents", 25000L)
        set(value) = prefs.edit().putLong("rentCents", value).apply()

    val weeklyRentCents: Long
        get() = MoneyMath.weeklyRent(rentCents, rentPeriod == "month")

    var commissionCutBasisPoints: Int
        get() = prefs.getInt("commissionCutBasisPoints", 5500)
        set(value) = prefs.edit().putInt("commissionCutBasisPoints", value).apply()

    var tipOwner: TipOwner
        get() = runCatching { TipOwner.valueOf(prefs.getString("tipOwner", TipOwner.YOU.name) ?: TipOwner.YOU.name) }.getOrDefault(TipOwner.YOU)
        set(value) = prefs.edit().putString("tipOwner", value.name).apply()

    var workerPaysCardFees: Boolean
        get() = prefs.getBoolean("workerPaysCardFees", false)
        set(value) = prefs.edit().putBoolean("workerPaysCardFees", value).apply()

    var cardFeeBasisPoints: Int
        get() = prefs.getInt("cardFeeBasisPoints", 290)
        set(value) = prefs.edit().putInt("cardFeeBasisPoints", value).apply()

    var servicesOnCardBasisPoints: Int
        get() = prefs.getInt("servicesOnCardBasisPoints", 7000)
        set(value) = prefs.edit().putInt("servicesOnCardBasisPoints", value).apply()

    var taxBasisPoints: Int
        get() = prefs.getInt("taxBasisPoints", 2500)
        set(value) = prefs.edit().putInt("taxBasisPoints", value).apply()

    var extraFeesCents: Long
        get() = prefs.getLong("extraFeesCents", 0L)
        set(value) = prefs.edit().putLong("extraFeesCents", value).apply()

    fun updateWidgetTakeHomeCents(amount: Long) {
        prefs.edit().putLong("widgetTakeHomeCents", amount).apply()
    }

    fun saveWeek(week: SavedWeek) {
        if (sameWeek(week.startMillis, System.currentTimeMillis())) updateWidgetTakeHomeCents(week.takeHomeCents)
        val weeks = loadWeeks().filterNot { sameWeek(it.startMillis, week.startMillis) }.toMutableList()
        weeks.add(week)
        weeks.sortByDescending { it.startMillis }
        val array = JSONArray()
        weeks.take(52).forEach { w ->
            array.put(
                JSONObject()
                    .put("start", w.startMillis)
                    .put("servicesCents", w.servicesCents)
                    .put("cashTipsCents", w.cashTipsCents)
                    .put("cardTipsCents", w.cardTipsCents)
                    .put("suppliesCents", w.suppliesCents)
                    .put("extraFeesCents", w.extraFeesCents)
                    .put("hours", w.hours)
                    .put("payModel", w.payModel)
                    .put("takeHomeCents", w.takeHomeCents)
            )
        }
        prefs.edit().putString("weeks.v3", array.toString()).apply()
    }

    fun loadWeeks(): List<SavedWeek> {
        val raw = prefs.getString("weeks.v3", "[]") ?: "[]"
        return runCatching {
            val a = JSONArray(raw)
            (0 until a.length()).map { i ->
                a.getJSONObject(i).let {
                    SavedWeek(
                        startMillis = it.getLong("start"),
                        servicesCents = it.getLong("servicesCents"),
                        cashTipsCents = it.getLong("cashTipsCents"),
                        cardTipsCents = it.getLong("cardTipsCents"),
                        suppliesCents = it.getLong("suppliesCents"),
                        extraFeesCents = it.optLong("extraFeesCents", 0L),
                        hours = if (it.has("hours") && !it.isNull("hours")) it.getDouble("hours") else null,
                        payModel = it.optString("payModel", "booth"),
                        takeHomeCents = it.getLong("takeHomeCents")
                    )
                }
            }
        }.getOrDefault(emptyList())
    }

    private fun sameWeek(a: Long, b: Long): Boolean {
        val week = 7L * 24 * 60 * 60 * 1000
        return kotlin.math.abs(a - b) < week / 2
    }
}
