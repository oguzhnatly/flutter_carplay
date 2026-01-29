//
//  FCPNowPlayingButton.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay.
//

import CarPlay

/// Protocol for all Now Playing button types
@available(iOS 14.0, *)
protocol FCPNowPlayingButtonProtocol {
    var elementId: String { get }
    func getButton() -> CPNowPlayingButton
}

/// Factory class for creating Now Playing buttons from Flutter arguments
@available(iOS 14.0, *)
class FCPNowPlayingButtonFactory {
    static func createButton(from obj: [String: Any]) -> FCPNowPlayingButtonProtocol? {
        guard let type = obj["type"] as? String else { return nil }
        
        switch type {
        case "repeat":
            return FCPNowPlayingRepeatButton(obj: obj)
        case "shuffle":
            return FCPNowPlayingShuffleButton(obj: obj)
        case "addToLibrary":
            return FCPNowPlayingAddToLibraryButton(obj: obj)
        case "more":
            return FCPNowPlayingMoreButton(obj: obj)
        case "playbackRate":
            return FCPNowPlayingPlaybackRateButton(obj: obj)
        case "image":
            return FCPNowPlayingImageButton(obj: obj)
        default:
            return nil
        }
    }
}

/// A button that cycles through repeat modes
@available(iOS 14.0, *)
class FCPNowPlayingRepeatButton: FCPNowPlayingButtonProtocol {
    private(set) var elementId: String
    
    init(obj: [String: Any]) {
        self.elementId = obj["_elementId"] as! String
    }
    
    func getButton() -> CPNowPlayingButton {
        return CPNowPlayingRepeatButton(handler: { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(
                    type: FCPChannelTypes.onNowPlayingButtonPressed,
                    data: ["elementId": self.elementId]
                )
            }
        })
    }
}

/// A button that toggles shuffle mode
@available(iOS 14.0, *)
class FCPNowPlayingShuffleButton: FCPNowPlayingButtonProtocol {
    private(set) var elementId: String
    
    init(obj: [String: Any]) {
        self.elementId = obj["_elementId"] as! String
    }
    
    func getButton() -> CPNowPlayingButton {
        return CPNowPlayingShuffleButton(handler: { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(
                    type: FCPChannelTypes.onNowPlayingButtonPressed,
                    data: ["elementId": self.elementId]
                )
            }
        })
    }
}

/// A button that adds the current item to the library
@available(iOS 14.0, *)
class FCPNowPlayingAddToLibraryButton: FCPNowPlayingButtonProtocol {
    private(set) var elementId: String
    
    init(obj: [String: Any]) {
        self.elementId = obj["_elementId"] as! String
    }
    
    func getButton() -> CPNowPlayingButton {
        return CPNowPlayingAddToLibraryButton(handler: { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(
                    type: FCPChannelTypes.onNowPlayingButtonPressed,
                    data: ["elementId": self.elementId]
                )
            }
        })
    }
}

/// A button that triggers a "more" action
@available(iOS 14.0, *)
class FCPNowPlayingMoreButton: FCPNowPlayingButtonProtocol {
    private(set) var elementId: String
    
    init(obj: [String: Any]) {
        self.elementId = obj["_elementId"] as! String
    }
    
    func getButton() -> CPNowPlayingButton {
        return CPNowPlayingMoreButton(handler: { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(
                    type: FCPChannelTypes.onNowPlayingButtonPressed,
                    data: ["elementId": self.elementId]
                )
            }
        })
    }
}

/// A button that cycles through playback rates
@available(iOS 14.0, *)
class FCPNowPlayingPlaybackRateButton: FCPNowPlayingButtonProtocol {
    private(set) var elementId: String
    
    init(obj: [String: Any]) {
        self.elementId = obj["_elementId"] as! String
    }
    
    func getButton() -> CPNowPlayingButton {
        return CPNowPlayingPlaybackRateButton(handler: { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(
                    type: FCPChannelTypes.onNowPlayingButtonPressed,
                    data: ["elementId": self.elementId]
                )
            }
        })
    }
}

/// A custom image button for the Now Playing screen
@available(iOS 14.0, *)
class FCPNowPlayingImageButton: FCPNowPlayingButtonProtocol {
    private(set) var elementId: String
    private var image: String
    
    init(obj: [String: Any]) {
        self.elementId = obj["_elementId"] as! String
        self.image = obj["image"] as! String
    }
    
    func getButton() -> CPNowPlayingButton {
        let imageSource = self.image.toImageSource()
        let uiImage = makeUIImage(from: imageSource)
        
        return CPNowPlayingImageButton(image: uiImage, handler: { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(
                    type: FCPChannelTypes.onNowPlayingButtonPressed,
                    data: ["elementId": self.elementId]
                )
            }
        })
    }
}
