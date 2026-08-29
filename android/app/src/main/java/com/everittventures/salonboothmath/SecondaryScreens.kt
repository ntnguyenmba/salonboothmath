package com.everittventures.salonboothmath

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.os.LocaleListCompat
import java.math.BigDecimal
import java.math.RoundingMode
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
internal fun BreakdownScreen(store: AppStore, services: Long, cashTips: Long, cardTips: Long, supplies: Long, cardFees: Long, takeHome: Long, back: () -> Unit) {
    val gross = services + cashTips + cardTips
    val workerCut = BigDecimal(store.commissionCutBasisPoints).movePointLeft(4)
    val ownerCut = if (store.payModel == "commission") services - BigDecimal.valueOf(services).multiply(workerCut).setScale(0, RoundingMode.HALF_UP).longValueExact() else store.weeklyRentCents
    val tax = if (takeHome > 0) BigDecimal.valueOf(takeHome).multiply(BigDecimal(store.taxBasisPoints).movePointLeft(4)).setScale(0, RoundingMode.HALF_UP).longValueExact() else 0L
    SimpleScreen(stringResource(R.string.breakdown), back) {
        Metric(stringResource(R.string.gross), gross)
        CostRow(if (store.payModel == "commission") stringResource(R.string.house_cut) else stringResource(R.string.weekly_rent), ownerCut)
        if (cardFees > 0) CostRow(stringResource(R.string.card_fees), cardFees)
        CostRow(stringResource(R.string.supplies), supplies)
        if (store.extraFeesCents > 0) CostRow(stringResource(R.string.extra_shop_fees), store.extraFeesCents)
        HorizontalDivider(color = MutedInk)
        Metric(stringResource(R.string.take_home), takeHome)
        if (tax > 0) Metric(stringResource(R.string.tax_reserve), tax)
    }
}

@Composable
internal fun HistoryScreen(store: AppStore, onWeek: (SavedWeek) -> Unit, back: () -> Unit) {
    val weeks = store.loadWeeks()
    val recent = weeks.take(4)
    val total = recent.sumOf { it.takeHomeCents }
    val average = if (recent.isEmpty()) 0L else total / recent.size
    val hourlyWeeks = recent.filter { (it.hours ?: 0.0) > 0.0 }
    val totalHours = hourlyWeeks.sumOf { it.hours ?: 0.0 }
    val hourly = if (totalHours > 0) (hourlyWeeks.sumOf { it.takeHomeCents } / totalHours).toLong() else null

    SimpleScreen(stringResource(R.string.history), back) {
        if (weeks.isNotEmpty()) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Box(Modifier.weight(1f)) { HistoryMetric(stringResource(R.string.last_four_weeks), total) }
                Box(Modifier.weight(1f)) { HistoryMetric(stringResource(R.string.average_week), average) }
            }
            if (hourly != null) HistoryMetric(stringResource(R.string.average_hourly), hourly, "/hr")
            Text(stringResource(R.string.take_home_trend), fontSize = 17.sp, fontWeight = FontWeight.Bold, color = Ink, fontFamily = AppFontFamily)
            HistoryTrend(recent.reversed().map { it.takeHomeCents })
        }

        weeks.take(12).forEach { week ->
            Row(Modifier.fillMaxWidth().clickable { onWeek(week) }.padding(vertical = 16.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(SimpleDateFormat("MMM d", Locale.getDefault()).format(Date(week.startMillis)), fontSize = 19.sp, fontWeight = FontWeight.Bold, color = Ink, fontFamily = AppFontFamily)
                Text(formatCents(week.takeHomeCents), fontSize = 20.sp, fontWeight = FontWeight.ExtraBold, color = Ink, fontFamily = AppFontFamily)
            }
        }
    }
}

@Composable
private fun HistoryMetric(label: String, cents: Long, suffix: String = "") {
    Column(Modifier.fillMaxWidth().padding(vertical = 6.dp)) {
        Text(label, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = MutedInk, fontFamily = AppFontFamily)
        Text(formatCents(cents) + suffix, fontSize = 23.sp, fontWeight = FontWeight.ExtraBold, color = Ink, fontFamily = AppFontFamily)
    }
}

@Composable
private fun HistoryTrend(values: List<Long>) {
    Canvas(Modifier.fillMaxWidth().height(72.dp)) {
        if (values.isEmpty()) return@Canvas
        val min = values.minOrNull() ?: 0L
        val max = values.maxOrNull() ?: min
        val span = (max - min).coerceAtLeast(1L)
        val points = values.mapIndexed { index, value ->
            val x = if (values.size == 1) size.width / 2f else size.width * index / (values.size - 1).toFloat()
            val normalized = (value - min).toFloat() / span.toFloat()
            Offset(x, size.height - (normalized * (size.height - 12f)) - 6f)
        }
        for (i in 0 until points.lastIndex) drawLine(Pink, points[i], points[i + 1], strokeWidth = 8f)
        points.forEach { drawCircle(Pink, radius = 5f, center = it) }
    }
}

