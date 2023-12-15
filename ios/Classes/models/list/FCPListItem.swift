//
//  FCPListItem.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPListItem {
    private(set) var _super: CPListItem?
    private(set) var elementId: String
    private var text: String
    private var detailText: String?
    private var isOnPressListenerActive: Bool = false
    private var completeHandler: (() -> Void)?
    private var image: String?
    private var playbackProgress: CGFloat?
    private var isPlaying: Bool?
    private var isEnabled: Bool = true
    private var playingIndicatorLocation: CPListItemPlayingIndicatorLocation?
    private var accessoryType: CPListItemAccessoryType?

    init(obj: [String: Any]) {
        elementId = obj["_elementId"] as! String
        text = obj["text"] as! String
        detailText = obj["detailText"] as? String
        isOnPressListenerActive = obj["onPressed"] as? Bool ?? false
        image = obj["image"] as? String
        playbackProgress = obj["playbackProgress"] as? CGFloat
        isPlaying = obj["isPlaying"] as? Bool
        isEnabled = obj["isEnabled"] as? Bool ?? true
        setPlayingIndicatorLocation(fromString: obj["playingIndicatorLocation"] as? String)
        setAccessoryType(fromString: obj["accessoryType"] as? String)
    }

    var get: CPListItem {
        let listItem = CPListItem(text: text, detailText: detailText)
        listItem.handler = ((CPSelectableListItem, @escaping () -> Void) -> Void)? { [unowned self] _, complete in
            if self.isOnPressListenerActive == true {
                MemoryLogger.shared.appendEvent("isOnPressListenerActive: \(self.isOnPressListenerActive) for \(self.elementId)")
                DispatchQueue.main.async {
                    MemoryLogger.shared.appendEvent("Selected call passed to dart for \(self.elementId)")
                    self.completeHandler = complete
                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onListItemSelected,
                                                     data: ["elementId": self.elementId])
                    complete()
                }
            } else {
                MemoryLogger.shared.appendEvent("Complete called from swift for \(self.elementId)")
                complete()
            }
        }
        if image != nil {
            listItem.setImage(UIImage().fromFlutterAsset(name: image!))
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

    public func stopHandler() {
        guard completeHandler != nil else {
            MemoryLogger.shared.appendEvent("stopHandler is null for: \(elementId)")
            return
        }
        MemoryLogger.shared.appendEvent("stopHandler called for: \(elementId)")
        completeHandler!()
        completeHandler = nil
    }

    public func update(text: String?, detailText: String?, image: String?, playbackProgress: CGFloat?, isPlaying: Bool?, playingIndicatorLocation: String?, accessoryType: String?, isEnabled: Bool?) {
        if completeHandler == nil {
            MemoryLogger.shared.appendEvent("completeHandler is null when update for: \(elementId)")
        }
        if text != nil {
            _super?.setText(text!)
            self.text = text!
        }
        if detailText != nil {
            _super?.setDetailText(detailText)
            self.detailText = detailText
        }
        if image != nil {
            _super?.setImage(UIImage().fromFlutterAsset(name: image!))
            self.image = image
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
    }

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
