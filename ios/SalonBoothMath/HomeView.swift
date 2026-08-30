import SwiftUI
import UIKit

struct HomeView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue
    @AppStorage("payModel") private var savedPayModel = PayModel.booth.rawValue
    @AppStorage("rentCents") private var rentCents = 25000
    @AppStorage("rentPeriod") private var savedRentPeriod = RentPeriod.week.rawValue
    @AppStorage("commissionCutBasisPoints") private var commissionCutBasisPoints = 5500
    @AppStorage("tipOwner") private var savedTipOwner = TipOwner.you.rawValue
    @AppStorage("cardFeeBasisPoints") private var cardFeeBasisPoints = 290
    @AppStorage("servicesOnCardBasisPoints") private var servicesOnCardBasisPoints = 7000
    @AppStorage("extraFeesCents") private var extraFeesCents = 0
    @AppStorage("workerPaysCardFees") private var workerPaysCardFees = false
    @AppStorage("taxBasisPoints") private var taxBasisPoints = 2500
    @AppStorage("currentWeekDraftStart") private var currentWeekDraftStart = 0.0
    @AppStorage("currentWeekServices") private var currentWeekServices = ""
    @AppStorage("currentWeekCashTips") private var currentWeekCashTips = ""
    @AppStorage("currentWeekCardTips") private var currentWeekCardTips = ""
    @AppStorage("currentWeekSupplies") private var currentWeekSupplies = ""
    @AppStorage("currentWeekHours") private var currentWeekHours = ""
    @AppStorage("currentWeekDaysJSON") private var currentWeekDaysJSON = "[]"

    @StateObject private var purchases = PurchaseManager()
    @StateObject private var weekStore = WeekStore()
    @State private var services = ""
    @State private var cashTips = ""
    @State private var cardTips = ""
    @State private var supplies = ""
    @State private var hours = ""
    @State private var days: [DayLine] = []
    @State private var editingWeekStart: Date?
    @State private var showPaywall = false
    @State private var showBreakdown = false
    @State private var showCompare = false
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showShare = false
    @State private var showAddToday = false
    @State private var addedTodayGross: Int?
    @State private var shareImage: UIImage?
    @State private var pendingAction: LockedAction?

    private enum LockedAction { case save, compare, history }
    private var language: AppLanguage { AppLanguage.current(appLanguage) }
    private var payModel: PayModel { PayModel(rawValue: savedPayModel) ?? .booth }
    private var rentPeriod: RentPeriod { RentPeriod(rawValue: savedRentPeriod) ?? .week }
    private var tipOwner: TipOwner { TipOwner(rawValue: savedTipOwner) ?? .you }
    private var commissionCut: Decimal { MoneyMath.rate(fromBasisPoints: commissionCutBasisPoints) }
    private var cardFeeRate: Decimal { MoneyMath.rate(fromBasisPoints: cardFeeBasisPoints) }
    private var servicesOnCardRate: Decimal { MoneyMath.rate(fromBasisPoints: servicesOnCardBasisPoints) }
    private var taxRate: Decimal { MoneyMath.rate(fromBasisPoints: taxBasisPoints) }
    private var serviceCents: Int { MoneyMath.cents(from: services) }
    private var cashTipCents: Int { MoneyMath.cents(from: cashTips) }
    private var cardTipCents: Int { MoneyMath.cents(from: cardTips) }
    private var supplyCents: Int { MoneyMath.cents(from: supplies) }
    private var weeklyRentCents: Int { MoneyMath.weeklyRent(cents: rentCents, period: rentPeriod) }
    private var grossCents: Int { serviceCents + cashTipCents + cardTipCents }
    private var estimatedCardFees: Int { MoneyMath.cardFees(services: serviceCents, cardTips: cardTipCents, cardFeeRate: cardFeeRate, percentServicesOnCard: servicesOnCardRate) }
    private var boothTakeHome: Int { MoneyMath.boothTakeHome(services: serviceCents, cashTips: cashTipCents, cardTips: cardTipCents, supplies: supplyCents, weeklyRent: weeklyRentCents, extraFees: extraFeesCents, cardFeeRate: cardFeeRate, percentServicesOnCard: servicesOnCardRate) }
    private var commissionTakeHome: Int { MoneyMath.commissionTakeHome(services: serviceCents, cashTips: cashTipCents, cardTips: cardTipCents, supplies: supplyCents, cut: commissionCut, tipOwner: tipOwner, workerPaysCardFees: workerPaysCardFees, extraFees: extraFeesCents, cardFeeRate: cardFeeRate, percentServicesOnCard: servicesOnCardRate) }
    private var hybridTakeHome: Int { MoneyMath.hybridTakeHome(services: serviceCents, cashTips: cashTipCents, cardTips: cardTipCents, supplies: supplyCents, weeklyRent: weeklyRentCents, cut: commissionCut, tipOwner: tipOwner, workerPaysCardFees: workerPaysCardFees, extraFees: extraFeesCents, cardFeeRate: cardFeeRate, percentServicesOnCard: servicesOnCardRate) }
    private var takeHomeCents: Int { payModel == .booth ? boothTakeHome : (payModel == .commission ? commissionTakeHome : hybridTakeHome) }
    private var currentWeekStart: Date { Calendar.current.startOfWeek(for: Date()) }
    private var activeWeekStart: Date { editingWeekStart ?? currentWeekStart }
    private var isCurrentWeek: Bool { Calendar.current.isDate(activeWeekStart, equalTo: currentWeekStart, toGranularity: .weekOfYear) }
    private var highRentRatio: Decimal? { guard payModel != .commission, grossCents > 0 else { return nil }; return Decimal(weeklyRentCents) / Decimal(grossCents) }
    private var hoursValue: Double? { let n=hours.trimmingCharacters(in:.whitespacesAndNewlines).replacingOccurrences(of:",",with:"."); guard let v=Double(n),v>0 else{return nil};return v }
    private var lifetimePrice: String { purchases.product?.displayPrice ?? "$9.99" }
    private var payContext: String {
        switch payModel {
        case .booth: return "\(String(localized:"pay.booth")) · \(formatCurrency(weeklyRentCents))/\(String(localized:"rent.week"))"
        case .commission: return String(format:String(localized:"home.keepCut"),commissionCutBasisPoints/100)
        case .hybrid: return String(format:String(localized:"home.hybridContext",table:"Hybrid"),formatCurrency(weeklyRentCents),commissionCutBasisPoints/100)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack { Brand.page.ignoresSafeArea(); VStack(spacing:0){ header; ScrollView { VStack(spacing:0){ fields.padding(.top,26); result.padding(.top,30); actions.padding(.top,24).padding(.bottom,32) } }.scrollDismissesKeyboard(.interactively) } }
                .foregroundStyle(Brand.ink)
                .navigationDestination(isPresented:$showBreakdown){ BreakdownView(grossCents:grossCents,rentCents:weeklyRentCents,houseCutCents:MoneyMath.houseCut(services:serviceCents,workerCut:commissionCut),cardFeesCents:payModel == .booth || workerPaysCardFees ? estimatedCardFees : 0,suppliesCents:supplyCents,extraFeesCents:extraFeesCents,takeHomeCents:takeHomeCents,taxReserveCents:MoneyMath.taxReserve(takeHomeCents:takeHomeCents,rate:taxRate),payModel:payModel,hoursText:$hours) }
                .navigationDestination(isPresented:$showCompare){ CompareView(boothCents:boothTakeHome,commissionCents:commissionTakeHome,hybridCents:hybridTakeHome,commissionPercent:commissionCutBasisPoints/100) }
                .navigationDestination(isPresented:$showHistory){ HistoryView(store:weekStore){week in load(week);showHistory=false} }
                .navigationDestination(isPresented:$showSettings){ SettingsView() }
        }
        .sheet(isPresented:$showAddToday){ AddTodaySheet { addToday($0) }.presentationDetents([.large]).presentationDragIndicator(.visible) }
        .sheet(isPresented:$showPaywall){ PaywallView(purchases:purchases){unlocked in showPaywall=false;if unlocked{runPendingAction()} }.presentationDetents([.medium,.large]).presentationDragIndicator(.visible) }
        .sheet(isPresented:$showShare){ if let shareImage { ActivityShareView(items:[shareImage,formatCurrency(takeHomeCents),activeWeekStart.formatted(date:.abbreviated,time:.omitted)]) } }
        .onAppear{restoreCurrentWeekDraft();if isCurrentWeek{WidgetBridge.updateCurrentWeek(takeHomeCents:takeHomeCents)}}
        .onChange(of:services){_,_ in persistCurrentWeekDraft()}.onChange(of:cashTips){_,_ in persistCurrentWeekDraft()}.onChange(of:cardTips){_,_ in persistCurrentWeekDraft()}.onChange(of:supplies){_,_ in persistCurrentWeekDraft()}.onChange(of:hours){_,_ in persistCurrentWeekDraft()}.onChange(of:days){_,_ in persistCurrentWeekDraft()}
        .onChange(of:takeHomeCents){_,v in if isCurrentWeek{WidgetBridge.updateCurrentWeek(takeHomeCents:v)}}
    }

    private var header: some View { ZStack { VStack(spacing:3){Text(isCurrentWeek ? String(localized:"home.thisWeek") : weekRange(activeWeekStart)).font(Brand.font(19));Text(payContext).font(Brand.font(16)).foregroundStyle(.white)};HStack{if !isCurrentWeek{Button{returnToCurrentWeek()}label:{Image(systemName:"chevron.left").frame(width:48,height:48)}};Spacer();Menu{Picker(language.languageTitle,selection:$appLanguage){ForEach(AppLanguage.allCases){l in Text(l.displayName).tag(l.rawValue)}};Divider();if !purchases.isUnlocked{Button(String(format:String(localized:"paywall.unlockLifetime"),lifetimePrice)){pendingAction=nil;showPaywall=true}};Button("home.share"){shareCurrentWeek()};Button("history.title"){requireUnlock(.history)};Button("compare.title"){requireUnlock(.compare)};Button("settings.title"){showSettings=true}}label:{Image(systemName:"ellipsis.circle.fill").font(.system(size:23,weight:.bold)).frame(width:48,height:48)}}}.foregroundStyle(.white).padding(.horizontal,10).padding(.vertical,12).background(Brand.berry).overlay(alignment:.top){Rectangle().fill(Brand.hotPink).frame(height:4)} }
    private var fields: some View { VStack(spacing:20){HomeMoneyField(title:String(localized:"field.services"),text:$services);HomeMoneyField(title:String(localized:"field.tipsCash"),text:$cashTips);HomeMoneyField(title:String(localized:"field.tipsCard"),text:$cardTips);HomeMoneyField(title:String(localized:"field.supplies"),text:$supplies)}.padding(.horizontal,Brand.screenPadding) }
    private var result: some View { VStack(spacing:8){Text("home.youTookHome").font(Brand.font(17)).foregroundStyle(Brand.hotPink);Text(formatCurrency(takeHomeCents)).font(Brand.font(52,weight:.heavy)).monospacedDigit().minimumScaleFactor(0.82).lineLimit(1);if let ratio=highRentRatio,ratio>=Decimal(string:"0.40")!{Text(String(format:String(localized:"br.rentHigh"),NSDecimalNumber(decimal:ratio).doubleValue.formatted(.percent.precision(.fractionLength(0))))).font(Brand.font(16)).foregroundStyle(Brand.warning).multilineTextAlignment(.center)};if let addedTodayGross{Text(copy(en:"Added today · \(formatCurrency(addedTodayGross))",es:"Agregado hoy · \(formatCurrency(addedTodayGross))",vi:"Đã thêm hôm nay · \(formatCurrency(addedTodayGross))")).font(Brand.font(16)).foregroundStyle(Brand.mutedInk)}}.frame(maxWidth:.infinity).padding(.horizontal,Brand.screenPadding) }
    private var actions: some View { VStack(spacing:14){if isCurrentWeek{Button{showAddToday=true}label:{Text(copy(en:"Add today",es:"Agregar hoy",vi:"Thêm hôm nay")).font(Brand.font(18,weight:.heavy)).foregroundStyle(Brand.hotPink).frame(maxWidth:.infinity,minHeight:58).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius:Brand.controlRadius))}};PrimaryButton(title:String(localized:"home.save")){requireUnlock(.save)};Button{showBreakdown=true}label:{Text("home.breakdown").font(Brand.font(18)).foregroundStyle(Brand.ink).frame(maxWidth:.infinity,minHeight:58).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius:Brand.controlRadius))};Button{requireUnlock(.compare)}label:{Text(String(localized:"home.compareDeal",table:"Hybrid")).font(Brand.font(18)).foregroundStyle(Brand.ink).frame(maxWidth:.infinity,minHeight:58).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius:Brand.controlRadius))}}.padding(.horizontal,Brand.screenPadding) }

    private func addToday(_ line: DayLine){ services=inputCurrencyCents(serviceCents+line.servicesCents);cashTips=inputCurrencyCents(cashTipCents+line.cashTipsCents);cardTips=inputCurrencyCents(cardTipCents+line.cardTipsCents);supplies=inputCurrencyCents(supplyCents+line.suppliesCents);if let h=line.hours{let total=(hoursValue ?? 0)+h;hours=total.formatted(.number.precision(.fractionLength(0...1)))};days.append(line);addedTodayGross=line.grossCents;persistCurrentWeekDraft();WidgetBridge.updateCurrentWeek(takeHomeCents:takeHomeCents) }
    private func restoreCurrentWeekDraft(){let start=currentWeekStart.timeIntervalSince1970;if abs(currentWeekDraftStart-start)>1{currentWeekDraftStart=start;currentWeekServices="";currentWeekCashTips="";currentWeekCardTips="";currentWeekSupplies="";currentWeekHours="";currentWeekDaysJSON="[]"};guard isCurrentWeek else{return};services=currentWeekServices;cashTips=currentWeekCashTips;cardTips=currentWeekCardTips;supplies=currentWeekSupplies;hours=currentWeekHours;if let data=currentWeekDaysJSON.data(using:.utf8),let decoded=try? JSONDecoder().decode([DayLine].self,from:data){days=decoded}else{days=[]}}
    private func persistCurrentWeekDraft(){guard isCurrentWeek else{return};currentWeekDraftStart=currentWeekStart.timeIntervalSince1970;currentWeekServices=services;currentWeekCashTips=cashTips;currentWeekCardTips=cardTips;currentWeekSupplies=supplies;currentWeekHours=hours;if let data=try? JSONEncoder().encode(days),let json=String(data:data,encoding:.utf8){currentWeekDaysJSON=json}}
    private func load(_ week:WeekRecord){editingWeekStart=week.weekStart;services=inputCurrencyCents(week.servicesCents);cashTips=inputCurrencyCents(week.cashTipsCents);cardTips=inputCurrencyCents(week.cardTipsCents);supplies=inputCurrencyCents(week.suppliesCents);hours=week.hours.map{$0.formatted(.number.precision(.fractionLength(0...1)))} ?? "";days=week.days;savedPayModel=week.payModel.rawValue}
    private func returnToCurrentWeek(){editingWeekStart=nil;restoreCurrentWeekDraft()}
    private func weekRange(_ start:Date)->String{let end=Calendar.current.date(byAdding:.day,value:6,to:start) ?? start;return "\(start.formatted(.dateTime.month(.abbreviated).day()))–\(end.formatted(.dateTime.month(.abbreviated).day()))"}
    private func shareCurrentWeek(){shareImage=ShareCardRenderer.image(takeHomeCents:takeHomeCents,weekStart:activeWeekStart);showShare=shareImage != nil}
    private func requireUnlock(_ action:LockedAction){pendingAction=action;if purchases.isUnlocked{runPendingAction()}else{showPaywall=true}}
    private func runPendingAction(){guard let action=pendingAction else{return};switch action{case .save:weekStore.save(WeekRecord(weekStart:activeWeekStart,servicesCents:serviceCents,cashTipsCents:cashTipCents,cardTipsCents:cardTipCents,suppliesCents:supplyCents,extraFeesCents:extraFeesCents,hours:hoursValue,payModel:payModel,takeHomeCents:takeHomeCents,days:days));if isCurrentWeek{WidgetBridge.updateCurrentWeek(takeHomeCents:takeHomeCents)};case .compare:showCompare=true;case .history:showHistory=true};pendingAction=nil}
    private func copy(en:String,es:String,vi:String)->String{switch language{case .english:en;case .spanish:es;case .vietnamese:vi}}
}

