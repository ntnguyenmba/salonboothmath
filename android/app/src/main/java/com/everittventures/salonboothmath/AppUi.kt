package com.everittventures.salonboothmath

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MoreVert
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
import java.math.RoundingMode
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.*

private val Berry = Color(0xFF4A1835)
private val Ink = Color(0xFF0B1220)
private val Pink = Color(0xFFFF3D6E)
private val Warning = Color(0xFFC2410C)
private val Page = Color.White
private val FieldFill = Color(0x140B1220)

enum class Screen { Home, Breakdown, History, Compare, Settings }

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

    val title = when (step) {
        0 -> stringResource(R.string.trade_question)
        1 -> stringResource(R.string.pay_question)
        2 -> if (pay == "booth") stringResource(R.string.weekly_rent) else stringResource(R.string.your_cut)
        else -> stringResource(R.string.enter_week)
    }

    val trades = listOf(
        "nail" to stringResource(R.string.trade_nail),
        "hair" to stringResource(R.string.trade_hair),
        "barber" to stringResource(R.string.trade_barber),
        "esthetician" to stringResource(R.string.trade_esthetician)
    )
    val payModels = listOf(
        "booth" to stringResource(R.string.booth_rent),
        "commission" to stringResource(R.string.commission)
    )

    Column(
        Modifier.fillMaxSize().background(Page).padding(24.dp),
        verticalArrangement = Arrangement.Center
    ) {
        Text(title, color = Ink, fontSize = 34.sp, fontWeight = FontWeight.ExtraBold)
        Spacer(Modifier.height(30.dp))
        when (step) {
            0 -> trades.forEach { (id, label) -> Choice(label, trade == id) { trade = id } }
            1 -> payModels.forEach { (id, label) ->
                Choice(label, pay == id) {
                    pay = id
                    value = if (id == "booth") "250" else "55"
                }
            }
            2 -> MoneyField(
                if (pay == "booth") stringResource(R.string.weekly_rent) else stringResource(R.string.your_cut),
                value
            ) { value = it }
        }
        Spacer(Modifier.height(28.dp))
        PrimaryButton(if (step == 3) stringResource(R.string.enter_week) else stringResource(R.string.continue_label)) {
            if (step < 3) {
                step++
            } else {
                store.trade = trade
                store.payModel = pay
                if (pay == "booth") store.rentCents = MoneyMath.cents(value)
                else store.commissionCutBasisPoints = percentBasisPoints(value, 55.0)
                store.onboardingDone = true
                done()
            }
        }
    }
}

@Composable
private fun Choice(label: String, selected: Boolean, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        colors = ButtonDefaults.buttonColors(
            containerColor = if (selected) Berry else Color.White,
            contentColor = if (selected) Color.White else Ink
        ),
        border = if (selected) null else ButtonDefaults.outlinedButtonBorder,
        modifier = Modifier.fillMaxWidth().height(68.dp).padding(bottom = 10.dp),
        shape = RoundedCornerShape(18.dp)
    ) {
        Text(label, fontSize = 19.sp, fontWeight = FontWeight.ExtraBold)
    }
}

