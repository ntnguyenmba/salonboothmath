package com.everittventures.salonboothmath

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.util.Calendar
import java.util.UUID

@Composable
internal fun FreeTryActionButton(
    title: String,
    used: Boolean,
    freeLabel: String,
    usedLabel: String,
    onClick: () -> Unit
) {
    TextButton(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth().height(68.dp)
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                title,
                color = Color.White,
                fontSize = 18.sp,
                fontWeight = FontWeight.ExtraBold,
                fontFamily = AppFontFamily
            )
            Text(
                if (used) usedLabel else freeLabel,
                color = Pink,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = AppFontFamily
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun UpgradeSheet(
    displayPrice: String,
    billingIssue: BillingIssue?,
    takeHomeCents: Long,
    onPurchase: () -> Unit,
    onRestore: () -> Unit,
    onDismiss: () -> Unit
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = BerryDeep,
        contentColor = Ink,
        dragHandle = {
            Box(
                Modifier
                    .padding(top = 10.dp, bottom = 8.dp)
                    .width(54.dp)
                    .height(6.dp)
                    .background(Pink, RoundedCornerShape(99.dp))
            )
        }
    ) {
        Column(
            Modifier.fillMaxWidth().padding(horizontal = 22.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                stringResource(R.string.unlock),
                color = Ink,
                fontSize = 26.sp,
                fontWeight = FontWeight.ExtraBold,
                fontFamily = AppFontFamily,
                maxLines = 2
            )
            if (takeHomeCents > 0) {
                Text(
                    stringResource(R.string.paywall_take_home_lead, formatCents(takeHomeCents)),
                    color = Pink,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.ExtraBold,
                    fontFamily = AppFontFamily
                )
            }
            PaywallBenefit(R.string.paywall_benefit_compare)
            PaywallBenefit(R.string.paywall_benefit_difference)
            PaywallBenefit(R.string.paywall_benefit_decisions)
            PaywallBenefit(R.string.paywall_benefit_track)
            PaywallBenefit(R.string.paywall_benefit_history)
            PaywallBenefit(R.string.paywall_benefit_no_ads)
            Text(
                "\u2022 " + stringResource(R.string.paywall_once),
                color = MutedInk,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = AppFontFamily
            )
            billingIssue?.let { issue ->
                Text(
                    stringResource(
                        when (issue) {
                            BillingIssue.CONNECTION -> R.string.billing_connection_error
                            BillingIssue.PRODUCT_UNAVAILABLE -> R.string.billing_product_unavailable
                            BillingIssue.PURCHASE_FAILED -> R.string.billing_purchase_failed
                        }
                    ),
                    color = Pink,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = AppFontFamily
                )
            }
            PrimaryButton(stringResource(R.string.unlock_price, displayPrice), onPurchase)
            TextButton(
                onClick = onRestore,
                modifier = Modifier.fillMaxWidth().height(56.dp)
            ) {
                Text(
                    stringResource(R.string.restore_purchase),
                    color = Pink,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = AppFontFamily
                )
            }
            TextButton(
                onClick = onDismiss,
                modifier = Modifier.fillMaxWidth().height(56.dp)
            ) {
                Text(
                    stringResource(R.string.not_now),
                    color = Ink,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = AppFontFamily
                )
            }
            Spacer(Modifier.height(12.dp))
        }
    }
}

@Composable
private fun PaywallBenefit(resourceId: Int) {
    Text(
        "\u2022 " + stringResource(resourceId),
        color = Ink,
        fontSize = 17.sp,
        fontWeight = FontWeight.Bold,
        fontFamily = AppFontFamily
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun AddTodaySheet(
    onDismiss: () -> Unit,
    onAdd: (DayLine) -> Unit
) {
    var services by remember { mutableStateOf("") }
    var cash by remember { mutableStateOf("") }
    var card by remember { mutableStateOf("") }
    var supplies by remember { mutableStateOf("") }
    var hours by remember { mutableStateOf("") }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = BerryDeep,
        contentColor = Ink
    ) {
        Column(
            Modifier.fillMaxWidth().padding(22.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                stringResource(R.string.add_today),
                fontSize = 27.sp,
                fontWeight = FontWeight.ExtraBold,
                fontFamily = AppFontFamily
            )
            MoneyField(stringResource(R.string.services), services) { services = it }
            MoneyField(stringResource(R.string.cash_tips), cash) { cash = it }
            MoneyField(stringResource(R.string.card_tips), card) { card = it }
            MoneyField(stringResource(R.string.supplies), supplies) { supplies = it }
            MoneyField(stringResource(R.string.hours_today_optional), hours, false) { hours = it }
            PrimaryButton(stringResource(R.string.add_to_week)) {
                val parsedHours = hours.trim().replace(',', '.').toDoubleOrNull()?.takeIf { it > 0 }
                val dayStart = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }.timeInMillis
                onAdd(
                    DayLine(
                        UUID.randomUUID().toString(),
                        dayStart,
                        MoneyMath.cents(services),
                        MoneyMath.cents(cash),
                        MoneyMath.cents(card),
                        MoneyMath.cents(supplies),
                        parsedHours
                    )
                )
            }
            TextButton(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) {
                Text(
                    stringResource(R.string.cancel),
                    color = Ink,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}