private struct HomeMoneyField: View { let title:String;@Binding var text:String;@FocusState private var focused:Bool;var body:some View{VStack(alignment:.leading,spacing:11){Text(title).font(Brand.font(18)).foregroundStyle(Brand.ink);HStack(spacing:8){Text(Locale.current.currencySymbol ?? "$");TextField("0",text:$text).keyboardType(.decimalPad).focused($focused)}.font(Brand.font(29,weight:.heavy)).padding(.horizontal,16).frame(minHeight:64).background(Brand.surface).clipShape(RoundedRectangle(cornerRadius:Brand.controlRadius)).overlay(RoundedRectangle(cornerRadius:Brand.controlRadius).stroke(focused ? Brand.hotPink : Brand.line,lineWidth:focused ? 3:2))}.frame(maxWidth:.infinity)} }

struct PaywallView: View { @ObservedObject var purchases:PurchaseManager;let completion:(Bool)->Void;private var unlockTitle:String{String(format:String(localized:"paywall.unlockLifetime"),purchases.product?.displayPrice ?? "$9.99")};var body:some View{VStack(alignment:.leading,spacing:18){HStack{Capsule().fill(Brand.hotPink).frame(width:54,height:6);Spacer();Button(String(localized:"paywall.continueFree")){completion(false)}.font(Brand.font(16)).foregroundStyle(Brand.ink)};Text("paywall.lifetimeTitle").font(Brand.font(27,weight:.heavy)).lineLimit(2).minimumScaleFactor(0.85);Text("paywall.lifetimeBody").font(Brand.font(18)).foregroundStyle(Brand.mutedInk).fixedSize(horizontal:false,vertical:true);PrimaryButton(title:unlockTitle){Task{let ok=await purchases.purchase();if ok{completion(true)}}};Button{Task{await purchases.restore();if purchases.isUnlocked{completion(true)}}}label:{Text("paywall.restore").font(Brand.font(17)).foregroundStyle(Brand.ink).frame(maxWidth:.infinity,minHeight:54)};Button{completion(false)}label:{Text("paywall.continueFree").font(Brand.font(17)).foregroundStyle(Brand.muted).frame(maxWidth:.infinity,minHeight:54)}}.padding(24).background(Brand.page).foregroundStyle(Brand.ink)} }
struct ActivityShareView:UIViewControllerRepresentable{let items:[Any];func makeUIViewController(context:Context)->UIActivityViewController{UIActivityViewController(activityItems:items,applicationActivities:nil)};func updateUIViewController(_ uiViewController:UIActivityViewController,context:Context){} }
