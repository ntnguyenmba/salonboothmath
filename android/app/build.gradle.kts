plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "com.everittventures.salonboothmath"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.everittventures.salonboothmath"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    buildFeatures { compose = true }
    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    implementation(platform("androidx.compose:compose-bom:2024.12.01"))
    implementation("androidx.activity:activity-compose:1.10.0")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.glance:glance-appwidget:1.1.1")
    implementation("com.android.billingclient:billing-ktx:7.1.1")
    debugImplementation("androidx.compose.ui:ui-tooling")
}
