package com.everittventures.salonboothmath

import android.app.Activity
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.google.android.gms.ads.MobileAds
import com.google.android.ump.ConsentInformation
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.UserMessagingPlatform

object AdConsentManager {
    var canRequestAds by mutableStateOf(false)
        private set

    var privacyOptionsRequired by mutableStateOf(false)
        private set

    private var mobileAdsStarted = false

    fun requestConsent(activity: Activity) {
        val consentInformation = UserMessagingPlatform.getConsentInformation(activity)
        val parameters = ConsentRequestParameters.Builder().build()

        consentInformation.requestConsentInfoUpdate(
            activity,
            parameters,
            {
                refreshState(consentInformation)
                startMobileAdsIfAllowed(activity)

                UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity) {
                    refreshState(consentInformation)
                    startMobileAdsIfAllowed(activity)
                }
            },
            {
                refreshState(consentInformation)
                startMobileAdsIfAllowed(activity)
            }
        )
    }

    fun presentPrivacyOptions(activity: Activity) {
        val consentInformation = UserMessagingPlatform.getConsentInformation(activity)
        UserMessagingPlatform.showPrivacyOptionsForm(activity) {
            refreshState(consentInformation)
            startMobileAdsIfAllowed(activity)
        }
    }

    private fun refreshState(consentInformation: ConsentInformation) {
        canRequestAds = consentInformation.canRequestAds()
        privacyOptionsRequired =
            consentInformation.privacyOptionsRequirementStatus ==
                ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED
    }

    private fun startMobileAdsIfAllowed(activity: Activity) {
        if (!canRequestAds || mobileAdsStarted) return
        mobileAdsStarted = true
        MobileAds.initialize(activity)
    }
}
