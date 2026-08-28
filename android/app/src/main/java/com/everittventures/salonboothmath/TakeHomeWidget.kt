package com.everittventures.salonboothmath

import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.*
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import java.text.NumberFormat

class TakeHomeWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = context.getSharedPreferences("salon_booth_math", Context.MODE_PRIVATE)
        val cents = prefs.getLong("widgetTakeHomeCents", 0L)
        val amount = NumberFormat.getCurrencyInstance().format(cents / 100.0)
        provideContent {
            Column(
                modifier = GlanceModifier.fillMaxSize().background(ColorProvider(Color(0xFF4A1835))).padding(16.dp),
                verticalAlignment = Alignment.Vertical.CenterVertically
            ) {
                Box(GlanceModifier.fillMaxWidth().height(4.dp).background(ColorProvider(Color(0xFFFF3D6E)))) {}
                Spacer(GlanceModifier.height(12.dp))
                Text("YOU TOOK HOME", style = TextStyle(color = ColorProvider(Color.White), fontSize = 15.sp, fontWeight = FontWeight.Bold))
                Spacer(GlanceModifier.height(5.dp))
                Text(amount, style = TextStyle(color = ColorProvider(Color.White), fontSize = 32.sp, fontWeight = FontWeight.Bold))
                Spacer(GlanceModifier.height(5.dp))
                Text("This week", style = TextStyle(color = ColorProvider(Color.White), fontSize = 16.sp, fontWeight = FontWeight.Bold))
            }
        }
    }
}

class TakeHomeWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = TakeHomeWidget()
}
