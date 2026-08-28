package com.everittventures.salonboothmath

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme

class MainActivity : ComponentActivity() {
    private lateinit var billing: BillingManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        billing = BillingManager(this).also { it.start() }
        setContent {
            MaterialTheme {
                SalonBoothApp(billing)
            }
        }
    }
}
