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
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.*

private val Berry = Color(0xFF4A1835)
private val Ink = Color(0xFF0B1220)
private val Pink = Color(0xFFFF3D6E)
private val Page = Color.White

enum class Screen { Home, History, Compare, Settings }

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
    if (!onboardingDone) {
        Onboarding(store) { onboardingDone = true }
    } else {
        SalonBoothHome(store, billing)
    }
}

@Composable
private fun Onboarding(store: AppStore, done: () -> Unit) {
    var step by remember { mutableIntStateOf(0) }
    var trade by remember { mutableStateOf(store.trade) }
    var pay by remember { mutableStateOf(store.payModel) }
    var value by remember { mutableStateOf(if (pay == "booth") "250" else "55") }
    val titles = listOf("What do you do?", "How do you get paid?", if (pay == "booth") "Weekly booth rent" else "Your cut", "Let’s see this week.")

    Column(Modifier.fillMaxSize().background(Page).padding(24.dp), verticalArrangement = Arrangement.Center) {
        Text(titles[step], color = Ink, fontSize = 34.sp, fontWeight = FontWeight.ExtraBold)
        Spacer(Modifier.height(30.dp))
        when (step) {
            0 -> listOf("nail" to "Nail", "hair" to "Hair", "barber" to "Barber", "esthetician" to "Esthetician").forEach { (id, label) -> Choice(label, trade == id) { trade = id } }
            1 -> listOf("booth" to "Booth rent", "commission" to "Commission").forEach { (id, label) -> Choice(label, pay == id) { pay = id; value = if (id == "booth") "250" else "55" } }
            2 -> MoneyField(if (pay == "booth") "Weekly booth rent" else "Your cut %", value) { value = it }
        }
        Spacer(Modifier.height(28.dp))
        Button(onClick = {
            if (step < 3) step++ else {
                store.trade = trade; store.payModel = pay
                if (pay == "booth") store.weeklyRent = value.toDoubleOrNull() ?: 250.0 else store.commissionCut = (value.toDoubleOrNull() ?: 55.0) / 100
                store.onboardingDone = true; done()
            }
        }, colors = ButtonDefaults.buttonColors(containerColor = Pink, contentColor = Ink), modifier = Modifier.fillMaxWidth().height(62.dp), shape = RoundedCornerShape(18.dp)) { Text(if (step == 3) "Enter this week" else "Continue", fontSize = 19.sp, fontWeight = FontWeight.ExtraBold) }
    }
}

@Composable
private fun Choice(label: String, selected: Boolean, onClick: () -> Unit) {
    Button(onClick = onClick, colors = ButtonDefaults.buttonColors(containerColor = if (selected) Berry else Color.White, contentColor = if (selected) Color.White else Ink), border = if (selected) null else ButtonDefaults.outlinedButtonBorder, modifier = Modifier.fillMaxWidth().height(64.dp).padding(bottom = 10.dp), shape = RoundedCornerShape(18.dp)) { Text(label, fontSize = 19.sp, fontWeight = FontWeight.ExtraBold) }
}

@Composable
fun SalonBoothHome(store: AppStore, billing: BillingManager) {
    var services by remember { mutableStateOf("1240") }
    var tips by remember { mutableStateOf("160") }
    var supplies by remember { mutableStateOf("45") }
    var screen by remember { mutableStateOf(Screen.Home) }
    var showPaywall by remember { mutableStateOf(false) }
    val unlocked by billing.isUnlocked.collectAsState()
    val context = LocalContext.current
    val activity = context as Activity

    val service = services.toDoubleOrNull() ?: 0.0
    val tip = tips.toDoubleOrNull() ?: 0.0
    val supply = supplies.toDoubleOrNull() ?: 0.0
    val cardFees = (tip + service * .70) * .029
    val takeHome = if (store.payModel == "commission") service * store.commissionCut + tip - cardFees - supply else service + tip - store.weeklyRent - cardFees - supply
    val money = NumberFormat.getCurrencyInstance().format(takeHome)
    fun gated(target: Screen) { if (unlocked) screen = target else showPaywall = true }

    when (screen) {
        Screen.History -> HistoryScreen(store) { screen = Screen.Home }
        Screen.Compare -> CompareScreen(store, service, tip, supply, cardFees) { screen = Screen.Home }
        Screen.Settings -> SettingsScreen(store) { screen = Screen.Home }
        Screen.Home -> Column(Modifier.fillMaxSize().background(Page).verticalScroll(rememberScrollState())) {
            Box(Modifier.fillMaxWidth().background(Berry).padding(20.dp)) { Text(stringResource(R.string.this_week), color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.ExtraBold, modifier = Modifier.align(Alignment.Center)) }
            Column(Modifier.padding(horizontal = 22.dp, vertical = 28.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
                MoneyField(stringResource(R.string.services), services) { services = it }
                MoneyField(stringResource(R.string.tips), tips) { tips = it }
                MoneyField(stringResource(R.string.supplies), supplies) { supplies = it }
                Spacer(Modifier.height(8.dp))
                Text(stringResource(R.string.you_took_home), color = Berry, fontWeight = FontWeight.ExtraBold, fontSize = 18.sp, modifier = Modifier.align(Alignment.CenterHorizontally))
                Text(money, color = Ink, fontWeight = FontWeight.ExtraBold, fontSize = 56.sp, modifier = Modifier.align(Alignment.CenterHorizontally))
                Button(onClick = { if (unlocked) store.saveWeek(SavedWeek(startOfWeek(), service, tip, supply, takeHome)) else showPaywall = true }, colors = ButtonDefaults.buttonColors(containerColor = Pink, contentColor = Ink), shape = RoundedCornerShape(18.dp), modifier = Modifier.fillMaxWidth().height(62.dp)) { Text(stringResource(R.string.save_week), fontSize = 19.sp, fontWeight = FontWeight.ExtraBold) }
                TextButton(onClick = { gated(Screen.Compare) }, modifier = Modifier.fillMaxWidth()) { Text(stringResource(R.string.breakdown), color = Berry, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold) }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedButton(onClick = { gated(Screen.Compare) }, modifier = Modifier.weight(1f).height(58.dp), shape = RoundedCornerShape(18.dp)) { Text(stringResource(R.string.compare), color = Berry, fontWeight = FontWeight.Bold) }
                    OutlinedButton(onClick = { gated(Screen.History) }, modifier = Modifier.weight(1f).height(58.dp), shape = RoundedCornerShape(18.dp)) { Text(stringResource(R.string.history), color = Berry, fontWeight = FontWeight.Bold) }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedButton(onClick = { val intent = Intent(Intent.ACTION_SEND).apply { type = "text/plain"; putExtra(Intent.EXTRA_TEXT, "${context.getString(R.string.you_took_home)} $money\nSalon Booth Math") }; context.startActivity(Intent.createChooser(intent, context.getString(R.string.share))) }, modifier = Modifier.weight(1f)) { Text(stringResource(R.string.share), color = Berry, fontWeight = FontWeight.Bold) }
                    OutlinedButton(onClick = { screen = Screen.Settings }, modifier = Modifier.weight(1f)) { Text(stringResource(R.string.settings), color = Berry, fontWeight = FontWeight.Bold) }
                }
            }
        }
    }

    if (showPaywall) AlertDialog(onDismissRequest = { showPaywall = false }, title = { Text(stringResource(R.string.unlock), fontWeight = FontWeight.ExtraBold) }, text = { Text(stringResource(R.string.paywall_body)) }, confirmButton = { Button(onClick = { billing.launchPurchase(activity) }, colors = ButtonDefaults.buttonColors(containerColor = Pink, contentColor = Ink)) { Text("$4.99", fontWeight = FontWeight.ExtraBold) } }, dismissButton = { Column { TextButton(onClick = { billing.restore() }) { Text("Restore Purchase") }; TextButton(onClick = { showPaywall = false }) { Text("Not now") } } })
}