@Composable
internal fun CompareScreen(store: AppStore, services: Long, cashTips: Long, cardTips: Long, supplies: Long, back: () -> Unit) {
    val feeRate = BigDecimal(store.cardFeeBasisPoints).movePointLeft(4)
    val cardShare = BigDecimal(store.servicesOnCardBasisPoints).movePointLeft(4)
    val booth = MoneyMath.boothTakeHome(services, cashTips, cardTips, supplies, store.weeklyRentCents, store.extraFeesCents, feeRate, cardShare)
    val commission = MoneyMath.commissionTakeHome(services, cashTips, cardTips, supplies, BigDecimal(store.commissionCutBasisPoints).movePointLeft(4), store.tipOwner, store.workerPaysCardFees, store.extraFeesCents, feeRate, cardShare)
    SimpleScreen(stringResource(R.string.compare), back) {
        Metric(stringResource(R.string.compare_booth), booth)
        Metric(stringResource(R.string.compare_commission, store.commissionCutBasisPoints / 100), commission)
    }
}

@Composable
internal fun SettingsScreen(store: AppStore, billing: BillingManager, back: () -> Unit) {
    var rent by remember { mutableStateOf(inputMoney(store.rentCents)) }
    var rentPeriod by remember { mutableStateOf(store.rentPeriod) }
    var cut by remember { mutableStateOf(percentText(store.commissionCutBasisPoints)) }
    var tipOwner by remember { mutableStateOf(store.tipOwner) }
    var extra by remember { mutableStateOf(inputMoney(store.extraFeesCents)) }
    var paysFees by remember { mutableStateOf(store.workerPaysCardFees) }
    var cardFee by remember { mutableStateOf(percentText(store.cardFeeBasisPoints)) }
    var cardShare by remember { mutableStateOf(percentText(store.servicesOnCardBasisPoints)) }
    var tax by remember { mutableStateOf(percentText(store.taxBasisPoints)) }
    val context = LocalContext.current
    val prefs = remember { context.getSharedPreferences("salon_booth_math", Context.MODE_PRIVATE) }
    var language by remember { mutableStateOf(prefs.getString("app_language", "en") ?: "en") }

    fun open(url: String) { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }
    fun setLanguage(tag: String) {
        language = tag
        prefs.edit().putString("app_language", tag).apply()
        AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(tag))
    }

    SimpleScreen(stringResource(R.string.settings), back) {
        Text(stringResource(R.string.language), color = Ink, fontSize = 22.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
        SingleChoiceSegment(listOf("en" to "English", "es" to "Español", "vi" to "Tiếng Việt"), language, ::setLanguage)

        if (store.payModel == "booth") {
            MoneyField(stringResource(R.string.weekly_rent), rent) { rent = it }
            SingleChoiceSegment(listOf("week" to stringResource(R.string.week), "month" to stringResource(R.string.month)), rentPeriod) { rentPeriod = it }
        } else {
            MoneyField(stringResource(R.string.your_cut), cut, false) { cut = it }
            Text(stringResource(R.string.who_keeps_tips), color = Ink, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
            SingleChoiceSegment(listOf(TipOwner.YOU.name to stringResource(R.string.tips_you), TipOwner.HOUSE.name to stringResource(R.string.tips_house), TipOwner.SPLIT.name to stringResource(R.string.tips_split)), tipOwner.name) { tipOwner = TipOwner.valueOf(it) }
            SettingToggle(stringResource(R.string.worker_card_fees), paysFees) { paysFees = it }
        }
        MoneyField(stringResource(R.string.card_fee_percent), cardFee, false) { cardFee = it }
        MoneyField(stringResource(R.string.services_on_card), cardShare, false) { cardShare = it }
        MoneyField(stringResource(R.string.extra_shop_fees), extra) { extra = it }
        MoneyField(stringResource(R.string.tax_set_aside), tax, false) { tax = it }
        Text(stringResource(R.string.estimate_disclaimer), color = MutedInk, fontSize = 16.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)

        Text(stringResource(R.string.legal_support), color = Ink, fontSize = 22.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
        LegalButton(stringResource(R.string.privacy_policy)) { open("https://everittventures.com/privacy") }
        LegalButton(stringResource(R.string.terms_use)) { open("https://everittventures.com/terms") }
        LegalButton(stringResource(R.string.contact_support)) { open("mailto:support@everittventures.com?subject=Salon%20Booth%20Math%20Support") }
        LegalButton(stringResource(R.string.restore_purchase)) { billing.restore() }
        Text(stringResource(R.string.about), color = Ink, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
        Text(stringResource(R.string.about_text), color = MutedInk, fontSize = 16.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
        Text("© 2026 Everitt Ventures LLC", color = MutedInk, fontSize = 14.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)

        PrimaryButton(stringResource(R.string.save_settings)) {
            store.rentCents = MoneyMath.cents(rent)
            store.rentPeriod = rentPeriod
            store.commissionCutBasisPoints = percentBasisPoints(cut, "55")
            store.tipOwner = tipOwner
            store.extraFeesCents = MoneyMath.cents(extra)
            store.workerPaysCardFees = paysFees
            store.cardFeeBasisPoints = percentBasisPoints(cardFee, "2.9")
            store.servicesOnCardBasisPoints = percentBasisPoints(cardShare, "70")
            store.taxBasisPoints = percentBasisPoints(tax, "25")
            back()
        }
    }
}

@Composable
private fun LegalButton(label: String, action: () -> Unit) {
    TextButton(onClick = action, modifier = Modifier.fillMaxWidth()) {
        Text(label, color = Ink, fontSize = 17.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily, modifier = Modifier.fillMaxWidth())
    }
}
