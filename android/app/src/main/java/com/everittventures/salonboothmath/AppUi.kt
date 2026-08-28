package com.everittventures.salonboothmath

import android.app.Activity
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.launch
import java.math.BigDecimal

enum class Screen { Home, Breakdown, History, Compare, Settings }

@Composable
fun SalonBoothApp(billing: BillingManager) {
    val context = LocalContext.current
    val store = remember { AppStore(context) }
    var onboardingDone by remember { mutableStateOf(store.onboardingDone) }
    if (!onboardingDone) OnboardingScreen(store) { onboardingDone = true }
    else SalonBoothHome(store, billing)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SalonBoothHome(store: AppStore, billing: BillingManager) {
    var services by remember { mutableStateOf("") }
    var cashTips by remember { mutableStateOf("") }
    var cardTips by remember { mutableStateOf("") }
    var supplies by remember { mutableStateOf("") }
    var editingWeekStart by remember { mutableLongStateOf(startOfWeek()) }
    var screen by remember { mutableStateOf(Screen.Home) }
    var showPaywall by remember { mutableStateOf(false) }
    var menuOpen by remember { mutableStateOf(false) }

    val unlocked by billing.isUnlocked.collectAsState()
    val displayPrice by billing.displayPrice.collectAsState()
    val context = LocalContext.current
    val activity = context as? Activity
    val scope = rememberCoroutineScope()
    val currentWeekStart = startOfWeek()
    val isCurrentWeek = editingWeekStart == currentWeekStart
    val serviceCents = MoneyMath.cents(services)
    val cashTipsCents = MoneyMath.cents(cashTips)
    val cardTipsCents = MoneyMath.cents(cardTips)
    val supplyCents = MoneyMath.cents(supplies)
    val cut = BigDecimal(store.commissionCutBasisPoints).movePointLeft(4)
    val feeRate = BigDecimal(store.cardFeeBasisPoints).movePointLeft(4)
    val cardShare = BigDecimal(store.servicesOnCardBasisPoints).movePointLeft(4)
    val cardFeesCents = if (store.payModel == "booth" || store.workerPaysCardFees) MoneyMath.cardFees(serviceCents, cardTipsCents, feeRate, cardShare) else 0L
    val takeHomeCents = if (store.payModel == "commission") {
        MoneyMath.commissionTakeHome(serviceCents, cashTipsCents, cardTipsCents, supplyCents, cut, store.tipOwner, store.workerPaysCardFees, store.extraFeesCents, feeRate, cardShare)
    } else {
        MoneyMath.boothTakeHome(serviceCents, cashTipsCents, cardTipsCents, supplyCents, store.weeklyRentCents, store.extraFeesCents, feeRate, cardShare)
    }
    val grossCents = serviceCents + cashTipsCents + cardTipsCents
    val highRent = store.payModel == "booth" && grossCents > 0 && store.weeklyRentCents * 100 >= grossCents * 40

    fun gated(target: Screen) { if (unlocked) screen = target else showPaywall = true }
    fun loadWeek(week: SavedWeek) {
        editingWeekStart = week.startMillis
        services = inputMoney(week.servicesCents)
        cashTips = inputMoney(week.cashTipsCents)
        cardTips = inputMoney(week.cardTipsCents)
        supplies = inputMoney(week.suppliesCents)
        store.payModel = week.payModel
        screen = Screen.Home
    }
    fun returnToCurrentWeek() {
        editingWeekStart = currentWeekStart
        val saved = store.loadWeeks().firstOrNull { it.startMillis == currentWeekStart }
        if (saved != null) {
            services = inputMoney(saved.servicesCents)
            cashTips = inputMoney(saved.cashTipsCents)
            cardTips = inputMoney(saved.cardTipsCents)
            supplies = inputMoney(saved.suppliesCents)
            store.payModel = saved.payModel
        } else {
            services = ""
            cashTips = ""
            cardTips = ""
            supplies = ""
        }
    }

    if (isCurrentWeek) {
        LaunchedEffect(takeHomeCents) {
            store.updateWidgetTakeHomeCents(takeHomeCents)
            TakeHomeWidget().updateAll(context)
        }
    }

    when (screen) {
        Screen.Breakdown -> BreakdownScreen(store, serviceCents, cashTipsCents, cardTipsCents, supplyCents, cardFeesCents, takeHomeCents) { screen = Screen.Home }
        Screen.History -> HistoryScreen(store, ::loadWeek) { screen = Screen.Home }
        Screen.Compare -> CompareScreen(store, serviceCents, cashTipsCents, cardTipsCents, supplyCents) { screen = Screen.Home }
        Screen.Settings -> SettingsScreen(store, billing) { screen = Screen.Home }
        Screen.Home -> Column(Modifier.fillMaxSize().background(Page)) {
            Column(Modifier.fillMaxWidth().background(BerryDeep)) {
                Box(Modifier.fillMaxWidth().height(4.dp).background(Pink))
                Box(Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp)) {
                    Column(Modifier.align(Alignment.Center), horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(if (isCurrentWeek) stringResource(R.string.this_week) else weekRange(editingWeekStart), color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
                        Text(payContext(store), color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
                    }
                    if (!isCurrentWeek) {
                        IconButton(onClick = { returnToCurrentWeek() }, modifier = Modifier.align(Alignment.CenterStart).size(48.dp)) {
                            Icon(Icons.Default.ArrowBack, contentDescription = stringResource(R.string.this_week), tint = Color.White)
                        }
                    }
                    Box(Modifier.align(Alignment.CenterEnd)) {
                        IconButton(onClick = { menuOpen = true }) { Icon(Icons.Default.MoreVert, contentDescription = stringResource(R.string.more_options), tint = Color.White) }
                        DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                            if (!unlocked) DropdownMenuItem(text = { Text(stringResource(R.string.unlock_price, displayPrice)) }, onClick = { menuOpen = false; showPaywall = true })
                            DropdownMenuItem(text = { Text(stringResource(R.string.share)) }, onClick = { menuOpen = false; ShareCard.share(context, takeHomeCents, editingWeekStart) })
                            DropdownMenuItem(text = { Text(stringResource(R.string.history)) }, onClick = { menuOpen = false; gated(Screen.History) })
                            DropdownMenuItem(text = { Text(stringResource(R.string.compare)) }, onClick = { menuOpen = false; gated(Screen.Compare) })
                            DropdownMenuItem(text = { Text(stringResource(R.string.settings)) }, onClick = { menuOpen = false; screen = Screen.Settings })
                        }
                    }
                }
            }

            Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 22.dp, vertical = 20.dp)) {
                BrandMark()
                Spacer(Modifier.height(16.dp))
                MembershipCard(unlocked, displayPrice) { showPaywall = true }
                Spacer(Modifier.height(24.dp))
                Column(verticalArrangement = Arrangement.spacedBy(20.dp)) {
                    MoneyField(stringResource(R.string.services), services) { services = it }
                    MoneyField(stringResource(R.string.cash_tips), cashTips) { cashTips = it }
                    MoneyField(stringResource(R.string.card_tips), cardTips) { cardTips = it }
                    MoneyField(stringResource(R.string.supplies), supplies) { supplies = it }
                }
                Column(Modifier.fillMaxWidth().padding(top = 30.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(stringResource(R.string.you_took_home), color = Pink, fontWeight = FontWeight.ExtraBold, fontSize = 18.sp, fontFamily = AppFontFamily)
                    Text(formatCents(takeHomeCents), color = Ink, fontWeight = FontWeight.ExtraBold, fontSize = 52.sp, fontFamily = AppFontFamily)
                    if (highRent) Text(stringResource(R.string.rent_warning), color = Warning, fontSize = 17.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
                }
                Column(Modifier.fillMaxWidth().padding(top = 24.dp, bottom = 32.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    PrimaryButton(if (unlocked) stringResource(R.string.save_week) else stringResource(R.string.save_week_lifetime)) {
                        if (unlocked) {
                            store.saveWeek(SavedWeek(editingWeekStart, serviceCents, cashTipsCents, cardTipsCents, supplyCents, store.extraFeesCents, null, store.payModel, takeHomeCents))
                            scope.launch { if (isCurrentWeek) TakeHomeWidget().updateAll(context) }
                        } else showPaywall = true
                    }
                    TextButton(onClick = { screen = Screen.Breakdown }, modifier = Modifier.fillMaxWidth().height(58.dp)) {
                        Text(stringResource(R.string.breakdown), color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
                    }
                }
            }
        }
    }

    if (showPaywall) {
        ModalBottomSheet(onDismissRequest = { showPaywall = false }, containerColor = BerryDeep, contentColor = Ink, dragHandle = { Box(Modifier.padding(top = 10.dp, bottom = 8.dp).width(54.dp).height(6.dp).background(Pink, RoundedCornerShape(99.dp))) }) {
            Column(Modifier.fillMaxWidth().padding(horizontal = 22.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                Text(stringResource(R.string.unlock), color = Ink, fontSize = 28.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
                Text(stringResource(R.string.paywall_body, displayPrice), color = Ink, fontSize = 18.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
                PrimaryButton(stringResource(R.string.unlock_price, displayPrice)) { activity?.let { billing.launchPurchase(it) } }
                TextButton(onClick = { billing.restore() }, modifier = Modifier.fillMaxWidth().height(56.dp)) { Text(stringResource(R.string.restore_purchase), color = Pink, fontSize = 18.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily) }
                TextButton(onClick = { showPaywall = false }, modifier = Modifier.fillMaxWidth().height(56.dp)) { Text(stringResource(R.string.not_now), color = Ink, fontSize = 18.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily) }
                Spacer(Modifier.height(12.dp))
            }
        }
    }
}

@Composable
private fun BrandMark() {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center) {
        Image(painter = painterResource(R.drawable.salon_booth_logo), contentDescription = stringResource(R.string.app_name), modifier = Modifier.size(70.dp))
        Spacer(Modifier.width(12.dp))
        Column {
            Text("SALON BOOTH", color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
            Text("MATH", color = Pink, fontSize = 24.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
        }
    }
}

@Composable
private fun MembershipCard(unlocked: Boolean, displayPrice: String, unlock: () -> Unit) {
    Row(Modifier.fillMaxWidth().background(Surface, RoundedCornerShape(18.dp)).padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(if (unlocked) stringResource(R.string.lifetime_unlocked) else stringResource(R.string.free_label), color = Pink, fontSize = 13.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
            Text(if (unlocked) stringResource(R.string.premium_features) else stringResource(R.string.free_features), color = Ink, fontSize = 16.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
        }
        if (unlocked) Icon(Icons.Default.CheckCircle, contentDescription = null, tint = Pink, modifier = Modifier.size(28.dp))
        else Button(onClick = unlock, colors = ButtonDefaults.buttonColors(containerColor = Pink), shape = RoundedCornerShape(99.dp)) { Text(displayPrice, color = Color.White, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily) }
    }
}
