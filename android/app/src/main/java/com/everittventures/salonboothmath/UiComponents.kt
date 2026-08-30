package com.everittventures.salonboothmath

import android.content.Context
import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
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
import java.util.Currency
import java.util.Date
import java.util.Locale

internal val Berry=Color(0xFF4B0728); internal val BerryDeep=Color(0xFF2D0418); internal val Surface=Color(0xFF65103B); internal val Ink=Color.White; internal val MutedInk=Color.White.copy(alpha=.78f); internal val Pink=Color(0xFFFF3D6E); internal val Warning=Pink; internal val Page=Berry; internal val AppFontFamily=FontFamily.SansSerif
@Composable internal fun SimpleScreen(title:String,back:()->Unit,content:@Composable ColumnScope.()->Unit){Column(Modifier.fillMaxSize().background(Page).padding(22.dp).verticalScroll(rememberScrollState()),verticalArrangement=Arrangement.spacedBy(20.dp)){TextButton(onClick=back){Text("‹ ${stringResource(R.string.back)}",color=Color.White,fontSize=16.sp,fontWeight=FontWeight.Bold,fontFamily=AppFontFamily)};Text(title,color=Ink,fontSize=32.sp,fontWeight=FontWeight.ExtraBold,fontFamily=AppFontFamily);content()}}
@Composable internal fun Metric(label:String,value:Long){Column(verticalArrangement=Arrangement.spacedBy(4.dp)){Text(label,color=Ink,fontSize=18.sp,fontWeight=FontWeight.Bold,fontFamily=AppFontFamily);Text(formatCents(value),color=Ink,fontSize=40.sp,fontWeight=FontWeight.ExtraBold,fontFamily=AppFontFamily)}}
@Composable internal fun CostRow(label:String,value:Long){Row(Modifier.fillMaxWidth(),horizontalArrangement=Arrangement.SpaceBetween){Text(label,color=Ink,fontSize=18.sp,fontWeight=FontWeight.Bold,fontFamily=AppFontFamily);Text("−${formatCents(value)}",color=Ink,fontSize=18.sp,fontWeight=FontWeight.ExtraBold,fontFamily=AppFontFamily)}}
@OptIn(ExperimentalMaterial3Api::class)
@Composable internal fun MoneyField(label:String,value:String,showCurrency:Boolean=true,onValue:(String)->Unit){
    Column(verticalArrangement=Arrangement.spacedBy(9.dp)){
        Text(label,color=Ink,fontSize=19.sp,fontWeight=FontWeight.Bold,fontFamily=AppFontFamily)
        OutlinedTextField(
            value=value,
            onValueChange={ raw ->
                val normalized = raw.replace(',', '.')
                if (normalized.isEmpty() || normalized.matches(Regex("\\d*(\\.\\d{0,2})?"))) onValue(normalized)
            },
            modifier=Modifier.fillMaxWidth().defaultMinSize(minHeight = 64.dp),
            enabled=true,
            readOnly=false,
            singleLine=true,
            keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Decimal),
            prefix=if(showCurrency){{Text(appCurrencySymbol(),color=Color.White,fontSize=24.sp,fontWeight=FontWeight.ExtraBold,fontFamily=AppFontFamily)}}else null,
            textStyle=LocalTextStyle.current.copy(color=Color.White,fontSize=24.sp,fontWeight=FontWeight.ExtraBold,fontFamily=AppFontFamily),
            shape=RoundedCornerShape(18.dp),
            colors=OutlinedTextFieldDefaults.colors(
                focusedTextColor=Color.White,
                unfocusedTextColor=Color.White,
                cursorColor=Pink,
                focusedBorderColor=Pink,
                unfocusedBorderColor=Color.White.copy(alpha=.32f),
                focusedContainerColor=Surface,
                unfocusedContainerColor=Surface,
                focusedPrefixColor=Color.White,
                unfocusedPrefixColor=Color.White
            )
        )
    }
}
@Composable internal fun PrimaryButton(label:String,action:()->Unit){Button(onClick=action,colors=ButtonDefaults.buttonColors(containerColor=Pink,contentColor=Color.White),modifier=Modifier.fillMaxWidth().height(62.dp),shape=RoundedCornerShape(18.dp)){Text(label,fontSize=19.sp,fontWeight=FontWeight.ExtraBold,fontFamily=AppFontFamily)}}
@Composable internal fun SingleChoiceSegment(options:List<Pair<String,String>>,selected:String,onSelect:(String)->Unit){Row(horizontalArrangement=Arrangement.spacedBy(8.dp)){options.forEach{(id,label)->Button(onClick={onSelect(id)},modifier=Modifier.weight(1f).height(56.dp),colors=ButtonDefaults.buttonColors(containerColor=if(selected==id)Pink else Surface,contentColor=Color.White),shape=RoundedCornerShape(16.dp)){Text(label,fontSize=16.sp,fontWeight=FontWeight.Bold,fontFamily=AppFontFamily,maxLines=1)}}}}
@Composable internal fun SettingToggle(label:String,checked:Boolean,onChecked:(Boolean)->Unit){Row(Modifier.fillMaxWidth(),verticalAlignment=Alignment.CenterVertically,horizontalArrangement=Arrangement.SpaceBetween){Text(label,color=Ink,fontSize=18.sp,fontWeight=FontWeight.Bold,fontFamily=AppFontFamily,modifier=Modifier.weight(1f));Switch(checked=checked,onCheckedChange=onChecked,colors=SwitchDefaults.colors(checkedThumbColor=Color.White,checkedTrackColor=Pink))}}
@Composable internal fun payContext(store:AppStore):String {
    val keep = store.commissionCutBasisPoints/100
    val house = 100 - keep
    return when(store.payModel){
        "commission" -> stringResource(R.string.keep_cut, keep, house)
        "hybrid" -> stringResource(R.string.hybrid_context, formatCents(store.weeklyRentCents), stringResource(R.string.week), keep)
        else -> "${stringResource(R.string.weekly_rent)} · ${formatCents(store.weeklyRentCents)}/${stringResource(R.string.week)}"
    }
}
internal fun selectedAppLanguage(): String {
    val tag = AppCompatDelegate.getApplicationLocales().toLanguageTags().substringBefore(",").trim()
    return if (tag.isEmpty()) "en" else tag
}
internal fun appLanguage(context: Context): String = context.getSharedPreferences("salon_booth_math", Context.MODE_PRIVATE).getString("app_language", "en") ?: "en"
internal fun localeFor(language: String): Locale = when (language) {
    "es" -> Locale.forLanguageTag("es-US")
    "vi" -> Locale.forLanguageTag("vi-US")
    else -> Locale.forLanguageTag("en-US")
}
internal fun formatCents(cents: Long, language: String = selectedAppLanguage()): String {
    val format = NumberFormat.getCurrencyInstance(localeFor(language))
    format.currency = Currency.getInstance("USD")
    return format.format(BigDecimal.valueOf(cents, 2))
}
internal fun appCurrencySymbol(language: String = selectedAppLanguage()): String {
    val format = NumberFormat.getCurrencyInstance(localeFor(language))
    format.currency = Currency.getInstance("USD")
    return format.currency?.symbol ?: "$"
}
internal fun inputMoney(cents:Long):String=BigDecimal.valueOf(cents,2).stripTrailingZeros().toPlainString(); internal fun cleanDecimal(value:Double):String=BigDecimal.valueOf(value).stripTrailingZeros().toPlainString(); internal fun percentText(basisPoints:Int):String=BigDecimal(basisPoints).movePointLeft(2).stripTrailingZeros().toPlainString()
internal fun settingsShowsBoothRent(payModel: String) = payModel != "commission"
internal fun settingsShowsServiceSplit(payModel: String) = payModel != "booth"
internal fun houseKeepPercent(userKeepText: String, fallbackPercent: String = "55"): Int {
    return (100 - percentBasisPoints(userKeepText, fallbackPercent) / 100).coerceIn(0, 100)
}
internal fun percentBasisPoints(text:String,fallback:String):Int{val normalized=text.trim().replace(',','.');val percent=normalized.toBigDecimalOrNull()?:BigDecimal(fallback);return percent.multiply(BigDecimal("100")).setScale(0,RoundingMode.HALF_UP).toInt()}
internal fun startOfWeek():Long{val c=Calendar.getInstance();c.set(Calendar.DAY_OF_WEEK,c.firstDayOfWeek);c.set(Calendar.HOUR_OF_DAY,0);c.set(Calendar.MINUTE,0);c.set(Calendar.SECOND,0);c.set(Calendar.MILLISECOND,0);return c.timeInMillis}
internal fun weekRange(startMillis:Long, language: String = selectedAppLanguage()):String{val locale=localeFor(language);val start=Calendar.getInstance().apply{timeInMillis=startMillis};val end=(start.clone() as Calendar).apply{add(Calendar.DAY_OF_MONTH,6)};val sf=SimpleDateFormat("MMM d",locale);val ef=if(start.get(Calendar.MONTH)==end.get(Calendar.MONTH))SimpleDateFormat("d",locale)else SimpleDateFormat("MMM d",locale);return "${sf.format(Date(startMillis))}–${ef.format(Date(end.timeInMillis))}"}
