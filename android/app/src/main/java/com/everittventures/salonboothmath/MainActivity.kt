package com.everittventures.salonboothmath

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.launch
import java.math.BigDecimal
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.*

private val Berry = Color(0xFF4A1835)
private val Ink = Color(0xFF0B1220)
private val Pink = Color(0xFFFF3D6E)
private val Warning = Color(0xFFC2410C)
private val Page = Color.White

enum class Screen { Home, Breakdown, History, Compare, Settings }

class MainActivity : ComponentActivity() {
    private lateinit var billing: BillingManager
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        billing = BillingManager(this).also { it.start() }
        setContent { MaterialTheme { SalonBoothApp(billing) } }
    }
}

@Composable
fun SalonBoothApp(billing: BillingManager) {
    val context = LocalContext.current
    val store = remember { AppStore(context) }
    var onboardingDone by remember { mutableStateOf(store.onboardingDone) }
    if (!onboardingDone) Onboarding(store) { onboardingDone = true } else SalonBoothHome(store, billing)
}

@Composable
private fun Onboarding(store: AppStore, done: () -> Unit) {
    var step by remember { mutableIntStateOf(0) }
    var trade by remember { mutableStateOf(store.trade) }
    var pay by remember { mutableStateOf(store.payModel) }
    var value by remember { mutableStateOf(if (pay == "booth") "250" else "55") }
    val title = when (step) {
        0 -> stringResource(R.string.trade_question)
        1 -> stringResource(R.string.pay_question)
        2 -> if (pay == "booth") stringResource(R.string.weekly_rent) else stringResource(R.string.your_cut)
        else -> stringResource(R.string.enter_week)
    }
    Column(Modifier.fillMaxSize().background(Page).padding(24.dp), verticalArrangement = Arrangement.Center) {
        Text(title, color = Ink, fontSize = 34.sp, fontWeight = FontWeight.ExtraBold)
        Spacer(Modifier.height(30.dp))
        when (step) {
            0 -> listOf("nail" to "Nail", "hair" to "Hair", "barber" to "Barber", "esthetician" to "Esthetician").forEach { (id, label) -> Choice(label, trade == id) { trade = id } }
            1 -> listOf("booth" to "Booth rent", "commission" to "Commission").forEach { (id, label) -> Choice(label, pay == id) { pay = id; value = if (id == "booth") "250" else "55" } }
            2 -> MoneyField(if (pay == "booth") stringResource(R.string.weekly_rent) else stringResource(R.string.your_cut), value) { value = it }
        }
        Spacer(Modifier.height(28.dp))
        Button(onClick = {
            if (step < 3) step++ else {
                store.trade = trade
                store.payModel = pay
                if (pay == "booth") store.weeklyRentCents = MoneyMath.cents(value)
                else store.commissionCutBasisPoints = ((value.toBigDecimalOrNull() ?: BigDecimal("55")) * BigDecimal("100")).toInt()
                store.onboardingDone = true
                done()
            }
        }, colors = ButtonDefaults.buttonColors(containerColor = Pink, contentColor = Ink), modifier = Modifier.fillMaxWidth().height(62.dp), shape = RoundedCornerShape(18.dp)) {
            Text(if (step == 3) stringResource(R.string.enter_week) else stringResource(R.string.continue_label), fontSize = 19.sp, fontWeight = FontWeight.ExtraBold)
        }
    }
}

@Composable private fun Choice(label: String, selected: Boolean, onClick: () -> Unit) {
    Button(onClick = onClick, colors = ButtonDefaults.buttonColors(containerColor = if (selected) Berry else Color.White, contentColor = if (selected) Color.White else Ink), border = if (selected) null else ButtonDefaults.outlinedButtonBorder, modifier = Modifier.fillMaxWidth().height(64.dp).padding(bottom = 10.dp), shape = RoundedCornerShape(18.dp)) { Text(label, fontSize = 19.sp, fontWeight = FontWeight.ExtraBold) }
}

