package com.everittventures.salonboothmath

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.math.BigDecimal

@Composable internal fun DecisionsScreen(
    store: AppStore,
    services: Long,
    cashTips: Long,
    cardTips: Long,
    supplies: Long,
    isUnlocked: Boolean,
    onRequestUnlock: () -> Unit,
    back: () -> Unit
) {
    val cut = BigDecimal(store.commissionCutBasisPoints).movePointLeft(4)
    val feeRate = BigDecimal(store.cardFeeBasisPoints).movePointLeft(4)
    val cardShare = BigDecimal(store.servicesOnCardBasisPoints).movePointLeft(4)
    var targetText by remember { mutableStateOf("") }
    val targetCents = MoneyMath.cents(targetText)
    val required = if (targetCents > 0) MoneyMath.requiredServicesBooth(
        targetCents, cashTips, cardTips, store.weeklyRentCents, supplies, store.extraFeesCents, feeRate, cardShare
    ) else 0L
    val maxRent = MoneyMath.maxRentToBeatCommission(
        services, cashTips, cardTips, supplies, cut, store.tipOwner, store.workerPaysCardFees, store.extraFeesCents, feeRate, cardShare
    )
    val breakEvenBp = MoneyMath.breakEvenCutBasisPoints(
        services, cashTips, cardTips, supplies, store.weeklyRentCents, store.tipOwner, store.workerPaysCardFees, store.extraFeesCents, feeRate, cardShare
    )
    SimpleScreen(stringResource(R.string.decisions), back) {
        Text(stringResource(R.string.decisions_subtitle), color = MutedInk, fontSize = 17.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
        Spacer(Modifier.height(8.dp))
        DecisionCard {
            Text(stringResource(R.string.decisions_need_sales_title), color = Ink, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
            Text(stringResource(R.string.decisions_need_sales_hint), color = MutedInk, fontSize = 16.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
            MoneyField(stringResource(R.string.decisions_target_take_home), targetText) { targetText = it }
            if (targetCents > 0) {
                Text(stringResource(R.string.decisions_need_sales_result), color = MutedInk, fontSize = 16.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
                Text(formatCents(required), color = Pink, fontSize = 32.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
            }
        }
        DecisionCard {
            Text(stringResource(R.string.decisions_max_rent_title), color = Ink, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
            Text(stringResource(R.string.decisions_max_rent_hint), color = MutedInk, fontSize = 16.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
            Text(stringResource(R.string.decisions_max_rent_result), color = MutedInk, fontSize = 16.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
            Text("${formatCents(maxRent)}/${stringResource(R.string.week)}", color = Pink, fontSize = 32.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
        }
        DecisionCard {
            Text(stringResource(R.string.decisions_break_even_cut_title), color = Ink, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
            Text(stringResource(R.string.decisions_break_even_cut_hint), color = MutedInk, fontSize = 16.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
            Text(stringResource(R.string.decisions_break_even_cut_result), color = MutedInk, fontSize = 16.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
            Text("${breakEvenBp / 100}%", color = Pink, fontSize = 32.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
        }

        Spacer(Modifier.height(8.dp))
        PrimaryButton(stringResource(R.string.back_to_this_week)) { back() }
        if (!isUnlocked) {
            Spacer(Modifier.height(12.dp))
            DecisionCard {
                Text(stringResource(R.string.paywall_soft_title), color = Ink, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
                Text(stringResource(R.string.paywall_soft_body), color = MutedInk, fontSize = 16.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
                Spacer(Modifier.height(4.dp))
                androidx.compose.material3.TextButton(onClick = onRequestUnlock, modifier = Modifier.fillMaxWidth()) {
                    Text(stringResource(R.string.paywall_soft_cta), color = Pink, fontSize = 17.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
                }
            }
        }
    }
}

@Composable private fun DecisionCard(content: @Composable ColumnScope.() -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Surface, RoundedCornerShape(18.dp))
            .border(2.dp, Color.White.copy(alpha = 0.22f), RoundedCornerShape(18.dp))
            .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
        content = content
    )
}
