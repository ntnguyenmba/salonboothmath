package com.everittventures.salonboothmath

import android.view.ViewGroup
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdSize
import com.google.android.gms.ads.AdView

private const val SALON_BOOTH_BANNER_AD_UNIT_ID = "ca-app-pub-1237434632796366/6297592214"

@Composable
fun FreeBannerAd(modifier: Modifier = Modifier) {
    AndroidView(
        modifier = modifier,
        factory = { context ->
            AdView(context).apply {
                adUnitId = SALON_BOOTH_BANNER_AD_UNIT_ID
                setAdSize(AdSize.BANNER)
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                )
                loadAd(AdRequest.Builder().build())
            }
        }
    )

    DisposableEffect(Unit) {
        onDispose { }
    }
}