@Composable
fun SalonBoothHome(store: AppStore, billing: BillingManager) {
    var services by remember { mutableStateOf("") }
    var cashTips by remember { mutableStateOf("") }
    var cardTips by remember { mutableStateOf("") }
    var supplies by remember { mutableStateOf("") }
    var hours by remember { mutableStateOf("") }
    var editingWeekStart by remember { mutableLongStateOf(startOfWeek()) }
    var screen by remember { mutableStateOf(Screen.Home) }
    var showPaywall by remember { mutableStateOf(false) }
    var menuOpen by remember { mutableStateOf(false) }

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
    val cardFeesCents = if (store.payModel == "booth" || store.workerPaysCardFees) {
        MoneyMath.cardFees(serviceCents, cardTipsCents, feeRate, cardShare)
    } else 0L
    val takeHomeCents = if (store.payModel == "commission") {
        MoneyMath.commissionTakeHome(
            serviceCents, cashTipsCents, cardTipsCents, supplyCents, cut,
            tipOwner = store.tipOwner,
            workerPaysCardFees = store.workerPaysCardFees,
            extraFeesCents = store.extraFeesCents,
            cardFeeRate = feeRate,
            percentServicesOnCard = cardShare
        )
    } else {
        MoneyMath.boothTakeHome(
            serviceCents, cashTipsCents, cardTipsCents, supplyCents,
            store.weeklyRentCents, store.extraFeesCents, feeRate, cardShare
        )
    }
    val grossCents = serviceCents + cashTipsCents + cardTipsCents
    val highRent = store.payModel == "booth" && grossCents > 0 && store.weeklyRentCents * 100 >= grossCents * 40

    fun gated(target: Screen) {
        if (unlocked) screen = target else showPaywall = true
    }

    fun loadWeek(week: SavedWeek) {
        editingWeekStart = week.startMillis
        services = inputMoney(week.servicesCents)
        cashTips = inputMoney(week.cashTipsCents)
        cardTips = inputMoney(week.cardTipsCents)
        supplies = inputMoney(week.suppliesCents)
        hours = week.hours?.let { cleanDecimal(it) } ?: ""
        store.payModel = week.payModel
        screen = Screen.Home
    }

    if (editingWeekStart == startOfWeek()) {
        LaunchedEffect(takeHomeCents) {
            store.updateWidgetTakeHomeCents(takeHomeCents)
            TakeHomeWidget().updateAll(context)
        }
    }

    when (screen) {
        Screen.Breakdown -> BreakdownScreen(
            store = store,
            services = serviceCents,
            cashTips = cashTipsCents,
            cardTips = cardTipsCents,
            supplies = supplyCents,
            cardFees = cardFeesCents,
            takeHome = takeHomeCents,
            hours = hours,
            onHoursChange = { hours = it },
            back = { screen = Screen.Home }
        )
        Screen.History -> HistoryScreen(store, onWeek = ::loadWeek) { screen = Screen.Home }
        Screen.Compare -> CompareScreen(store, serviceCents, cashTipsCents, cardTipsCents, supplyCents) { screen = Screen.Home }
        Screen.Settings -> SettingsScreen(store) { screen = Screen.Home }
        Screen.Home -> Column(Modifier.fillMaxSize().background(Page).verticalScroll(rememberScrollState())) {
            Box(Modifier.fillMaxWidth().background(Berry).padding(horizontal = 14.dp, vertical = 12.dp)) {
                Column(Modifier.align(Alignment.Center), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        if (editingWeekStart == startOfWeek()) stringResource(R.string.this_week)
                        else SimpleDateFormat("MMM d", Locale.getDefault()).format(Date(editingWeekStart)),
                        color = Color.White,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.ExtraBold
                    )
                    Text(
                        payContext(store),
                        color = Color.White.copy(alpha = .9f),
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
                Box(Modifier.align(Alignment.CenterEnd)) {
                    IconButton(onClick = { menuOpen = true }) {
                        Icon(Icons.Default.MoreVert, contentDescription = stringResource(R.string.settings), tint = Color.White)
                    }
                    DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                        DropdownMenuItem(text = { Text(stringResource(R.string.share)) }, onClick = {
                            menuOpen = false
                            ShareCard.share(context, takeHomeCents, editingWeekStart)
                        })
                        DropdownMenuItem(text = { Text(stringResource(R.string.history)) }, onClick = {
                            menuOpen = false
                            gated(Screen.History)
                        })
                        DropdownMenuItem(text = { Text(stringResource(R.string.compare)) }, onClick = {
                            menuOpen = false
                            gated(Screen.Compare)
                        })
                        DropdownMenuItem(text = { Text(stringResource(R.string.settings)) }, onClick = {
                            menuOpen = false
                            screen = Screen.Settings
                        })
                    }
                }
            }

            Column(
                Modifier.padding(horizontal = 22.dp, vertical = 28.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp)
            ) {
                MoneyField(stringResource(R.string.services), services) { services = it }
                MoneyField(stringResource(R.string.cash_tips), cashTips) { cashTips = it }
                MoneyField(stringResource(R.string.card_tips), cardTips) { cardTips = it }
                MoneyField(stringResource(R.string.supplies), supplies) { supplies = it }

                Spacer(Modifier.height(10.dp))
                Text(
                    stringResource(R.string.you_took_home),
                    color = Berry,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 18.sp,
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                )
                Text(
                    formatCents(takeHomeCents),
                    color = Ink,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 52.sp,
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                )
                if (highRent) {
                    Text(stringResource(R.string.rent_warning), color = Warning, fontSize = 17.sp, fontWeight = FontWeight.ExtraBold)
                }

                PrimaryButton(stringResource(R.string.save_week)) {
                    if (unlocked) {
                        store.saveWeek(
                            SavedWeek(
                                startMillis = editingWeekStart,
                                servicesCents = serviceCents,
                                cashTipsCents = cashTipsCents,
                                cardTipsCents = cardTipsCents,
                                suppliesCents = supplyCents,
                                extraFeesCents = store.extraFeesCents,
                                hours = hours.toDoubleOrNull()?.takeIf { it > 0 },
                                payModel = store.payModel,
                                takeHomeCents = takeHomeCents
                            )
                        )
                        scope.launch {
                            if (editingWeekStart == startOfWeek()) TakeHomeWidget().updateAll(context)
                        }
                    } else showPaywall = true
                }

                TextButton(onClick = { screen = Screen.Breakdown }, modifier = Modifier.fillMaxWidth().height(54.dp)) {
                    Text(stringResource(R.string.breakdown), color = Berry, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold)
                }
            }
        }
    }

    if (showPaywall) {
        AlertDialog(
            onDismissRequest = { showPaywall = false },
            title = { Text(stringResource(R.string.unlock), fontWeight = FontWeight.ExtraBold) },
            text = { Text(stringResource(R.string.paywall_body, displayPrice)) },
            confirmButton = {
                Button(
                    onClick = { billing.launchPurchase(activity) },
                    colors = ButtonDefaults.buttonColors(containerColor = Pink, contentColor = Color.White)
                ) {
                    Text(stringResource(R.string.unlock_price, displayPrice), fontWeight = FontWeight.ExtraBold)
                }
            },
            dismissButton = {
                Column {
                    TextButton(onClick = { billing.restore() }) { Text(stringResource(R.string.restore_purchase)) }
                    TextButton(onClick = { showPaywall = false }) { Text(stringResource(R.string.not_now)) }
                }
            }
        )
    }
}

