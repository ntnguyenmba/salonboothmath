package com.everittventures.salonboothmath

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.math.BigDecimal
import java.math.RoundingMode
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

internal val Berry = Color(0xFF4B0728)
internal val BerryDeep = Color(0xFF2D0418)
internal val Surface = Color(0xFF65103B)
internal val Ink = Color.White
internal val MutedInk = Color.White.copy(alpha = 0.78f)
internal val Pink = Color(0xFFFF3D6E)
internal val Warning = Color(0xFFFFB86B)
internal val Page = Berry
internal val AppFontFamily = FontFamily.SansSerif

@Composable
internal fun SimpleScreen(title: String, back: () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    Column(
        Modifier
            .fillMaxSize()
            .background(Page)
            .padding(22.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        TextButton(onClick = back) {
            Text("‹ ${stringResource(R.string.this_week)}", color = Color.White, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
        }
        Text(title, color = Ink, fontSize = 32.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
        content()
    }
}

@Composable
internal fun Metric(label: String, value: Long) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(label, color = Pink, fontSize = 18.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
        Text(formatCents(value), color = Ink, fontSize = 40.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
    }
}

@Composable
internal fun CostRow(label: String, value: Long) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = Ink, fontSize = 18.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
        Text("−${formatCents(value)}", color = Ink, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
    }
}

@Composable
internal fun MoneyField(label: String, value: String, showCurrency: Boolean = true, onValue: (String) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(9.dp)) {
        Text(label, color = Ink, fontSize = 19.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
        OutlinedTextField(
            value = value,
            onValueChange = onValue,
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            textStyle = LocalTextStyle.current.copy(fontSize = 29.sp, fontWeight = FontWeight.ExtraBold, color = Ink, fontFamily = AppFontFamily),
            modifier = Modifier.fillMaxWidth().height(68.dp),
            shape = RoundedCornerShape(18.dp),
            prefix = if (showCurrency) ({ Text(NumberFormat.getCurrencyInstance().currency?.symbol ?: "$", color = Ink, fontFamily = AppFontFamily) }) else null,
            colors = OutlinedTextFieldDefaults.colors(
                unfocusedContainerColor = Surface,
                focusedContainerColor = Surface,
                unfocusedBorderColor = Color.White.copy(alpha = .26f),
                focusedBorderColor = Pink,
                cursorColor = Pink,
                focusedTextColor = Ink,
                unfocusedTextColor = Ink
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
    ) {
        Text(label, fontSize = 19.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
    }
}

@Composable
internal fun SingleChoiceSegment(options: List<Pair<String, String>>, selected: String, onSelect: (String) -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        options.forEach { (id, label) ->
            Button(
                onClick = { onSelect(id) },
                modifier = Modifier.weight(1f).height(56.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (selected == id) Pink else Surface,
                    contentColor = Color.White
                ),
                shape = RoundedCornerShape(16.dp)
            ) {
                Text(label, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
            }
        }
    }
}

@Composable
internal fun SettingToggle(label: String, checked: Boolean, onChecked: (Boolean) -> Unit) {
    Row(
        Modifier.fillMaxWidth(),
        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, color = Ink, fontSize = 18.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily, modifier = Modifier.weight(1f))
        Switch(
            checked = checked,
            onCheckedChange = onChecked,
            colors = SwitchDefaults.colors(checkedThumbColor = Color.White, checkedTrackColor = Pink)
        )
    }
}

@Composable
internal fun payContext(store: AppStore): String = if (store.payModel == "booth") {
    val suffix = if (store.rentPeriod == "month") stringResource(R.string.month) else stringResource(R.string.week)
    "${stringResource(R.string.booth_rent)} · ${formatCents(store.weeklyRentCents)}/$suffix"
} else {
    stringResource(R.string.keep_cut, store.commissionCutBasisPoints / 100)
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
internal fun weekRange(startMillis: Long): String {
    val start = Calendar.getInstance().apply { timeInMillis = startMillis }
    val end = (start.clone() as Calendar).apply { add(Calendar.DAY_OF_MONTH, 6) }
    val startFormat = SimpleDateFormat("MMM d", Locale.getDefault())
    val endFormat = if (start.get(Calendar.MONTH) == end.get(Calendar.MONTH)) SimpleDateFormat("d", Locale.getDefault()) else SimpleDateFormat("MMM d", Locale.getDefault())
    return "${startFormat.format(Date(startMillis))}–${endFormat.format(end.timeInMillis)}"
}
