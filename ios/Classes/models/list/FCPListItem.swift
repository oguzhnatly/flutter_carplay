//
//  FCPListItem.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

/// A wrapper class for CPListItem with additional functionality.
@available(iOS 14.0, *)
class FCPListItem {
    // MARK: Properties

    /// The underlying CPListItem instance.
    private(set) var _super: CPListItem?

    /// The unique identifier for the list item.
    private(set) var elementId: String

    /// The primary text of the list item.
    private var text: String

    /// The secondary text of the list item (optional).
    private var detailText: String?

    /// Indicates whether the onPressed event listener is active for the list item.
    private var isOnPressListenerActive: Bool = false

    /// A closure to be executed when the list item is selected.
    private var completeHandler: (() -> Void)?

    /// The image associated with the list item (optional).
    private var image: UIImage?

    /// The playback progress for the list item (optional).
    private var playbackProgress: CGFloat?

    /// Indicates whether the list item is in a playing state (optional).
    private var isPlaying: Bool?

    /// Indicates whether the list item is enabled (optional).
    private var isEnabled: Bool = true

    /// The location of the playing indicator on the list item (optional).
    private var playingIndicatorLocation: CPListItemPlayingIndicatorLocation?

    /// The accessory type for the list item (optional).
    private var accessoryType: CPListItemAccessoryType?

    /// The accessory image associated with the list item (optional).
    private var accessoryImage: UIImage?

    // MARK: Initializer

    /// Initializes an instance of FCPListItem with the provided parameters.
    ///
    /// - Parameter obj: A dictionary containing information about the list item.
    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String,
              let textValue = obj["text"] as? String
        else {
            fatalError("Missing required keys in dictionary for FCPListItem initialization.")
        }

        elementId = elementIdValue
        text = textValue
        detailText = obj["detailText"] as? String
        isOnPressListenerActive = obj["onPressed"] as? Bool ?? false

        image = UIImage.dynamicImage(lightImage: obj["image"] as? String,
                                     darkImage: obj["darkImage"] as? String)

        playbackProgress = obj["playbackProgress"] as? CGFloat
        isPlaying = obj["isPlaying"] as? Bool ?? false
        isEnabled = obj["isEnabled"] as? Bool ?? true

        accessoryImage = UIImage.dynamicImage(lightImage: obj["accessoryImage"] as? String,
                                              darkImage: obj["accessoryDarkImage"] as? String)

        setPlayingIndicatorLocation(fromString: obj["playingIndicatorLocation"] as? String)
        setAccessoryType(fromString: obj["accessoryType"] as? String)
    }

    // MARK: Computed Property

    /// Returns the underlying CPListItem instance configured with the specified properties.
    var get: CPListItem {
        let listItem = CPListItem(text: text, detailText: detailText)
        listItem.setFCPObject(self)
        listItem.handler = { [weak self] _, complete in
            guard let self = self else { return }
            if self.isOnPressListenerActive == true {
                DispatchQueue.main.async {
                    self.completeHandler = complete
                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onListItemSelected,
                                                     data: ["elementId": self.elementId])
                }
            } else {
                complete()
            }
        }
        if let imageValue = image {
            listItem.setImage(imageValue)
        }
        if let accessoryImageValue = accessoryImage {
            listItem.setAccessoryImage(accessoryImageValue)
        }
        if let playbackProgressValue = playbackProgress {
            listItem.playbackProgress = playbackProgressValue
        }
        if let isPlayingValue = isPlaying {
            listItem.isPlaying = isPlayingValue
        }
        if let playingIndicatorLocationValue = playingIndicatorLocation {
            listItem.playingIndicatorLocation = playingIndicatorLocationValue
        }
        if let accessoryTypeValue = accessoryType {
            listItem.accessoryType = accessoryTypeValue
        }
        if #available(iOS 15.0, *) {
            listItem.isEnabled = isEnabled
        }
        _super = listItem
        return listItem
    }

    // MARK: Public Methods

    /// Stops the onPressed event handler for the list item.
    public func stopHandler() {
        completeHandler?()
        completeHandler = nil
    }

    /// Updates the properties of the list item.
    ///
    /// - Parameters:
    ///   - text: The new primary text.
    ///   - detailText: The new secondary text.
    ///   - image: The new image.
    ///   - darkImage: The new dark image.
    ///   - accessoryImage: The new accessory image.
    ///   - accessoryDarkImage: The new accessory dark image.
    ///   - playbackProgress: The new playback progress.
    ///   - isPlaying: The new playing state.
    ///   - playingIndicatorLocation: The new playing indicator location.
    ///   - accessoryType: The new accessory type.
    ///   - isEnabled: The new enabled state.
    public func update(text: String?, detailText: String?, image: String?, darkImage: String?, accessoryImage: String?, accessoryDarkImage: String?, playbackProgress: CGFloat?, isPlaying: Bool?, playingIndicatorLocation: String?, accessoryType: String?, isEnabled: Bool?) {
        if let textValue = text {
            _super?.setText(textValue)
            self.text = textValue
        }
        if let detailTextValue = detailText {
            _super?.setDetailText(detailTextValue)
            self.detailText = detailTextValue
        }
        if let playbackProgressValue = playbackProgress {
            _super?.playbackProgress = playbackProgressValue
            self.playbackProgress = playbackProgressValue
        }
        if let isPlayingValue = isPlaying {
            _super?.isPlaying = isPlayingValue
            self.isPlaying = isPlayingValue
        }
        if let playingIndicatorLocationValue = playingIndicatorLocation {
            setPlayingIndicatorLocation(fromString: playingIndicatorLocationValue)
            if let location = self.playingIndicatorLocation {
                _super?.playingIndicatorLocation = location
            }
        }
        if let accessoryTypeValue = accessoryType {
            setAccessoryType(fromString: accessoryTypeValue)
            if let type = self.accessoryType {
                _super?.accessoryType = type
            }
        }

        let themeImage = UIImage.dynamicImage(lightImage: image,
                                              darkImage: darkImage)
        _super?.setImage(themeImage)
        self.image = themeImage

        let themeAccessoryImage = UIImage.dynamicImage(lightImage: accessoryImage,
                                                       darkImage: accessoryDarkImage)
        _super?.setAccessoryImage(themeAccessoryImage)
        self.accessoryImage = themeAccessoryImage

        if #available(iOS 15.0, *), let isEnabledValue = isEnabled {
            _super?.isEnabled = isEnabledValue
            self.isEnabled = isEnabledValue
        }
        _super?.setFCPObject(self)
    }

    // MARK: Private Methods

    private func setPlayingIndicatorLocation(fromString: String?) {
        if fromString == "leading" {
            playingIndicatorLocation = CPListItemPlayingIndicatorLocation.leading
        } else if fromString == "trailing" {
            playingIndicatorLocation = CPListItemPlayingIndicatorLocation.trailing
        }
    }

    private func setAccessoryType(fromString: String?) {
        if fromString == "cloud" {
            accessoryType = CPListItemAccessoryType.cloud
        } else if fromString == "disclosureIndicator" {
            accessoryType = CPListItemAccessoryType.disclosureIndicator
        } else {
            accessoryType = CPListItemAccessoryType.none
        }
    }
}
