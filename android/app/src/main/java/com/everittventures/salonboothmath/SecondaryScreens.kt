package com.everittventures.salonboothmath

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.math.BigDecimal
import java.math.RoundingMode
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
internal fun BreakdownScreen(store: AppStore, services: Long, cashTips: Long, cardTips: Long, supplies: Long, cardFees: Long, takeHome: Long, hours: String, onHoursChange: (String) -> Unit, back: () -> Unit) {
    val gross = services + cashTips + cardTips
    val workerCut = BigDecimal(store.commissionCutBasisPoints).movePointLeft(4)
    val ownerCut = if (store.payModel == "commission") services - BigDecimal.valueOf(services).multiply(workerCut).setScale(0, RoundingMode.HALF_UP).longValueExact() else store.weeklyRentCents
    val hoursValue = hours.toBigDecimalOrNull()?.takeIf { it > BigDecimal.ZERO }
    val hourly = hoursValue?.let { BigDecimal.valueOf(takeHome).divide(it, 0, RoundingMode.HALF_UP).longValueExact() }
    val tax = if (takeHome > 0) BigDecimal.valueOf(takeHome).multiply(BigDecimal(store.taxBasisPoints).movePointLeft(4)).setScale(0, RoundingMode.HALF_UP).longValueExact() else 0L
    SimpleScreen(stringResource(R.string.breakdown), back) {
        Metric(stringResource(R.string.gross), gross)
        CostRow(if (store.payModel == "commission") stringResource(R.string.house_cut) else stringResource(R.string.weekly_rent), ownerCut)
        if (cardFees > 0) CostRow(stringResource(R.string.card_fees), cardFees)
        CostRow(stringResource(R.string.supplies), supplies)
        if (store.extraFeesCents > 0) CostRow(stringResource(R.string.extra_shop_fees), store.extraFeesCents)
        HorizontalDivider()
        Metric(stringResource(R.string.take_home), takeHome)
        MoneyField(stringResource(R.string.hours_this_week), hours, false, onHoursChange)
        if (hourly != null) Metric(stringResource(R.string.per_hour), hourly)
        if (tax > 0) Metric(stringResource(R.string.tax_reserve), tax)
    }
}

@Composable
internal fun HistoryScreen(store: AppStore, onWeek: (SavedWeek) -> Unit, back: () -> Unit) {
    SimpleScreen(stringResource(R.string.history), back) {
        store.loadWeeks().take(12).forEach { week ->
            Row(
                Modifier.fillMaxWidth().clickable { onWeek(week) }.padding(vertical = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(SimpleDateFormat("MMM d", Locale.getDefault()).format(Date(week.startMillis)), fontSize = 19.sp, fontWeight = FontWeight.Bold, color = Ink)
                Text(formatCents(week.takeHomeCents), fontSize = 20.sp, fontWeight = FontWeight.ExtraBold, color = Berry)
            }
        }
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
internal fun SettingsScreen(store: AppStore, back: () -> Unit) {
    var rent by remember { mutableStateOf(inputMoney(store.rentCents)) }
    var rentPeriod by remember { mutableStateOf(store.rentPeriod) }
    var cut by remember { mutableStateOf(percentText(store.commissionCutBasisPoints)) }
    var tipOwner by remember { mutableStateOf(store.tipOwner) }
    var extra by remember { mutableStateOf(inputMoney(store.extraFeesCents)) }
    var paysFees by remember { mutableStateOf(store.workerPaysCardFees) }
    var cardFee by remember { mutableStateOf(percentText(store.cardFeeBasisPoints)) }
    var cardShare by remember { mutableStateOf(percentText(store.servicesOnCardBasisPoints)) }
    var tax by remember { mutableStateOf(percentText(store.taxBasisPoints)) }

    SimpleScreen(stringResource(R.string.settings), back) {
        if (store.payModel == "booth") {
            MoneyField(stringResource(R.string.weekly_rent), rent) { rent = it }
            SingleChoiceSegment(listOf("week" to stringResource(R.string.week), "month" to stringResource(R.string.month)), rentPeriod) { rentPeriod = it }
        } else {
            MoneyField(stringResource(R.string.your_cut), cut, false) { cut = it }
            Text(stringResource(R.string.who_keeps_tips), color = Ink, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold)
            SingleChoiceSegment(listOf(TipOwner.YOU.name to stringResource(R.string.tips_you), TipOwner.HOUSE.name to stringResource(R.string.tips_house), TipOwner.SPLIT.name to stringResource(R.string.tips_split)), tipOwner.name) { tipOwner = TipOwner.valueOf(it) }
            SettingToggle(stringResource(R.string.worker_card_fees), paysFees) { paysFees = it }
        }
        MoneyField(stringResource(R.string.card_fee_percent), cardFee, false) { cardFee = it }
        MoneyField(stringResource(R.string.services_on_card), cardShare, false) { cardShare = it }
        MoneyField(stringResource(R.string.extra_shop_fees), extra) { extra = it }
        MoneyField(stringResource(R.string.tax_set_aside), tax, false) { tax = it }
        Text(stringResource(R.string.estimate_disclaimer), color = Berry, fontSize = 16.sp, fontWeight = FontWeight.Bold)
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
