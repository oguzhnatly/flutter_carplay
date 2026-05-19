package com.oguzhnatly.flutter_android_auto

import android.graphics.BitmapFactory
import androidx.car.app.model.CarIcon
import androidx.core.graphics.drawable.IconCompat
import java.io.File
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object FAAHelpers {
    fun makeFCPChannelId(event: String): String {
        return "com.oguzhnatly.flutter_android_auto" + event
    }
}

/**
 * Loads an image from three possible formats and returns a [CarIcon]:
 *
 * - **Network URL** (`http://` or `https://`) — downloaded via [HttpURLConnection].
 * - **Local file** (`file://`) — read directly from the file system.
 * - **Flutter asset** (any other value) — opened via `Context.assets` under the
 *   `flutter_assets/` prefix, which is where Flutter packages assets inside the APK.
 *   Example: `"images/logo.png"` → `flutter_assets/images/logo.png`.
 *
 * Returns `null` if loading fails for any reason.
 */
suspend fun loadCarImageAsync(image: String): CarIcon? = withContext(Dispatchers.IO) {
    try {
        val bitmap = when {
            image.startsWith("http://") || image.startsWith("https://") -> {
                val connection = URL(image).openConnection() as HttpURLConnection
                connection.doInput = true
                connection.connect()
                BitmapFactory.decodeStream(connection.inputStream)
            }
            image.startsWith("file://") -> {
                BitmapFactory.decodeFile(File(URI(image)).absolutePath)
            }
            else -> {
                // Flutter asset: empacotado em flutter_assets/ dentro do APK
                val context = AndroidAutoService.session?.carContext
                    ?: return@withContext null
                context.assets.open("flutter_assets/$image").use { BitmapFactory.decodeStream(it) }
            }
        }
        bitmap?.let { CarIcon.Builder(IconCompat.createWithBitmap(it)).build() }
    } catch (e: Exception) {
        e.printStackTrace()
        null
    }
}