@Composable
private fun BreakdownScreen(
    store: AppStore,
    services: Long,
    cashTips: Long,
    cardTips: Long,
    supplies: Long,
    cardFees: Long,
    takeHome: Long,
    hours: String,
    onHoursChange: (String) -> Unit,
    back: () -> Unit
) {
    val gross = services + cashTips + cardTips
    val workerCut = BigDecimal(store.commissionCutBasisPoints).movePointLeft(4)
    val ownerCut = if (store.payModel == "commission") {
        services - BigDecimal.valueOf(services).multiply(workerCut).setScale(0, RoundingMode.HALF_UP).longValueExact()
    } else store.weeklyRentCents
    val hoursValue = hours.toBigDecimalOrNull()?.takeIf { it > BigDecimal.ZERO }
    val hourly = hoursValue?.let {
        BigDecimal.valueOf(takeHome).divide(it, 0, RoundingMode.HALF_UP).longValueExact()
    }
    val tax = if (takeHome > 0) {
        BigDecimal.valueOf(takeHome)
            .multiply(BigDecimal(store.taxBasisPoints).movePointLeft(4))
            .setScale(0, RoundingMode.HALF_UP)
            .longValueExact()
    } else 0L

    SimpleScreen(stringResource(R.string.breakdown), back) {
        Metric(stringResource(R.string.gross), gross)
        CostRow(if (store.payModel == "commission") stringResource(R.string.house_cut) else stringResource(R.string.weekly_rent), ownerCut)
        if (cardFees > 0) CostRow(stringResource(R.string.card_fees), cardFees)
        CostRow(stringResource(R.string.supplies), supplies)
        if (store.extraFeesCents > 0) CostRow(stringResource(R.string.extra_shop_fees), store.extraFeesCents)
        HorizontalDivider()
        Metric(stringResource(R.string.take_home), takeHome)
        MoneyField(stringResource(R.string.hours_this_week), hours, showCurrency = false, onValue = onHoursChange)
        if (hourly != null) Metric(stringResource(R.string.per_hour), hourly)
        if (tax > 0) Metric(stringResource(R.string.tax_reserve), tax)
    }
}

