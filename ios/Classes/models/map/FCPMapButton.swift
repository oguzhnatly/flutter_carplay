//
//  FCPMapButton.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 25.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPMapButton {
    private(set) var _super: CPMapButton?
    private(set) var elementId: String
    private var isEnabled: Bool = true
    private var isHidden: Bool = false
    private var image: UIImage?
    private var focusedImage: UIImage?

    init(obj: [String: Any]) {
        elementId = obj["_elementId"] as! String
        isEnabled = obj["isEnabled"] as! Bool
        isHidden = obj["isHidden"] as! Bool
        if let image = obj["image"] as? String {
            self.image = UIImage().fromFlutterAsset(name: image)
        }
        if let focusedImage = obj["focusedImage"] as? String {
            self.focusedImage = UIImage().fromFlutterAsset(name: focusedImage)
        }
    }

    var get: CPMapButton {
        let mapButton = CPMapButton { _ in
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onMapButtonPressed, data: ["elementId": self.elementId])
            }
        }
        mapButton.isHidden = isHidden
        mapButton.isEnabled = isEnabled
        mapButton.focusedImage = focusedImage
        mapButton.image = image

        _super = mapButton
        return mapButton
    }
}
