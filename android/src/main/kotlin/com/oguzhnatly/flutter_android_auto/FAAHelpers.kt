package com.oguzhnatly.flutter_android_auto

import android.content.Context
import android.graphics.BitmapFactory
import androidx.car.app.model.CarIcon
import androidx.core.graphics.drawable.IconCompat
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object FAAHelpers {
    fun makeFCPChannelId(event: String): String {
        return "com.oguzhnatly.flutter_android_auto" + event
    }
}

suspend fun loadCarImageAsync(imageUrl: String): CarIcon? {
    return withContext(Dispatchers.IO) {
        try {
            val url = URL(imageUrl)
            val connection = url.openConnection() as HttpURLConnection
            connection.doInput = true
            connection.connect()
            val inputStream = connection.inputStream
            val bitmap = BitmapFactory.decodeStream(inputStream)
            val iconCompat = IconCompat.createWithBitmap(bitmap)
            CarIcon.Builder(iconCompat).build()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}

