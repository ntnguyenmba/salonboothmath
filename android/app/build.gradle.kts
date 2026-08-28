import org.jetbrains.kotlin.gradle.dsl.JvmTarget

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

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures { compose = true }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

val generatedLogoRes = layout.buildDirectory.dir("generated/logoRes")
val prepareAppLogo by tasks.registering(Copy::class) {
    from(rootProject.projectDir.parentFile.resolve("204DCB60-8DB2-480E-B020-6686D78673D4.png"))
    into(generatedLogoRes.map { it.dir("drawable-nodpi") })
    rename { "salon_booth_math_logo.png" }
}
android.sourceSets.getByName("main").res.srcDir(generatedLogoRes)
tasks.named("preBuild").configure { dependsOn(prepareAppLogo) }

dependencies {
    implementation(platform("androidx.compose:compose-bom:2024.12.01"))
    implementation("androidx.activity:activity-compose:1.10.0")
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.glance:glance-appwidget:1.2.0")
    implementation("com.android.billingclient:billing-ktx:9.1.0")
    testImplementation("junit:junit:4.13.2")
    debugImplementation("androidx.compose.ui:ui-tooling")
}
