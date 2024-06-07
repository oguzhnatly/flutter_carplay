package com.oguzhnatly.flutter_carplay.models.list

import CPListItemAccessoryType
import FCPChannelTypes
import androidx.car.app.model.ParkedOnlyOnClickListener
import androidx.car.app.model.Row
import com.oguzhnatly.flutter_carplay.Bool
import com.oguzhnatly.flutter_carplay.CGFloat
import com.oguzhnatly.flutter_carplay.CPListItem
import com.oguzhnatly.flutter_carplay.FCPStreamHandlerPlugin
import com.oguzhnatly.flutter_carplay.UIImage

/**
 * A wrapper class for CPListItem with additional functionality.
 *
 * @param obj A map containing information about the list item.
 */
class FCPListItem
    (obj: Map<String, Any>) {

    /// The underlying CPListItem instance.
    private lateinit var _super: CPListItem

    /// The unique identifier for the list item.
    var elementId: String
        private set

    /// The primary text of the list item.
    private var text: String

    /// The secondary text of the list item (optional).
    private var detailText: String?

    /// Indicates whether the onPressed event listener is active for the list item.
    private var isOnPressListenerActive: Bool

    /// A closure to be executed when the list item is selected.
    private var completeHandler: (() -> Unit)? = null

    /// The image associated with the list item (optional).
    private var image: UIImage? = null

    /// The playback progress for the list item (optional).
    private var playbackProgress: CGFloat? = null

    /// Indicates whether the list item is in a playing state (optional).
    private var isPlaying: Bool? = null

    /// Indicates whether the list item is enabled (optional).
    private var isEnabled: Bool

//    /// The location of the playing indicator on the list item (optional).
//    private var playingIndicatorLocation: CPListItemPlayingIndicatorLocation?

    /// The accessory type for the list item (optional).
    private var accessoryType: CPListItemAccessoryType? = null

    /// The accessory image associated with the list item (optional).
    private var accessoryImage: UIImage? = null


    init {
        val elementIdValue = obj["_elementId"] as? String
        val textValue = obj["text"] as? String
        assert(elementIdValue != null && textValue != null) { "Missing required keys in dictionary for FCPListItem initialization." }
        elementId = elementIdValue!!
        text = textValue!!
        detailText = obj["detailText"] as? String
        isOnPressListenerActive = obj["onPressed"] as? Bool ?: false
        playbackProgress = obj["playbackProgress"] as? CGFloat
        isPlaying = obj["isPlaying"] as? Bool ?: false
        isEnabled = obj["isEnabled"] as? Bool ?: true

//        image = UIImage.dynamicImage(
//            lightImage: obj["image"] as? String,
//            darkImage: obj["darkImage"] as? String
//        )
//
//        accessoryImage = UIImage.dynamicImage(
//            lightImage: obj["accessoryImage"] as? String,
//            darkImage: obj["accessoryDarkImage"] as? String
//        )
//
//        setPlayingIndicatorLocation(obj["playingIndicatorLocation"] as? String)
//        setAccessoryType(obj["accessoryType"] as? String)
    }


    /** Returns the underlying CPListItem instance configured with the specified properties. */
    val getTemplate: CPListItem
        get() {
            val builder = Row.Builder()
                .setOnClickListener(
                    ParkedOnlyOnClickListener.create {
                        if (isOnPressListenerActive) {
                            FCPStreamHandlerPlugin.sendEvent(
                                FCPChannelTypes.onFCPListItemSelected.name,
                                mapOf("elementId" to elementId)
                            )
                        }
                    })
                .setTitle(text)
                .setEnabled(isEnabled)


//        listItem.setFCPObject(self)
//        listItem.handler = { [weak self] _, complete in
//            guard let self = self else { return }
//            if self.isOnPressListenerActive == true {
//                DispatchQueue.main.async {
//                    self.completeHandler = complete
//                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onFCPListItemSelected,
//                    data: ["elementId": self.elementId])
//                }
//            } else {
//                complete()
//            }
//        }
            detailText?.let { builder.addText(it) }
            image?.let { builder.setImage(it) }

//            accessoryImage?.let { builder.setAccessoryImage(it) }
//            playbackProgress?.let { builder.playbackProgress = it }
//            isPlaying?.let { builder.isPlaying = it }
//            playingIndicatorLocation?.let { builder.playingIndicatorLocation = it }
//            accessoryType?.let { builder.accessoryType = it }

            _super = builder.build()

            return _super
        }


    /** Stops the onPressed event handler for the list item. */
    fun stopHandler() {
        completeHandler?.invoke()
        completeHandler = null
    }

    /**
     * Updates the properties of the list item.
     *
     * @param text The new primary text.
     * @param detailText The new secondary text.
     * @param image The new image.
     * @param darkImage The new dark image.
     * @param accessoryImage The new accessory image.
     * @param accessoryDarkImage The new accessory dark image.
     * @param playbackProgress The new playback progress.
     * @param isPlaying The new playing state.
     * @param playingIndicatorLocation The new playing indicator location.
     * @param accessoryType The new accessory type.
     * @param isEnabled The new enabled state.
     */
    fun update(
        text: String?,
        detailText: String?,
        image: String?,
        darkImage: String?,
        accessoryImage: String?,
        accessoryDarkImage: String?,
        playbackProgress: CGFloat?,
        isPlaying: Bool?,
        playingIndicatorLocation: String?,
        accessoryType: String?,
        isEnabled: Bool?
    ) {

        text?.let { this.text = it }
        detailText?.let { this.detailText = it }
        isEnabled?.let { this.isEnabled = it }

//        isPlaying?.let { this.isPlaying = it }
//        image?.let { this.image = UIImage.dynamicImage(lightImage: it, darkImage: darkImage) }
//        accessoryImage?.let { this.accessoryImage = UIImage.dynamicImage(lightImage: it, darkImage: accessoryDarkImage) }
//        playbackProgress?.let { this.playbackProgress = it }
//        playingIndicatorLocation?.let { setPlayingIndicatorLocation(fromString: it) }
//        accessoryType?.let { setAccessoryType(fromString: it) }


//        invalidate()
    }


//    private fun setPlayingIndicatorLocation(fromString: String?) {
//        if fromString == "leading" {
//            playingIndicatorLocation = CPListItemPlayingIndicatorLocation.leading
//        } else if fromString == "trailing" {
//            playingIndicatorLocation = CPListItemPlayingIndicatorLocation.trailing
//        }
//    }
//
//    private fun setAccessoryType(fromString: String?) {
//        if fromString == "cloud" {
//            accessoryType = CPListItemAccessoryType.cloud
//        } else if fromString == "disclosureIndicator" {
//            accessoryType = CPListItemAccessoryType.disclosureIndicator
//        } else {
//            accessoryType = CPListItemAccessoryType.none
//        }
//    }
}
