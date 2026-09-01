package com.everittventures.salonboothmath

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class BillingManager(private val context: Context) : PurchasesUpdatedListener {
    companion object {
        // Keep this aligned with the one-time product configured in Google Play Console.
        const val PRODUCT_ID = "com.everittventures.salonboothmath.lifetime"
    }

    private val billingClient = BillingClient.newBuilder(context)
        .setListener(this)
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder()
                .enableOneTimeProducts()
                .build()
        )
        .enableAutoServiceReconnection()
        .build()

    private val _isUnlocked = MutableStateFlow(false)
    val isUnlocked: StateFlow<Boolean> = _isUnlocked

    private val _displayPrice = MutableStateFlow("$9.99")
    val displayPrice: StateFlow<String> = _displayPrice

    private var productDetails: ProductDetails? = null
    private var purchaseInFlight = false

    fun start() {
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    queryProduct()
                    queryPurchases()
                }
            }
            override fun onBillingServiceDisconnected() = Unit
        })
    }

    private fun queryProduct(onLoaded: ((ProductDetails?) -> Unit)? = null) {
        val product = QueryProductDetailsParams.Product.newBuilder()
            .setProductId(PRODUCT_ID)
            .setProductType(BillingClient.ProductType.INAPP)
            .build()
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(listOf(product))
            .build()

        billingClient.queryProductDetailsAsync(params) { result, response ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                val loaded = response.productDetailsList.firstOrNull()
                if (loaded != null) {
                    productDetails = loaded
                    _displayPrice.value = loaded.oneTimePurchaseOfferDetails?.formattedPrice ?: _displayPrice.value
                }
                onLoaded?.invoke(loaded)
            } else {
                onLoaded?.invoke(null)
            }
        }
    }

    fun launchPurchase(activity: Activity) {
        if (purchaseInFlight) return
        purchaseInFlight = true

        val cached = productDetails
        if (cached != null) {
            launchLoadedPurchase(activity, cached)
            return
        }

        // A customer can tap Buy before the initial Play product query finishes.
        // Load the exact product on demand instead of silently doing nothing.
        queryProduct { loaded ->
            if (loaded == null) {
                purchaseInFlight = false
                return@queryProduct
            }
            launchLoadedPurchase(activity, loaded)
        }
    }

    private fun launchLoadedPurchase(activity: Activity, details: ProductDetails) {
        val productParams = BillingFlowParams.ProductDetailsParams.newBuilder()
            .setProductDetails(details)
            .build()
        val result = billingClient.launchBillingFlow(
            activity,
            BillingFlowParams.newBuilder()
                .setProductDetailsParamsList(listOf(productParams))
                .build()
        )
        if (result.responseCode != BillingClient.BillingResponseCode.OK) {
            purchaseInFlight = false
        }
    }

    fun restore() = queryPurchases()

    private fun queryPurchases() {
        val params = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.INAPP)
            .build()
        billingClient.queryPurchasesAsync(params) { result, purchases ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                handlePurchases(purchases)
            }
        }
    }

    override fun onPurchasesUpdated(result: BillingResult, purchases: MutableList<Purchase>?) {
        purchaseInFlight = false
        if (result.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            handlePurchases(purchases)
        }
    }

    private fun handlePurchases(purchases: List<Purchase>) {
        _isUnlocked.value = purchases.any { purchase ->
            purchase.products.contains(PRODUCT_ID) &&
                purchase.purchaseState == Purchase.PurchaseState.PURCHASED
        }

        purchases
            .filter {
                it.products.contains(PRODUCT_ID) &&
                    it.purchaseState == Purchase.PurchaseState.PURCHASED &&
                    !it.isAcknowledged
            }
            .forEach { purchase ->
                billingClient.acknowledgePurchase(
                    AcknowledgePurchaseParams.newBuilder()
                        .setPurchaseToken(purchase.purchaseToken)
                        .build()
                ) { }
            }
    }
}
