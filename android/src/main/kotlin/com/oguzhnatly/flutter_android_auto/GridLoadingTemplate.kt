package com.oguzhnatly.flutter_android_auto

import androidx.car.app.model.GridItem
import androidx.car.app.model.GridTemplate
import androidx.car.app.model.ItemList

// Uses only the already resolved native images. A tap must not reload assets or URLs.
internal fun buildGridLoadingTemplate(normal: GridTemplate, loadingIndex: Int, message: String?): GridTemplate {
    val list = ItemList.Builder()
    normal.singleList!!.items.forEachIndexed { index, item ->
        val gridItem = item as GridItem
        val builder = GridItem.Builder()
        gridItem.title?.let { builder.setTitle(it) }
        gridItem.text?.let { builder.setText(it) }
        if (index == loadingIndex) {
            builder.setLoading(true)
        } else {
            gridItem.image?.let { builder.setImage(it, gridItem.imageType) }
        }
        list.addItem(builder.build())
    }
    return GridTemplate.Builder().setSingleList(list.build()).apply {
        if (!message.isNullOrBlank()) setTitle(message)
        normal.headerAction?.let { setHeaderAction(it) }
        normal.actionStrip?.let { setActionStrip(it) }
    }.build()
}
