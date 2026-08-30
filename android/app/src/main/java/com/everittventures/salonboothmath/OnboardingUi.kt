package com.everittventures.salonboothmath

import android.app.Activity
import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.os.LocaleListCompat

@Composable
internal fun OnboardingScreen(store: AppStore, done: () -> Unit) {
    val context = LocalContext.current
    var step by remember { mutableIntStateOf(0) }
    var trade by remember { mutableStateOf(store.trade) }
    var pay by remember { mutableStateOf(store.payModel) }
    var rent by remember { mutableStateOf("250") }
    var cut by remember { mutableStateOf("55") }
    var language by remember { mutableStateOf(store.appLanguage) }
    val title = when (step) { 0 -> stringResource(R.string.trade_question); 1 -> stringResource(R.string.pay_question); 2 -> if (pay == "commission") stringResource(R.string.your_cut) else stringResource(R.string.weekly_rent); else -> stringResource(R.string.enter_week) }
    val trades = listOf("nail" to stringResource(R.string.trade_nail), "hair" to stringResource(R.string.trade_hair), "barber" to stringResource(R.string.trade_barber), "esthetician" to stringResource(R.string.trade_esthetician))
    val payModels = listOf("booth" to stringResource(R.string.booth_rent), "commission" to stringResource(R.string.commission), "hybrid" to stringResource(R.string.hybrid))

    Column(Modifier.fillMaxSize().background(Page).padding(24.dp), verticalArrangement = Arrangement.Center) {
        SingleChoiceSegment(listOf("en" to "English", "es" to "Español", "vi" to "Tiếng Việt"), language) { tag ->
            if (tag == language) return@SingleChoiceSegment
            language = tag
            store.appLanguage = tag
            AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(tag))
            (context as? Activity)?.recreate()
        }
        Spacer(Modifier.height(20.dp))
        Text(title, color = Ink, fontSize = 34.sp, fontWeight = FontWeight.ExtraBold)
        Spacer(Modifier.height(30.dp))
        when (step) {
            0 -> trades.forEach { (id, label) -> OnboardingChoice(label, trade == id) { trade = id } }
            1 -> payModels.forEach { (id, label) -> OnboardingChoice(label, pay == id) { pay = id } }
            2 -> when (pay) {
                "booth" -> MoneyField(stringResource(R.string.weekly_rent), rent) { rent = it }
                "commission" -> MoneyField(stringResource(R.string.your_cut), cut, false) { cut = it }
                else -> { MoneyField(stringResource(R.string.weekly_rent), rent) { rent = it }; Spacer(Modifier.height(14.dp)); MoneyField(stringResource(R.string.your_cut), cut, false) { cut = it } }
            }
        }
        Spacer(Modifier.height(28.dp))
        PrimaryButton(if (step == 3) stringResource(R.string.enter_week) else stringResource(R.string.continue_label)) {
            if (step < 3) step++ else {
                store.trade = trade; store.payModel = pay
                if (pay != "commission") store.rentCents = MoneyMath.cents(rent)
                if (pay != "booth") store.commissionCutBasisPoints = percentBasisPoints(cut, "55")
                store.onboardingDone = true; done()
            }
        }
    }
}

@Composable private fun OnboardingChoice(label: String, selected: Boolean, onClick: () -> Unit) {
    val background = if (selected) Berry else Color.White
    val foreground = if (selected) Color.White else BerryDeep
    Button(
        onClick = onClick,
        colors = ButtonDefaults.buttonColors(containerColor = background, contentColor = foreground),
        border = if (selected) null else ButtonDefaults.outlinedButtonBorder,
        modifier = Modifier.fillMaxWidth().height(68.dp).padding(bottom = 10.dp),
        shape = RoundedCornerShape(18.dp)
    ) {
        Text(label, color = foreground, fontSize = 19.sp, fontWeight = FontWeight.ExtraBold)
    }
}
