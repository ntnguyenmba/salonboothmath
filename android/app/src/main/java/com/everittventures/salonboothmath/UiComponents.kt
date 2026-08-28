package com.everittventures.salonboothmath

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.math.BigDecimal
import java.math.RoundingMode
import java.text.NumberFormat
import java.util.Calendar

internal val Berry = Color(0xFF4A1835)
internal val Ink = Color(0xFF0B1220)
internal val Pink = Color(0xFFFF3D6E)
internal val Warning = Color(0xFFC2410C)
internal val Page = Color.White

@Composable
internal fun SimpleScreen(title: String, back: () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    Column(Modifier.fillMaxSize().background(Page).padding(22.dp).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(20.dp)) {
        TextButton(onClick = back) { Text("‹ ${stringResource(R.string.this_week)}", color = Berry, fontWeight = FontWeight.ExtraBold) }
        Text(title, color = Ink, fontSize = 32.sp, fontWeight = FontWeight.ExtraBold)
        content()
    }
}

@Composable
internal fun Metric(label: String, value: Long) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(label, color = Berry, fontSize = 18.sp, fontWeight = FontWeight.Bold)
        Text(formatCents(value), color = Ink, fontSize = 40.sp, fontWeight = FontWeight.ExtraBold)
    }
}

@Composable
internal fun CostRow(label: String, value: Long) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = Ink, fontSize = 18.sp, fontWeight = FontWeight.Bold)
        Text("−${formatCents(value)}", color = Ink, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold)
    }
}

@Composable
internal fun MoneyField(label: String, value: String, showCurrency: Boolean = true, onValue: (String) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(9.dp)) {
        Text(label, color = Ink, fontSize = 19.sp, fontWeight = FontWeight.ExtraBold)
        OutlinedTextField(
            value = value,
            onValueChange = onValue,
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            textStyle = LocalTextStyle.current.copy(fontSize = 29.sp, fontWeight = FontWeight.ExtraBold, color = Ink),
            modifier = Modifier.fillMaxWidth().height(68.dp),
            shape = RoundedCornerShape(18.dp),
            prefix = if (showCurrency) ({ Text(NumberFormat.getCurrencyInstance().currency?.symbol ?: "$") }) else null,
            colors = OutlinedTextFieldDefaults.colors(
                unfocusedContainerColor = Color.White,
                focusedContainerColor = Color.White,
                unfocusedBorderColor = Ink.copy(alpha = .42f),
                focusedBorderColor = Pink,
                cursorColor = Berry
            )
        )
    }
}

@Composable
internal fun PrimaryButton(label: String, action: () -> Unit) {
    Button(
        onClick = action,
        colors = ButtonDefaults.buttonColors(containerColor = Pink, contentColor = Color.White),
        modifier = Modifier.fillMaxWidth().height(62.dp),
        shape = RoundedCornerShape(18.dp)
    ) { Text(label, fontSize = 19.sp, fontWeight = FontWeight.ExtraBold) }
}

@Composable
internal fun SingleChoiceSegment(options: List<Pair<String, String>>, selected: String, onSelect: (String) -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        options.forEach { (id, label) ->
            Button(
                onClick = { onSelect(id) },
                modifier = Modifier.weight(1f).height(56.dp),
                colors = ButtonDefaults.buttonColors(containerColor = if (selected == id) Berry else Color.White, contentColor = if (selected == id) Color.White else Ink),
                border = if (selected == id) null else ButtonDefaults.outlinedButtonBorder,
                shape = RoundedCornerShape(16.dp)
            ) { Text(label, fontWeight = FontWeight.ExtraBold) }
        }
    }
}

@Composable
internal fun SettingToggle(label: String, checked: Boolean, onChecked: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = androidx.compose.ui.Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = Ink, fontSize = 18.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
        Switch(checked = checked, onCheckedChange = onChecked, colors = SwitchDefaults.colors(checkedThumbColor = Color.White, checkedTrackColor = Berry))
    }
}

@Composable
internal fun payContext(store: AppStore): String = if (store.payModel == "booth") {
    val suffix = if (store.rentPeriod == "month") stringResource(R.string.month) else stringResource(R.string.week)
    "${stringResource(R.string.booth_rent)} · ${formatCents(store.rentCents)}/$suffix"
} else {
    val tips = when (store.tipOwner) {
        TipOwner.YOU -> stringResource(R.string.tips_you)
        TipOwner.HOUSE -> stringResource(R.string.tips_house)
        TipOwner.SPLIT -> stringResource(R.string.tips_split)
    }
    "${store.commissionCutBasisPoints / 100}% · $tips"
}

internal fun formatCents(cents: Long): String = NumberFormat.getCurrencyInstance().format(BigDecimal.valueOf(cents, 2))
internal fun inputMoney(cents: Long): String = BigDecimal.valueOf(cents, 2).stripTrailingZeros().toPlainString()
internal fun cleanDecimal(value: Double): String = BigDecimal.valueOf(value).stripTrailingZeros().toPlainString()
internal fun percentText(basisPoints: Int): String = BigDecimal(basisPoints).movePointLeft(2).stripTrailingZeros().toPlainString()
internal fun percentBasisPoints(text: String, fallback: String): Int {
    val normalized = text.trim().replace(',', '.')
    val percent = normalized.toBigDecimalOrNull() ?: BigDecimal(fallback)
    return percent.multiply(BigDecimal("100")).setScale(0, RoundingMode.HALF_UP).toInt()
}
internal fun startOfWeek(): Long {
    val c = Calendar.getInstance()
    c.set(Calendar.DAY_OF_WEEK, c.firstDayOfWeek)
    c.set(Calendar.HOUR_OF_DAY, 0)
    c.set(Calendar.MINUTE, 0)
    c.set(Calendar.SECOND, 0)
    c.set(Calendar.MILLISECOND, 0)
    return c.timeInMillis
}
