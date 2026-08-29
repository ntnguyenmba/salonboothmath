package com.everittventures.salonboothmath

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.launch
import java.math.BigDecimal

enum class Screen { Home, Breakdown, History, Compare, Settings }
private enum class LockedAction { SAVE, HISTORY, COMPARE }

@Composable
fun SalonBoothApp(billing: BillingManager) {
    val context = LocalContext.current
    val store = remember { AppStore(context) }
    var onboardingDone by remember { mutableStateOf(store.onboardingDone) }
    if (!onboardingDone) OnboardingScreen(store) { onboardingDone = true } else SalonBoothHome(store, billing)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SalonBoothHome(store: AppStore, billing: BillingManager) {
    val currentWeekStart = startOfWeek()
    val initialDraft = remember { store.loadCurrentWeekDraft(currentWeekStart) }
    var services by remember { mutableStateOf(initialDraft.services) }
    var cashTips by remember { mutableStateOf(initialDraft.cashTips) }
    var cardTips by remember { mutableStateOf(initialDraft.cardTips) }
    var supplies by remember { mutableStateOf(initialDraft.supplies) }
    var hours by remember { mutableStateOf(initialDraft.hours) }
    var editingWeekStart by remember { mutableLongStateOf(currentWeekStart) }
    var screen by remember { mutableStateOf(Screen.Home) }
    var showPaywall by remember { mutableStateOf(false) }
    var menuOpen by remember { mutableStateOf(false) }
    var pendingAction by remember { mutableStateOf<LockedAction?>(null) }

    val unlocked by billing.isUnlocked.collectAsState()
    val displayPrice by billing.displayPrice.collectAsState()
    val context = LocalContext.current
    val activity = context as? Activity
    val scope = rememberCoroutineScope()
    val isCurrentWeek = editingWeekStart == currentWeekStart
    val serviceCents = MoneyMath.cents(services)
    val cashTipsCents = MoneyMath.cents(cashTips)
    val cardTipsCents = MoneyMath.cents(cardTips)
    val supplyCents = MoneyMath.cents(supplies)
    val cut = BigDecimal(store.commissionCutBasisPoints).movePointLeft(4)
    val feeRate = BigDecimal(store.cardFeeBasisPoints).movePointLeft(4)
    val cardShare = BigDecimal(store.servicesOnCardBasisPoints).movePointLeft(4)
    val cardFeesCents = if (store.payModel == "booth" || store.workerPaysCardFees) MoneyMath.cardFees(serviceCents, cardTipsCents, feeRate, cardShare) else 0L
    val takeHomeCents = if (store.payModel == "commission") MoneyMath.commissionTakeHome(serviceCents, cashTipsCents, cardTipsCents, supplyCents, cut, store.tipOwner, store.workerPaysCardFees, store.extraFeesCents, feeRate, cardShare) else MoneyMath.boothTakeHome(serviceCents, cashTipsCents, cardTipsCents, supplyCents, store.weeklyRentCents, store.extraFeesCents, feeRate, cardShare)
    val grossCents = serviceCents + cashTipsCents + cardTipsCents
    val highRent = store.payModel == "booth" && grossCents > 0 && store.weeklyRentCents * 100 >= grossCents * 40
    val hoursValue = hours.trim().replace(',', '.').toDoubleOrNull()?.takeIf { it > 0 }

    fun saveWeek() {
        store.saveWeek(SavedWeek(editingWeekStart, serviceCents, cashTipsCents, cardTipsCents, supplyCents, store.extraFeesCents, hoursValue, store.payModel, takeHomeCents))
        scope.launch { if (isCurrentWeek) TakeHomeWidget().updateAll(context) }
    }

    fun runLockedAction(action: LockedAction) {
        when (action) {
            LockedAction.SAVE -> saveWeek()
            LockedAction.HISTORY -> screen = Screen.History
            LockedAction.COMPARE -> screen = Screen.Compare
        }
    }

    fun requireUnlock(action: LockedAction) {
        if (unlocked) runLockedAction(action) else {
            pendingAction = action
            showPaywall = true
        }
    }

    fun loadWeek(week: SavedWeek) {
        editingWeekStart = week.startMillis
        services = inputMoney(week.servicesCents)
        cashTips = inputMoney(week.cashTipsCents)
        cardTips = inputMoney(week.cardTipsCents)
        supplies = inputMoney(week.suppliesCents)
        hours = week.hours?.let { if (it % 1.0 == 0.0) it.toInt().toString() else it.toString() } ?: ""
        store.payModel = week.payModel
        screen = Screen.Home
    }

    fun returnToCurrentWeek() {
        editingWeekStart = currentWeekStart
        val draft = store.loadCurrentWeekDraft(currentWeekStart)
        services = draft.services
        cashTips = draft.cashTips
        cardTips = draft.cardTips
        supplies = draft.supplies
        hours = draft.hours
    }

    if (isCurrentWeek) {
        LaunchedEffect(services, cashTips, cardTips, supplies, hours) { store.saveCurrentWeekDraft(CurrentWeekDraft(currentWeekStart, services, cashTips, cardTips, supplies, hours)) }
        LaunchedEffect(takeHomeCents) { store.updateWidgetTakeHomeCents(takeHomeCents); TakeHomeWidget().updateAll(context) }
    }

    LaunchedEffect(unlocked) {
        if (unlocked && showPaywall) {
            showPaywall = false
            pendingAction?.let { runLockedAction(it) }
            pendingAction = null
        }
    }

    when (screen) {
        Screen.Breakdown -> BreakdownScreen(store, serviceCents, cashTipsCents, cardTipsCents, supplyCents, cardFeesCents, takeHomeCents, hours, { hours = it }) { screen = Screen.Home }
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
                    if (!isCurrentWeek) IconButton(onClick = { returnToCurrentWeek() }, modifier = Modifier.align(Alignment.CenterStart).size(48.dp)) { Icon(Icons.Default.ArrowBack, contentDescription = stringResource(R.string.this_week), tint = Color.White) }
                    Box(Modifier.align(Alignment.CenterEnd)) {
                        IconButton(onClick = { menuOpen = true }) { Icon(Icons.Default.MoreVert, contentDescription = stringResource(R.string.more_options), tint = Color.White) }
                        DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                            if (!unlocked) DropdownMenuItem(text = { Text(stringResource(R.string.unlock_price, displayPrice)) }, onClick = { menuOpen = false; pendingAction = null; showPaywall = true })
                            DropdownMenuItem(text = { Text(stringResource(R.string.share)) }, onClick = { menuOpen = false; ShareCard.share(context, takeHomeCents, editingWeekStart) })
                            DropdownMenuItem(text = { Text(stringResource(R.string.history)) }, onClick = { menuOpen = false; requireUnlock(LockedAction.HISTORY) })
                            DropdownMenuItem(text = { Text(stringResource(R.string.compare)) }, onClick = { menuOpen = false; requireUnlock(LockedAction.COMPARE) })
                            DropdownMenuItem(text = { Text(stringResource(R.string.settings)) }, onClick = { menuOpen = false; screen = Screen.Settings })
                        }
                    }
                }
            }
            Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 22.dp, vertical = 20.dp)) {
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
                    PrimaryButton(stringResource(R.string.save_week)) { requireUnlock(LockedAction.SAVE) }
                    TextButton(onClick = { screen = Screen.Breakdown }, modifier = Modifier.fillMaxWidth().height(58.dp)) { Text(stringResource(R.string.breakdown), color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily) }
                }
            }
        }
    }

    if (showPaywall) ModalBottomSheet(
        onDismissRequest = { showPaywall = false; pendingAction = null },
        containerColor = BerryDeep,
        contentColor = Ink,
        dragHandle = { Box(Modifier.padding(top = 10.dp, bottom = 8.dp).width(54.dp).height(6.dp).background(Pink, RoundedCornerShape(99.dp))) }
    ) {
        Column(Modifier.fillMaxWidth().padding(horizontal = 22.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
            Text(stringResource(R.string.unlock), color = Ink, fontSize = 28.sp, fontWeight = FontWeight.ExtraBold, fontFamily = AppFontFamily)
            Text(stringResource(R.string.paywall_body, displayPrice), color = Ink, fontSize = 18.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily)
            PrimaryButton(stringResource(R.string.unlock_price, displayPrice)) { activity?.let { billing.launchPurchase(it) } }
            TextButton(onClick = { billing.restore() }, modifier = Modifier.fillMaxWidth().height(56.dp)) { Text(stringResource(R.string.restore_purchase), color = Pink, fontSize = 18.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily) }
            TextButton(onClick = { showPaywall = false; pendingAction = null }, modifier = Modifier.fillMaxWidth().height(56.dp)) { Text(stringResource(R.string.not_now), color = Ink, fontSize = 18.sp, fontWeight = FontWeight.Bold, fontFamily = AppFontFamily) }
            Spacer(Modifier.height(12.dp))
        }
    }
}
