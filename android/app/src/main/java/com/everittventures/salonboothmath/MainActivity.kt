package com.everittventures.salonboothmath

import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.ui.graphics.Color
import androidx.core.os.LocaleListCompat

class MainActivity : AppCompatActivity() {
    private lateinit var billing: BillingManager

    override fun onCreate(savedInstanceState: Bundle?) {
        val prefs = getSharedPreferences("salon_booth_math", MODE_PRIVATE)
        val savedLanguage = prefs.getString("app_language", "en") ?: "en"
        AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(savedLanguage))

        super.onCreate(savedInstanceState)
        billing = BillingManager(this).also { it.start() }
        setContent {
            MaterialTheme(
                colorScheme = darkColorScheme(
                    primary = Pink,
                    onPrimary = Color.White,
                    background = Page,
                    onBackground = Color.White,
                    surface = BerryDeep,
                    onSurface = Color.White,
                    surfaceVariant = Surface,
                    onSurfaceVariant = Color.White,
                    outline = Color.White.copy(alpha = 0.28f)
                )
            ) {
                SalonBoothApp(billing)
            }
        }
    }
}