@Composable
fun SalonBoothHome(store: AppStore, billing: BillingManager) {
    var services by remember { mutableStateOf("") }
    var cashTips by remember { mutableStateOf("") }
    var cardTips by remember { mutableStateOf("") }
    var supplies by remember { mutableStateOf("") }
    var screen by remember { mutableStateOf(Screen.Home) }
    var showPaywall by remember { mutableStateOf(false) }
    val unlocked by billing.isUnlocked.collectAsState()
    val displayPrice by billing.displayPrice.collectAsState()
    val context = LocalContext.current
    val activity = context as Activity
    val scope = rememberCoroutineScope()

    val serviceCents = MoneyMath.cents(services)
    val cashTipsCents = MoneyMath.cents(cashTips)
    val cardTipsCents = MoneyMath.cents(cardTips)
    val supplyCents = MoneyMath.cents(supplies)
    val cut = BigDecimal(store.commissionCutBasisPoints).movePointLeft(4)
    val feeRate = BigDecimal(store.cardFeeBasisPoints).movePointLeft(4)
    val cardShare = BigDecimal(store.servicesOnCardBasisPoints).movePointLeft(4)
    val cardFeesCents = if (store.payModel == "booth" || store.workerPaysCardFees) MoneyMath.cardFees(serviceCents, cardTipsCents, feeRate, cardShare) else 0L
    val takeHomeCents = if (store.payModel == "commission") {
        MoneyMath.commissionTakeHome(serviceCents, cashTipsCents, cardTipsCents, supplyCents, cut, workerPaysCardFees = store.workerPaysCardFees, extraFeesCents = store.extraFeesCents, cardFeeRate = feeRate, percentServicesOnCard = cardShare)
    } else {
        MoneyMath.boothTakeHome(serviceCents, cashTipsCents, cardTipsCents, supplyCents, store.weeklyRentCents, store.extraFeesCents, feeRate, cardShare)
    }
    val money = formatCents(takeHomeCents)
    val grossCents = serviceCents + cashTipsCents + cardTipsCents
    val highRent = store.payModel == "booth" && grossCents > 0 && store.weeklyRentCents * 100 >= grossCents * 40
    fun gated(target: Screen) { if (unlocked) screen = target else showPaywall = true }

    LaunchedEffect(takeHomeCents) {
        store.updateWidgetTakeHomeCents(takeHomeCents)
        TakeHomeWidget().updateAll(context)
    }

    when (screen) {
        Screen.Breakdown -> BreakdownScreen(store, serviceCents, cashTipsCents, cardTipsCents, supplyCents, cardFeesCents, takeHomeCents) { screen = Screen.Home }
        Screen.History -> HistoryScreen(store) { screen = Screen.Home }
        Screen.Compare -> CompareScreen(store, serviceCents, cashTipsCents, cardTipsCents, supplyCents) { screen = Screen.Home }
        Screen.Settings -> SettingsScreen(store) { screen = Screen.Home }
        Screen.Home -> Column(Modifier.fillMaxSize().background(Page).verticalScroll(rememberScrollState())) {
            Box(Modifier.fillMaxWidth().background(Berry).padding(20.dp)) { Text(stringResource(R.string.this_week), color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.ExtraBold, modifier = Modifier.align(Alignment.Center)) }
            Column(Modifier.padding(horizontal = 22.dp, vertical = 28.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
                MoneyField(stringResource(R.string.services), services) { services = it }
                MoneyField(stringResource(R.string.cash_tips), cashTips) { cashTips = it }
                MoneyField(stringResource(R.string.card_tips), cardTips) { cardTips = it }
                MoneyField(stringResource(R.string.supplies), supplies) { supplies = it }
                Spacer(Modifier.height(8.dp))
                Text(stringResource(R.string.you_took_home), color = Berry, fontWeight = FontWeight.ExtraBold, fontSize = 18.sp, modifier = Modifier.align(Alignment.CenterHorizontally))
                Text(money, color = Ink, fontWeight = FontWeight.ExtraBold, fontSize = 56.sp, modifier = Modifier.align(Alignment.CenterHorizontally))
                if (highRent) Text(stringResource(R.string.rent_warning), color = Warning, fontSize = 17.sp, fontWeight = FontWeight.ExtraBold)
                Button(onClick = {
                    if (unlocked) {
                        store.saveWeek(SavedWeek(startOfWeek(), serviceCents, cashTipsCents, cardTipsCents, supplyCents, store.extraFeesCents, takeHomeCents))
                        scope.launch { TakeHomeWidget().updateAll(context) }
                    } else showPaywall = true
                }, colors = ButtonDefaults.buttonColors(containerColor = Pink, contentColor = Ink), shape = RoundedCornerShape(18.dp), modifier = Modifier.fillMaxWidth().height(62.dp)) { Text(stringResource(R.string.save_week), fontSize = 19.sp, fontWeight = FontWeight.ExtraBold) }
                TextButton(onClick = { screen = Screen.Breakdown }, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.breakdown), color = Berry, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold) }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedButton(onClick = { gated(Screen.Compare) }, modifier = Modifier.weight(1f).height(58.dp), shape = RoundedCornerShape(18.dp)) { Text(stringResource(R.string.compare), color = Berry, fontWeight = FontWeight.Bold) }
                    OutlinedButton(onClick = { gated(Screen.History) }, modifier = Modifier.weight(1f).height(58.dp), shape = RoundedCornerShape(18.dp)) { Text(stringResource(R.string.history), color = Berry, fontWeight = FontWeight.Bold) }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedButton(onClick = {
                        val intent = Intent(Intent.ACTION_SEND).apply { type = "text/plain"; putExtra(Intent.EXTRA_TEXT, "${context.getString(R.string.you_took_home)} $money\nSalon Booth Math") }
                        context.startActivity(Intent.createChooser(intent, context.getString(R.string.share)))
                    }, modifier = Modifier.weight(1f)) { Text(stringResource(R.string.share), color = Berry, fontWeight = FontWeight.Bold) }
                    OutlinedButton(onClick = { screen = Screen.Settings }, modifier = Modifier.weight(1f)) { Text(stringResource(R.string.settings), color = Berry, fontWeight = FontWeight.Bold) }
                }
            }
        }
    }

    if (showPaywall) AlertDialog(
        onDismissRequest = { showPaywall = false },
        title = { Text(stringResource(R.string.unlock), fontWeight = FontWeight.ExtraBold) },
        text = { Text(stringResource(R.string.paywall_body, displayPrice)) },
        confirmButton = { Button(onClick = { billing.launchPurchase(activity) }, colors = ButtonDefaults.buttonColors(containerColor = Pink, contentColor = Ink)) { Text(stringResource(R.string.unlock_price, displayPrice), fontWeight = FontWeight.ExtraBold) } },
        dismissButton = { Column { TextButton(onClick = { billing.restore() }) { Text(stringResource(R.string.restore_purchase)) }; TextButton(onClick = { showPaywall = false }) { Text(stringResource(R.string.not_now)) } } }
    )
}

