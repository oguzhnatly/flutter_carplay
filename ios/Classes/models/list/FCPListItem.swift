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

        if let img = obj["image"] as? String {
            image = UIImage().fromFlutterAsset(name: img)
        }

        playbackProgress = obj["playbackProgress"] as? CGFloat
        isPlaying = obj["isPlaying"] as? Bool ?? false
        isEnabled = obj["isEnabled"] as? Bool ?? true

        if let accImage = obj["accessoryImage"] as? String {
            accessoryImage = UIImage().fromFlutterAsset(name: accImage)
        }

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
        if image != nil {
            listItem.setImage(image!)
        }
        if accessoryImage != nil {
            listItem.setAccessoryImage(accessoryImage!)
        }
        if playbackProgress != nil {
            listItem.playbackProgress = playbackProgress!
        }
        if isPlaying != nil {
            listItem.isPlaying = isPlaying!
        }
        if playingIndicatorLocation != nil {
            listItem.playingIndicatorLocation = playingIndicatorLocation!
        }
        if accessoryType != nil {
            listItem.accessoryType = accessoryType!
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
        guard completeHandler != nil else {
            return
        }
        completeHandler!()
        completeHandler = nil
    }

    /// Updates the properties of the list item.
    ///
    /// - Parameters:
    ///   - text: The new primary text.
    ///   - detailText: The new secondary text.
    ///   - image: The new image.
    ///   - accessoryImage: The new accessory image.
    ///   - playbackProgress: The new playback progress.
    ///   - isPlaying: The new playing state.
    ///   - playingIndicatorLocation: The new playing indicator location.
    ///   - accessoryType: The new accessory type.
    ///   - isEnabled: The new enabled state.
    public func update(text: String?, detailText: String?, image: String?, accessoryImage: String?, playbackProgress: CGFloat?, isPlaying: Bool?, playingIndicatorLocation: String?, accessoryType: String?, isEnabled: Bool?) {
        if text != nil {
            _super?.setText(text!)
            self.text = text!
        }
        if detailText != nil {
            _super?.setDetailText(detailText)
            self.detailText = detailText
        }
        if let image = image {
            let img = UIImage().fromFlutterAsset(name: image)
            _super?.setImage(img)
            self.image = img
        } else {
            _super?.setImage(nil)
            self.image = nil
        }
        if let accessoryImage = accessoryImage {
            let img = UIImage().fromFlutterAsset(name: accessoryImage)
            _super?.setAccessoryImage(img)
            self.accessoryImage = img
        } else {
            _super?.setAccessoryImage(nil)
            self.accessoryImage = nil
        }
        if playbackProgress != nil {
            _super?.playbackProgress = playbackProgress!
            self.playbackProgress = playbackProgress
        }
        if isPlaying != nil {
            _super?.isPlaying = isPlaying!
            self.isPlaying = isPlaying
        }
        if #available(iOS 15.0, *), isEnabled != nil {
            _super?.isEnabled = isEnabled!
            self.isEnabled = isEnabled!
        }
        if playingIndicatorLocation != nil {
            setPlayingIndicatorLocation(fromString: playingIndicatorLocation)
            if self.playingIndicatorLocation != nil {
                _super?.playingIndicatorLocation = self.playingIndicatorLocation!
            }
        }
        if accessoryType != nil {
            setAccessoryType(fromString: accessoryType)
            if self.accessoryType != nil {
                _super?.accessoryType = self.accessoryType!
            }
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
