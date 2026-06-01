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

/**
 * Builds a [CarIcon] from raw PNG bytes sent over the MethodChannel.
 *
 * Used for Flutter asset SVGs that are rasterized to PNG on the Dart side,
 * since [BitmapFactory] cannot decode SVG directly. Returns `null` when the
 * bytes are empty or cannot be decoded so callers can fall back to other
 * resolution strategies.
 */
fun makeCarIconFromBytes(bytes: ByteArray?): CarIcon? {
    if (bytes == null || bytes.isEmpty()) return null
    return try {
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null
        bitmap.toCarIcon()
    } catch (e: Exception) {
        e.printStackTrace()
        null
    }
}

/**
 * Loads a [CarIcon] from a Flutter asset path (e.g. `images/icon.png`).
 *
 * Resolves the asset's lookup key via the Flutter loader and reads the bytes
 * from the application's asset manager. Returns `null` when the asset cannot be
 * found or decoded.
 */
suspend fun loadCarImageFromAsset(context: Context, assetPath: String): CarIcon? {
    return withContext(Dispatchers.IO) {
        try {
            val key = FlutterInjector.instance().flutterLoader()
                .getLookupKeyForAsset(assetPath)
            context.assets.open(key).use { inputStream ->
                val bitmap = BitmapFactory.decodeStream(inputStream) ?: return@use null
                bitmap.toCarIcon()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}

/**
 * Loads a [CarIcon] from a local file path (`file://...` or an absolute path).
 *
 * Returns `null` when the file does not exist or cannot be decoded.
 */
suspend fun loadCarImageFromFile(path: String): CarIcon? {
    return withContext(Dispatchers.IO) {
        try {
            val filePath = path.removePrefix("file://")
            val file = File(filePath)
            if (!file.exists()) return@withContext null
            val bitmap = BitmapFactory.decodeFile(filePath) ?: return@withContext null
            bitmap.toCarIcon()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}

/**
 * Resolves a [CarIcon] for an image reference, preferring sources in order:
 *
 * 1. rasterized PNG [bytes] (e.g. from a Flutter asset SVG),
 * 2. a remote `http(s)` URL,
 * 3. a local `file://` path,
 * 4. a Flutter asset path.
 *
 * Returns `null` when nothing can be resolved.
 */
suspend fun resolveCarIcon(
    context: Context,
    bytes: ByteArray?,
    imageUrl: String?,
): CarIcon? {
    makeCarIconFromBytes(bytes)?.let { return it }

    val source = imageUrl?.trim()
    if (source.isNullOrEmpty()) return null

    return when {
        source.startsWith("http") -> loadCarImageAsync(source)
        source.startsWith("file://") -> loadCarImageFromFile(source)
        else -> loadCarImageFromAsset(context, source)
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
            val bitmap = BitmapFactory.decodeStream(inputStream) ?: return@withContext null
            bitmap.toCarIcon()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}

private fun android.graphics.Bitmap.toCarIcon(): CarIcon {
    val iconCompat = IconCompat.createWithBitmap(this)
    return CarIcon.Builder(iconCompat).build()
}
