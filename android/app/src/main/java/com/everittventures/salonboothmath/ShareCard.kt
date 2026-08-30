package com.everittventures.salonboothmath

import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileOutputStream

object ShareCard {
    fun share(context: Context, takeHomeCents: Long, weekStartMillis: Long) {
        val file = render(context, takeHomeCents, weekStartMillis) ?: return
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        context.startActivity(Intent.createChooser(intent, context.getString(R.string.share)))
    }

    private fun render(context: Context, takeHomeCents: Long, weekStartMillis: Long): File? = runCatching {
        val size = 1080
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val berry = Color.rgb(74, 24, 53)
        val pink = Color.rgb(255, 61, 110)
        val white = Color.WHITE

        canvas.drawColor(berry)
        val accentPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = pink }
        canvas.drawRect(0f, 0f, size.toFloat(), 18f, accentPaint)

        val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = white
            textSize = 54f
            typeface = android.graphics.Typeface.create("sans-serif", android.graphics.Typeface.BOLD)
        }
        val amountPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = white
            textSize = 170f
            typeface = android.graphics.Typeface.create("sans-serif", android.graphics.Typeface.BOLD)
        }
        val bodyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = white
            textSize = 54f
            typeface = android.graphics.Typeface.create("sans-serif", android.graphics.Typeface.BOLD)
        }

        val language = appLanguage(context)
        val localized = context.createConfigurationContext(Configuration(context.resources.configuration).apply {
            setLocale(localeFor(language))
        })
        val amount = formatCents(takeHomeCents, language)
        val week = weekRange(weekStartMillis, language)

        canvas.drawText(localized.getString(R.string.you_took_home), 76f, 190f, labelPaint)
        canvas.drawText(amount, 76f, 430f, amountPaint)
        canvas.drawText(week, 76f, 560f, bodyPaint)
        canvas.drawText("Salon Booth Math", 76f, 930f, bodyPaint)

        val dir = File(context.cacheDir, "shared").apply { mkdirs() }
        val file = File(dir, "salon-booth-math.png")
        FileOutputStream(file).use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        bitmap.recycle()
        file
    }.getOrNull()
}