@Composable private fun BreakdownScreen(store: AppStore, services: Long, cashTips: Long, cardTips: Long, supplies: Long, cardFees: Long, takeHome: Long, back: () -> Unit) {
    val gross = services + cashTips + cardTips
    val mainCost = if (store.payModel == "commission") BigDecimal.valueOf(services).multiply(BigDecimal.ONE.subtract(BigDecimal(store.commissionCutBasisPoints).movePointLeft(4))).setScale(0, java.math.RoundingMode.HALF_UP).longValueExact() else store.weeklyRentCents
    SimpleScreen(stringResource(R.string.breakdown), back) {
        Metric(stringResource(R.string.gross), gross)
        CostRow(if (store.payModel == "commission") stringResource(R.string.house_cut) else stringResource(R.string.weekly_rent), mainCost)
        if (cardFees > 0) CostRow(stringResource(R.string.card_fees), cardFees)
        CostRow(stringResource(R.string.supplies), supplies)
        if (store.extraFeesCents > 0) CostRow(stringResource(R.string.extra_shop_fees), store.extraFeesCents)
        HorizontalDivider()
        Metric(stringResource(R.string.take_home), takeHome)
    }
}

@Composable private fun CostRow(label: String, value: Long) { Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) { Text(label, color = Ink, fontSize = 18.sp, fontWeight = FontWeight.Bold); Text("−${formatCents(value)}", color = Ink, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold) } }
@Composable private fun HistoryScreen(store: AppStore, back: () -> Unit) { SimpleScreen(stringResource(R.string.history), back) { store.loadWeeks().take(12).forEach { w -> Text("${SimpleDateFormat("MMM d", Locale.getDefault()).format(Date(w.startMillis))}   ${formatCents(w.takeHomeCents)}", fontSize = 20.sp, fontWeight = FontWeight.ExtraBold, color = Ink) } } }
@Composable private fun CompareScreen(store: AppStore, services: Long, cashTips: Long, cardTips: Long, supplies: Long, back: () -> Unit) { val feeRate = BigDecimal(store.cardFeeBasisPoints).movePointLeft(4); val cardShare = BigDecimal(store.servicesOnCardBasisPoints).movePointLeft(4); val booth = MoneyMath.boothTakeHome(services, cashTips, cardTips, supplies, store.weeklyRentCents, store.extraFeesCents, feeRate, cardShare); val commission = MoneyMath.commissionTakeHome(services, cashTips, cardTips, supplies, BigDecimal(store.commissionCutBasisPoints).movePointLeft(4), workerPaysCardFees = store.workerPaysCardFees, extraFeesCents = store.extraFeesCents, cardFeeRate = feeRate, percentServicesOnCard = cardShare); SimpleScreen(stringResource(R.string.compare), back) { Metric("On booth", booth); Metric("On ${store.commissionCutBasisPoints / 100}% commission", commission) } }
@Composable private fun SettingsScreen(store: AppStore, back: () -> Unit) { var rent by remember { mutableStateOf((store.weeklyRentCents / 100.0).toString()) }; var cut by remember { mutableStateOf((store.commissionCutBasisPoints / 100.0).toString()) }; var extra by remember { mutableStateOf((store.extraFeesCents / 100.0).toString()) }; var paysFees by remember { mutableStateOf(store.workerPaysCardFees) }; SimpleScreen(stringResource(R.string.settings), back) { MoneyField(stringResource(R.string.weekly_rent), rent) { rent = it }; MoneyField(stringResource(R.string.your_cut), cut) { cut = it }; MoneyField(stringResource(R.string.extra_shop_fees), extra) { extra = it }; Row(verticalAlignment = Alignment.CenterVertically) { Checkbox(checked = paysFees, onCheckedChange = { paysFees = it }); Text(stringResource(R.string.worker_card_fees), color = Ink, fontWeight = FontWeight.Bold) }; Button(onClick = { store.weeklyRentCents = MoneyMath.cents(rent); store.commissionCutBasisPoints = ((cut.toBigDecimalOrNull() ?: BigDecimal("55")) * BigDecimal("100")).toInt(); store.extraFeesCents = MoneyMath.cents(extra); store.workerPaysCardFees = paysFees; back() }, colors = ButtonDefaults.buttonColors(containerColor = Pink, contentColor = Ink), modifier = Modifier.fillMaxWidth().height(60.dp)) { Text(stringResource(R.string.settings), fontWeight = FontWeight.ExtraBold) } } }
@Composable private fun SimpleScreen(title: String, back: () -> Unit, content: @Composable ColumnScope.() -> Unit) { Column(Modifier.fillMaxSize().background(Page).padding(22.dp).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(20.dp)) { TextButton(onClick = back) { Text("‹ ${stringResource(R.string.this_week)}", color = Berry, fontWeight = FontWeight.ExtraBold) }; Text(title, color = Ink, fontSize = 32.sp, fontWeight = FontWeight.ExtraBold); content() } }
@Composable private fun Metric(label: String, value: Long) { Column { Text(label, color = Berry, fontSize = 18.sp, fontWeight = FontWeight.Bold); Text(formatCents(value), color = Ink, fontSize = 40.sp, fontWeight = FontWeight.ExtraBold) } }
@Composable private fun MoneyField(label: String, value: String, onValue: (String) -> Unit) { Column(verticalArrangement = Arrangement.spacedBy(8.dp)) { Text(label, color = Ink, fontSize = 20.sp, fontWeight = FontWeight.ExtraBold); OutlinedTextField(value = value, onValueChange = onValue, singleLine = true, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal), textStyle = LocalTextStyle.current.copy(fontSize = 30.sp, fontWeight = FontWeight.ExtraBold, color = Ink), modifier = Modifier.fillMaxWidth().height(68.dp), shape = RoundedCornerShape(18.dp)) } }
private fun formatCents(cents: Long): String = NumberFormat.getCurrencyInstance().format(BigDecimal.valueOf(cents, 2))
private fun startOfWeek(): Long { val c = Calendar.getInstance(); c.set(Calendar.DAY_OF_WEEK, c.firstDayOfWeek); c.set(Calendar.HOUR_OF_DAY, 0); c.set(Calendar.MINUTE, 0); c.set(Calendar.SECOND, 0); c.set(Calendar.MILLISECOND, 0); return c.timeInMillis }
