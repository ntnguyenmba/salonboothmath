package com.everittventures.salonboothmath

import android.app.Activity
import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Settings
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
import androidx.core.os.LocaleListCompat
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.launch
import java.math.BigDecimal

enum class Screen { Home, Breakdown, History, Compare, Decisions, Settings }
private enum class LockedAction { SAVE, HISTORY, COMPARE, DECISIONS }

@Composable fun SalonBoothApp(billing: BillingManager) { val context = LocalContext.current; val store = remember { AppStore(context) }; var done by remember { mutableStateOf(store.onboardingDone) }; if (!done) OnboardingScreen(store) { done = true } else SalonBoothHome(store, billing) }

@OptIn(ExperimentalMaterial3Api::class)
@Composable fun SalonBoothHome(store: AppStore, billing: BillingManager) {
    val context = LocalContext.current
    val freeAccess = rememberFreeAccessState(context)
    val currentWeekStart = startOfWeek(); val initialDraft = remember { store.loadCurrentWeekDraft(currentWeekStart) }
    var services by remember { mutableStateOf(initialDraft.services) }; var cashTips by remember { mutableStateOf(initialDraft.cashTips) }; var cardTips by remember { mutableStateOf(initialDraft.cardTips) }; var supplies by remember { mutableStateOf(initialDraft.supplies) }; var hours by remember { mutableStateOf(initialDraft.hours) }; var days by remember { mutableStateOf(initialDraft.days) }
    var editingWeekStart by remember { mutableLongStateOf(currentWeekStart) }; var screen by remember { mutableStateOf(Screen.Home) }; var showPaywall by remember { mutableStateOf(false) }; var showAddToday by remember { mutableStateOf(false) }; var menuOpen by remember { mutableStateOf(false) }; var pendingAction by remember { mutableStateOf<LockedAction?>(null) }; var addedTodayGross by remember { mutableStateOf<Long?>(null) }
    val unlocked by billing.isUnlocked.collectAsState(); val displayPrice by billing.displayPrice.collectAsState(); val billingIssue by billing.billingIssue.collectAsState(); val activity = context as? Activity; val scope = rememberCoroutineScope(); val isCurrentWeek = editingWeekStart == currentWeekStart
    val serviceCents = MoneyMath.cents(services); val cashTipsCents = MoneyMath.cents(cashTips); val cardTipsCents = MoneyMath.cents(cardTips); val supplyCents = MoneyMath.cents(supplies)
    val cut = BigDecimal(store.commissionCutBasisPoints).movePointLeft(4); val feeRate = BigDecimal(store.cardFeeBasisPoints).movePointLeft(4); val cardShare = BigDecimal(store.servicesOnCardBasisPoints).movePointLeft(4)
    val cardFeesCents = if (store.payModel == "booth" || store.workerPaysCardFees) MoneyMath.cardFees(serviceCents, cardTipsCents, feeRate, cardShare) else 0L
    val takeHomeCents = when (store.payModel) { "commission" -> MoneyMath.commissionTakeHome(serviceCents,cashTipsCents,cardTipsCents,supplyCents,cut,store.tipOwner,store.workerPaysCardFees,store.extraFeesCents,feeRate,cardShare); "hybrid" -> MoneyMath.hybridTakeHome(serviceCents,cashTipsCents,cardTipsCents,supplyCents,store.weeklyRentCents,cut,store.tipOwner,store.workerPaysCardFees,store.extraFeesCents,feeRate,cardShare); else -> MoneyMath.boothTakeHome(serviceCents,cashTipsCents,cardTipsCents,supplyCents,store.weeklyRentCents,store.extraFeesCents,feeRate,cardShare) }
    val grossCents = serviceCents + cashTipsCents + cardTipsCents; val highRent = store.payModel != "commission" && grossCents > 0 && store.weeklyRentCents * 100 >= grossCents * 40; val hoursValue = hours.trim().replace(',', '.').toDoubleOrNull()?.takeIf { it > 0 }
    fun saveWeek() { store.saveWeek(SavedWeek(editingWeekStart,serviceCents,cashTipsCents,cardTipsCents,supplyCents,store.extraFeesCents,hoursValue,store.payModel,takeHomeCents,days)); scope.launch { if (isCurrentWeek) TakeHomeWidget().updateAll(context) } }
    fun runLockedAction(action: LockedAction) { when(action){ LockedAction.SAVE->saveWeek(); LockedAction.HISTORY->screen=Screen.History; LockedAction.COMPARE->screen=Screen.Compare; LockedAction.DECISIONS->screen=Screen.Decisions } }
    fun requireUnlock(action: LockedAction) { if(unlocked) runLockedAction(action) else { pendingAction=action; showPaywall=true } }
    fun saveWithFreeTry() { if (freeAccess.claim(PremiumFeature.SAVE, unlocked)) saveWeek() else requireUnlock(LockedAction.SAVE) }
    fun openHistory() { if (freeAccess.claim(PremiumFeature.HISTORY, unlocked)) screen=Screen.History else requireUnlock(LockedAction.HISTORY) }
    fun openCompare() { if (freeAccess.claim(PremiumFeature.COMPARE, unlocked)) screen=Screen.Compare else requireUnlock(LockedAction.COMPARE) }
    fun openPayCheckup() { if (freeAccess.claim(PremiumFeature.PAY_CHECKUP, unlocked)) screen=Screen.Decisions else requireUnlock(LockedAction.DECISIONS) }
    fun loadWeek(week: SavedWeek){ editingWeekStart=week.startMillis; services=inputMoney(week.servicesCents); cashTips=inputMoney(week.cashTipsCents); cardTips=inputMoney(week.cardTipsCents); supplies=inputMoney(week.suppliesCents); hours=week.hours?.let{if(it%1.0==0.0)it.toInt().toString() else it.toString()}?:""; days=week.days; store.payModel=week.payModel; screen=Screen.Home }
    fun returnToCurrentWeek(){ editingWeekStart=currentWeekStart; val d=store.loadCurrentWeekDraft(currentWeekStart); services=d.services;cashTips=d.cashTips;cardTips=d.cardTips;supplies=d.supplies;hours=d.hours;days=d.days }
    fun setLanguage(tag: String) {
        if (tag == store.appLanguage) return
        store.appLanguage = tag
        AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(tag))
        activity?.recreate()
    }
    if(isCurrentWeek){ LaunchedEffect(services,cashTips,cardTips,supplies,hours,days){store.saveCurrentWeekDraft(CurrentWeekDraft(currentWeekStart,services,cashTips,cardTips,supplies,hours,days))}; LaunchedEffect(takeHomeCents){store.updateWidgetTakeHomeCents(takeHomeCents);TakeHomeWidget().updateAll(context)} }
    LaunchedEffect(unlocked){if(unlocked&&showPaywall){showPaywall=false;pendingAction?.let{runLockedAction(it)};pendingAction=null}}

    when(screen){
        Screen.Breakdown->BreakdownScreen(store,serviceCents,cashTipsCents,cardTipsCents,supplyCents,cardFeesCents,takeHomeCents,hours,{hours=it}){screen=Screen.Home}
        Screen.History->HistoryScreen(store,::loadWeek){screen=Screen.Home}
        Screen.Compare->CompareScreen(store,serviceCents,cashTipsCents,cardTipsCents,supplyCents){screen=Screen.Home}
        Screen.Decisions->DecisionsScreen(store,serviceCents,cashTipsCents,cardTipsCents,supplyCents,unlocked,{pendingAction=LockedAction.DECISIONS;showPaywall=true}){screen=Screen.Home}
        Screen.Settings->SettingsScreen(store,billing){screen=Screen.Home}
        Screen.Home->Column(Modifier.fillMaxSize().background(Page)){
            Column(Modifier.fillMaxWidth().background(BerryDeep)){Box(Modifier.fillMaxWidth().height(4.dp).background(Pink));Box(Modifier.fillMaxWidth().padding(horizontal=8.dp,vertical=8.dp)){
                Column(Modifier.align(Alignment.Center).clickable{screen=Screen.Settings},horizontalAlignment=Alignment.CenterHorizontally){Text(if(isCurrentWeek)stringResource(R.string.this_week) else weekRange(editingWeekStart, store.appLanguage),color=Color.White,fontSize=20.sp,fontWeight=FontWeight.ExtraBold,fontFamily=AppFontFamily);Text(payContext(store),color=Color.White,fontSize=16.sp,fontWeight=FontWeight.Bold,fontFamily=AppFontFamily)}
                if(!isCurrentWeek)IconButton(onClick={returnToCurrentWeek()},modifier=Modifier.align(Alignment.CenterStart).size(48.dp)){Icon(Icons.Default.ArrowBack,contentDescription=stringResource(R.string.this_week),tint=Color.White)}
                Row(Modifier.align(Alignment.CenterEnd), verticalAlignment=Alignment.CenterVertically){
                    IconButton(onClick={screen=Screen.Settings}){Icon(Icons.Default.Settings,contentDescription=stringResource(R.string.settings),tint=Color.White)}
                    Box{IconButton(onClick={menuOpen=true}){Icon(Icons.Default.MoreVert,contentDescription=stringResource(R.string.more_options),tint=Color.White)};DropdownMenu(expanded=menuOpen,onDismissRequest={menuOpen=false}){
                        DropdownMenuItem(text={Text("English")},onClick={menuOpen=false;setLanguage("en")})
                        DropdownMenuItem(text={Text("Español")},onClick={menuOpen=false;setLanguage("es")})
                        DropdownMenuItem(text={Text("Tiếng Việt")},onClick={menuOpen=false;setLanguage("vi")})
                        HorizontalDivider()
                        DropdownMenuItem(text={Text(stringResource(R.string.share))},onClick={menuOpen=false;ShareCard.share(context,takeHomeCents,editingWeekStart)})
                        DropdownMenuItem(text={Text(stringResource(R.string.history))},onClick={menuOpen=false;openHistory()})
                        DropdownMenuItem(text={Text(stringResource(R.string.decisions))},onClick={menuOpen=false;openPayCheckup()})
                        DropdownMenuItem(text={Text(stringResource(R.string.compare))},onClick={menuOpen=false;openCompare()})
                        DropdownMenuItem(text={Text(stringResource(R.string.settings))},onClick={menuOpen=false;screen=Screen.Settings})
                        HorizontalDivider()
                        DropdownMenuItem(text={Text(stringResource(R.string.start_over))},onClick={menuOpen=false;store.onboardingDone=false;activity?.recreate()})
                    }}
                }
            }}
            Column(Modifier.weight(1f).fillMaxWidth().verticalScroll(rememberScrollState()).padding(horizontal=22.dp)){
                Spacer(Modifier.height(26.dp))
                MoneyField(stringResource(R.string.services),services){services=it}
                Spacer(Modifier.height(20.dp))
                MoneyField(stringResource(R.string.cash_tips),cashTips){cashTips=it}
                Spacer(Modifier.height(20.dp))
                MoneyField(stringResource(R.string.card_tips),cardTips){cardTips=it}
                Spacer(Modifier.height(20.dp))
                MoneyField(stringResource(R.string.supplies),supplies){supplies=it}
                Spacer(Modifier.height(30.dp))
                Text(stringResource(R.string.you_took_home),color=MutedInk,fontSize=16.sp,fontWeight=FontWeight.Bold,fontFamily=AppFontFamily)
                Text(formatCents(takeHomeCents),color=Color.White,fontSize=48.sp,fontWeight=FontWeight.ExtraBold,fontFamily=AppFontFamily)
                if(highRent)Text(stringResource(R.string.high_rent_warning),color=Pink,fontSize=16.sp,fontWeight=FontWeight.Bold,fontFamily=AppFontFamily)
                if(addedTodayGross!=null)Text(stringResource(R.string.added_today,formatCents(addedTodayGross!!)),color=MutedInk,fontSize=16.sp,fontWeight=FontWeight.Bold,fontFamily=AppFontFamily)
                Column(Modifier.fillMaxWidth().padding(top=24.dp,bottom=32.dp),verticalArrangement=Arrangement.spacedBy(14.dp)){
                    if(isCurrentWeek) TextButton(onClick={showAddToday=true},modifier=Modifier.fillMaxWidth().height(58.dp)){Text(stringResource(R.string.add_today),color=Pink,fontSize=18.sp,fontWeight=FontWeight.ExtraBold,fontFamily=AppFontFamily)}
                    if (unlocked) {
                        PrimaryButton(stringResource(R.string.save_week)){saveWithFreeTry()}
                    } else {
                        FreeTryActionButton(
                            title = stringResource(R.string.save_week),
                            used = freeAccess.used(PremiumFeature.SAVE),
                            freeLabel = stringResource(R.string.free_try_save),
                            usedLabel = stringResource(R.string.free_used),
                            onClick = ::saveWithFreeTry
                        )
                    }
                    TextButton(onClick={screen=Screen.Breakdown},modifier=Modifier.fillMaxWidth().height(58.dp)){Text(stringResource(R.string.breakdown),color=Color.White,fontSize=18.sp,fontWeight=FontWeight.ExtraBold,fontFamily=AppFontFamily)}
                    if (unlocked) {
                        TextButton(onClick={openCompare},modifier=Modifier.fillMaxWidth().height(58.dp)){Text(stringResource(R.string.compare),color=Color.White,fontSize=18.sp,fontWeight=FontWeight.ExtraBold,fontFamily=AppFontFamily)}
                        TextButton(onClick={openPayCheckup},modifier=Modifier.fillMaxWidth().height(58.dp)){Text(stringResource(R.string.decisions),color=Color.White,fontSize=18.sp,fontWeight=FontWeight.ExtraBold,fontFamily=AppFontFamily)}
                    } else {
                        FreeTryActionButton(
                            title = stringResource(R.string.compare),
                            used = freeAccess.used(PremiumFeature.COMPARE),
                            freeLabel = stringResource(R.string.free_try_compare),
                            usedLabel = stringResource(R.string.free_used),
                            onClick = ::openCompare
                        )
                        FreeTryActionButton(
                            title = stringResource(R.string.decisions),
                            used = freeAccess.used(PremiumFeature.PAY_CHECKUP),
                            freeLabel = stringResource(R.string.free_try_pay_checkup),
                            usedLabel = stringResource(R.string.free_used),
                            onClick = ::openPayCheckup
                        )
                    }
                    TextButton(onClick={screen=Screen.Settings},modifier=Modifier.fillMaxWidth().height(58.dp)){Text(stringResource(R.string.settings),color=Color.White,fontSize=18.sp,fontWeight=FontWeight.ExtraBold,fontFamily=AppFontFamily)}
                }
            }
            if(!unlocked) {
                FreeBannerAd(Modifier.fillMaxWidth().height(50.dp))
            }
        }
    }
    if(showAddToday) {
        AddTodaySheet(onDismiss={showAddToday=false}) { line ->
            services=inputMoney(serviceCents+line.servicesCents)
            cashTips=inputMoney(cashTipsCents+line.cashTipsCents)
            cardTips=inputMoney(cardTipsCents+line.cardTipsCents)
            supplies=inputMoney(supplyCents+line.suppliesCents)
            line.hours?.let { h ->
                hours=((hoursValue?:0.0)+h).let { if(it%1.0==0.0) it.toInt().toString() else it.toString() }
            }
            days=days+line
            addedTodayGross=line.servicesCents+line.cashTipsCents+line.cardTipsCents
            showAddToday=false
        }
    }
    if(showPaywall) {
        UpgradeSheet(
            displayPrice = displayPrice,
            billingIssue = billingIssue,
            takeHomeCents = takeHomeCents,
            onPurchase = { billing.launchPurchase(activity) },
            onRestore = { billing.restore() },
            onDismiss = { showPaywall=false; pendingAction=null }
        )
    }
}
