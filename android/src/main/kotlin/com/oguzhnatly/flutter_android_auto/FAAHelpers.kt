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
 * Carrega uma imagem a partir de três formatos possíveis e retorna um [CarIcon]:
 *
 * - **URL de rede** (`http://` ou `https://`) — download via [HttpURLConnection].
 * - **Arquivo local** (`file://`) — leitura direta do sistema de arquivos.
 * - **Asset Flutter** (qualquer outro valor) — abre via `Context.assets` sob o
 *   prefixo `flutter_assets/`, que é onde o Flutter empacota os assets no APK.
 *   Exemplo: `"images/logo.png"` → `flutter_assets/images/logo.png`.
 *
 * Retorna `null` se o carregamento falhar por qualquer motivo.
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

