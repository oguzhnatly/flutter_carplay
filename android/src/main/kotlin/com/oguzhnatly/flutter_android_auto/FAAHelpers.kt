package com.oguzhnatly.flutter_android_auto

import android.content.Context
import android.graphics.BitmapFactory
import androidx.car.app.model.CarIcon
import androidx.core.graphics.drawable.IconCompat
import io.flutter.FlutterInjector
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object FAAHelpers {
    fun makeFCPChannelId(event: String): String {
        return "com.oguzhnatly.flutter_android_auto" + event
    }
}

fun makeCarIconFromBytes(bytes: ByteArray?): CarIcon? {
    return makeCarIconFromBytes(bytes, null)
}

fun makeCarIconFromBytes(bytes: ByteArray?, imageTint: FAAImageTint?): CarIcon? {
    if (bytes == null || bytes.isEmpty()) return null
    return try {
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null
        bitmap.toCarIcon(imageTint)
    } catch (e: Exception) {
        e.printStackTrace()
        null
    }
}

suspend fun loadCarImageFromAsset(
    context: Context,
    assetPath: String,
    imageTint: FAAImageTint? = null,
): CarIcon? {
    return withContext(Dispatchers.IO) {
        try {
            val key = FlutterInjector.instance().flutterLoader()
                .getLookupKeyForAsset(assetPath)
            context.assets.open(key).use { inputStream ->
                val bitmap = BitmapFactory.decodeStream(inputStream) ?: return@use null
                bitmap.toCarIcon(imageTint)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}

suspend fun loadCarImageFromFile(
    path: String,
    imageTint: FAAImageTint? = null,
): CarIcon? {
    return withContext(Dispatchers.IO) {
        try {
            val filePath = path.removePrefix("file://")
            val file = File(filePath)
            if (!file.exists()) return@withContext null
            val bitmap = BitmapFactory.decodeFile(filePath) ?: return@withContext null
            bitmap.toCarIcon(imageTint)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}

suspend fun resolveCarIcon(
    context: Context,
    bytes: ByteArray?,
    imageUrl: String?,
    imageTint: FAAImageTint? = null,
): CarIcon? {
    makeCarIconFromBytes(bytes, imageTint)?.let { return it }

    val source = imageUrl?.trim()
    if (source.isNullOrEmpty()) return null

    return when {
        source.startsWith("http") -> loadCarImageAsync(source, imageTint)
        source.startsWith("file://") -> loadCarImageFromFile(source, imageTint)
        else -> loadCarImageFromAsset(context, source, imageTint)
    }
}

suspend fun loadCarImageAsync(
    imageUrl: String,
    imageTint: FAAImageTint? = null,
): CarIcon? {
    return withContext(Dispatchers.IO) {
        try {
            val url = URL(imageUrl)
            val connection = url.openConnection() as HttpURLConnection
            connection.doInput = true
            connection.connect()
            val inputStream = connection.inputStream
            val bitmap = BitmapFactory.decodeStream(inputStream) ?: return@withContext null
            bitmap.toCarIcon(imageTint)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}

private fun android.graphics.Bitmap.toCarIcon(imageTint: FAAImageTint? = null): CarIcon {
    val iconCompat = IconCompat.createWithBitmap(this)
    val builder = CarIcon.Builder(iconCompat)
    if (imageTint != null) {
        builder.setTint(imageTint.toCarColor())
    }
    return builder.build()
}
