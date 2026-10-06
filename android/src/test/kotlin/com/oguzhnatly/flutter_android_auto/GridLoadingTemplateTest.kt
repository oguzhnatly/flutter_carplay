package com.oguzhnatly.flutter_android_auto

import androidx.car.app.model.CarIcon
import androidx.car.app.model.GridItem
import androidx.car.app.model.GridTemplate
import androidx.car.app.model.ItemList
import org.junit.Assert.*
import org.junit.Test

@org.junit.runner.RunWith(org.robolectric.RobolectricTestRunner::class)
@org.robolectric.annotation.Config(sdk = [28])
class GridLoadingTemplateTest {
    private fun grid(): GridTemplate {
        val items = ItemList.Builder()
        repeat(3) { index ->
            items.addItem(GridItem.Builder().setTitle("Button $index")
                .setImage(CarIcon.COMPOSE_MESSAGE).setOnClickListener {}.build())
        }
        return GridTemplate.Builder().setTitle("Normal title").setSingleList(items.build()).build()
    }

    @Test fun loadingCellUsesSpinnerWithoutImageOrClicks() {
        val normal = grid()
        val loading = buildGridLoadingTemplate(normal, 1, "Working")
        val items = loading.singleList!!.items.map { it as GridItem }
        assertEquals(3, items.size)
        assertEquals("Working", loading.title!!.toString())
        assertTrue(items[1].isLoading)
        assertNull(items[1].image)
        items.forEach { assertNull(it.onClickDelegate) }
        assertEquals((normal.singleList!!.items[0] as GridItem).image, items[0].image)
        assertFalse(normal.singleList!!.items.any { (it as GridItem).isLoading })
    }

    @Test fun blankLoadingMessageDoesNotShowNormalTitle() {
        for (message in listOf(null, "", "  ")) {
            assertNull(buildGridLoadingTemplate(grid(), 0, message).title)
        }
    }
}