@Composable private fun HistoryScreen(store: AppStore, back: () -> Unit) { SimpleScreen("Past weeks", back) { store.loadWeeks().take(12).forEach { w -> Text("${SimpleDateFormat("MMM d", Locale.getDefault()).format(Date(w.startMillis))}   ${NumberFormat.getCurrencyInstance().format(w.takeHome)}", fontSize = 20.sp, fontWeight = FontWeight.ExtraBold, color = Ink) } } }
@Composable private fun CompareScreen(store: AppStore, services: Double, tips: Double, supplies: Double, cardFees: Double, back: () -> Unit) { val booth = services + tips - store.weeklyRent - cardFees - supplies; val commission = services * store.commissionCut + tips - cardFees - supplies; SimpleScreen("Same week, other deal", back) { Metric("On booth", booth); Metric("On ${(store.commissionCut * 100).toInt()}% commission", commission) } }
@Composable private fun SettingsScreen(store: AppStore, back: () -> Unit) { var rent by remember { mutableStateOf(store.weeklyRent.toInt().toString()) }; var cut by remember { mutableStateOf((store.commissionCut * 100).toInt().toString()) }; SimpleScreen("Settings", back) { MoneyField("Weekly booth rent", rent) { rent = it }; MoneyField("Commission cut %", cut) { cut = it }; Button(onClick = { store.weeklyRent = rent.toDoubleOrNull() ?: 250.0; store.commissionCut = (cut.toDoubleOrNull() ?: 55.0) / 100; back() }, colors = ButtonDefaults.buttonColors(containerColor = Pink, contentColor = Ink), modifier = Modifier.fillMaxWidth().height(60.dp)) { Text("Save settings", fontWeight = FontWeight.ExtraBold) } } }
@Composable private fun SimpleScreen(title: String, back: () -> Unit, content: @Composable ColumnScope.() -> Unit) { Column(Modifier.fillMaxSize().background(Page).padding(22.dp).verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(20.dp)) { TextButton(onClick = back) { Text("‹ This week", color = Berry, fontWeight = FontWeight.ExtraBold) }; Text(title, color = Ink, fontSize = 32.sp, fontWeight = FontWeight.ExtraBold); content() } }
@Composable private fun Metric(label: String, value: Double) { Column { Text(label, color = Berry, fontSize = 18.sp, fontWeight = FontWeight.Bold); Text(NumberFormat.getCurrencyInstance().format(value), color = Ink, fontSize = 40.sp, fontWeight = FontWeight.ExtraBold) } }
@Composable private fun MoneyField(label: String, value: String, onValue: (String) -> Unit) { Column(verticalArrangement = Arrangement.spacedBy(8.dp)) { Text(label, color = Ink, fontSize = 20.sp, fontWeight = FontWeight.ExtraBold); OutlinedTextField(value = value, onValueChange = onValue, singleLine = true, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal), textStyle = LocalTextStyle.current.copy(fontSize = 30.sp, fontWeight = FontWeight.ExtraBold, color = Ink), modifier = Modifier.fillMaxWidth().height(68.dp), shape = RoundedCornerShape(18.dp)) } }
private fun startOfWeek(): Long { val c = Calendar.getInstance(); c.set(Calendar.DAY_OF_WEEK, c.firstDayOfWeek); c.set(Calendar.HOUR_OF_DAY, 0); c.set(Calendar.MINUTE, 0); c.set(Calendar.SECOND, 0); c.set(Calendar.MILLISECOND, 0); return c.timeInMillis }