@Composable
private fun HistoryScreen(store: AppStore, onWeek: (SavedWeek) -> Unit, back: () -> Unit) {
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
private fun CompareScreen(store: AppStore, services: Long, cashTips: Long, cardTips: Long, supplies: Long, back: () -> Unit) {
    val feeRate = BigDecimal(store.cardFeeBasisPoints).movePointLeft(4)
    val cardShare = BigDecimal(store.servicesOnCardBasisPoints).movePointLeft(4)
    val booth = MoneyMath.boothTakeHome(services, cashTips, cardTips, supplies, store.weeklyRentCents, store.extraFeesCents, feeRate, cardShare)
    val commission = MoneyMath.commissionTakeHome(
        services, cashTips, cardTips, supplies,
        BigDecimal(store.commissionCutBasisPoints).movePointLeft(4),
        tipOwner = store.tipOwner,
        workerPaysCardFees = store.workerPaysCardFees,
        extraFeesCents = store.extraFeesCents,
        cardFeeRate = feeRate,
        percentServicesOnCard = cardShare
    )
    SimpleScreen(stringResource(R.string.compare), back) {
        Metric(stringResource(R.string.compare_booth), booth)
        Metric(stringResource(R.string.compare_commission, store.commissionCutBasisPoints / 100), commission)
    }
}

@Composable
private fun SettingsScreen(store: AppStore, back: () -> Unit) {
    var rent by remember { mutableStateOf(inputMoney(store.rentCents)) }
    var rentPeriod by remember { mutableStateOf(store.rentPeriod) }
    var cut by remember { mutableStateOf(cleanDecimal(store.commissionCutBasisPoints / 100.0)) }
    var tipOwner by remember { mutableStateOf(store.tipOwner) }
    var extra by remember { mutableStateOf(inputMoney(store.extraFeesCents)) }
    var paysFees by remember { mutableStateOf(store.workerPaysCardFees) }
    var cardFee by remember { mutableStateOf(cleanDecimal(store.cardFeeBasisPoints / 100.0)) }
    var cardShare by remember { mutableStateOf(cleanDecimal(store.servicesOnCardBasisPoints / 100.0)) }
    var tax by remember { mutableStateOf(cleanDecimal(store.taxBasisPoints / 100.0)) }

    SimpleScreen(stringResource(R.string.settings), back) {
        if (store.payModel == "booth") {
            MoneyField(stringResource(R.string.weekly_rent), rent) { rent = it }
            SingleChoiceSegment(
                options = listOf("week" to stringResource(R.string.week), "month" to stringResource(R.string.month)),
                selected = rentPeriod,
                onSelect = { rentPeriod = it }
            )
        } else {
            MoneyField(stringResource(R.string.your_cut), cut, showCurrency = false) { cut = it }
            Text(stringResource(R.string.who_keeps_tips), color = Ink, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold)
            SingleChoiceSegment(
                options = listOf(
                    TipOwner.YOU.name to stringResource(R.string.tips_you),
                    TipOwner.HOUSE.name to stringResource(R.string.tips_house),
                    TipOwner.SPLIT.name to stringResource(R.string.tips_split)
                ),
                selected = tipOwner.name,
                onSelect = { tipOwner = TipOwner.valueOf(it) }
            )
            SettingToggle(stringResource(R.string.worker_card_fees), paysFees) { paysFees = it }
        }

        MoneyField(stringResource(R.string.card_fee_percent), cardFee, showCurrency = false) { cardFee = it }
        MoneyField(stringResource(R.string.services_on_card), cardShare, showCurrency = false) { cardShare = it }
        MoneyField(stringResource(R.string.extra_shop_fees), extra) { extra = it }
        MoneyField(stringResource(R.string.tax_set_aside), tax, showCurrency = false) { tax = it }

        Text(stringResource(R.string.estimate_disclaimer), color = Berry, fontSize = 16.sp, fontWeight = FontWeight.Bold)
        PrimaryButton(stringResource(R.string.save_settings)) {
            store.rentCents = MoneyMath.cents(rent)
            store.rentPeriod = rentPeriod
            store.commissionCutBasisPoints = percentBasisPoints(cut, 55.0)
            store.tipOwner = tipOwner
            store.extraFeesCents = MoneyMath.cents(extra)
            store.workerPaysCardFees = paysFees
            store.cardFeeBasisPoints = percentBasisPoints(cardFee, 2.9)
            store.servicesOnCardBasisPoints = percentBasisPoints(cardShare, 70.0)
            store.taxBasisPoints = percentBasisPoints(tax, 25.0)
            back()
        }
    }
}

@Composable
private fun SingleChoiceSegment(options: List<Pair<String, String>>, selected: String, onSelect: (String) -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        options.forEach { (id, label) ->
            Button(
                onClick = { onSelect(id) },
                modifier = Modifier.weight(1f).height(56.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (selected == id) Berry else Color.White,
                    contentColor = if (selected == id) Color.White else Ink
                ),
                border = if (selected == id) null else ButtonDefaults.outlinedButtonBorder,
                shape = RoundedCornerShape(16.dp)
            ) { Text(label, fontWeight = FontWeight.ExtraBold) }
        }
    }
}

@Composable
private fun SettingToggle(label: String, checked: Boolean, onChecked: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = Ink, fontSize = 18.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
        Switch(checked = checked, onCheckedChange = onChecked, colors = SwitchDefaults.colors(checkedThumbColor = Color.White, checkedTrackColor = Berry))
    }
}

@Composable
private fun SimpleScreen(title: String, back: () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    Column(
        Modifier.fillMaxSize().background(Page).padding(22.dp).verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        TextButton(onClick = back) { Text("‹ ${stringResource(R.string.this_week)}", color = Berry, fontWeight = FontWeight.ExtraBold) }
        Text(title, color = Ink, fontSize = 32.sp, fontWeight = FontWeight.ExtraBold)
        content()
    }
}

@Composable
private fun Metric(label: String, value: Long) {
    Column(spacing = 4.dp) {
        Text(label, color = Berry, fontSize = 18.sp, fontWeight = FontWeight.Bold)
        Text(formatCents(value), color = Ink, fontSize = 40.sp, fontWeight = FontWeight.ExtraBold)
    }
}

@Composable
private fun CostRow(label: String, value: Long) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, color = Ink, fontSize = 18.sp, fontWeight = FontWeight.Bold)
        Text("−${formatCents(value)}", color = Ink, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold)
    }
}

@Composable
private fun MoneyField(label: String, value: String, showCurrency: Boolean = true, onValue: (String) -> Unit) {
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
                unfocusedContainerColor = FieldFill,
                focusedContainerColor = FieldFill,
                unfocusedBorderColor = Ink.copy(alpha = .42f),
                focusedBorderColor = Pink,
                cursorColor = Berry
            )
        )
    }
}

@Composable
private fun PrimaryButton(label: String, action: () -> Unit) {
    Button(
        onClick = action,
        colors = ButtonDefaults.buttonColors(containerColor = Pink, contentColor = Color.White),
        modifier = Modifier.fillMaxWidth().height(62.dp),
        shape = RoundedCornerShape(18.dp)
    ) {
        Text(label, fontSize = 19.sp, fontWeight = FontWeight.ExtraBold)
    }
}

@Composable
private fun payContext(store: AppStore): String {
    return if (store.payModel == "booth") {
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
}

private fun formatCents(cents: Long): String = NumberFormat.getCurrencyInstance().format(BigDecimal.valueOf(cents, 2))
private fun inputMoney(cents: Long): String = BigDecimal.valueOf(cents, 2).stripTrailingZeros().toPlainString()
private fun cleanDecimal(value: Double): String = BigDecimal.valueOf(value).stripTrailingZeros().toPlainString()
private fun percentBasisPoints(text: String, fallback: Double): Int {
    val normalized = text.trim().replace(',', '.')
    val percent = normalized.toBigDecimalOrNull() ?: BigDecimal.valueOf(fallback)
    return percent.multiply(BigDecimal("100")).setScale(0, RoundingMode.HALF_UP).toInt()
}
private fun startOfWeek(): Long {
    val c = Calendar.getInstance()
    c.set(Calendar.DAY_OF_WEEK, c.firstDayOfWeek)
    c.set(Calendar.HOUR_OF_DAY, 0)
    c.set(Calendar.MINUTE, 0)
    c.set(Calendar.SECOND, 0)
    c.set(Calendar.MILLISECOND, 0)
    return c.timeInMillis
}
