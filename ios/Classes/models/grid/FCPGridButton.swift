//
//  FCPGridButton.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPGridButton {
    private(set) var _super: CPGridButton?
    private(set) var elementId: String
    private var titleVariants: [String]
    private var image: String

    init(obj: [String: Any]) {
        elementId = obj["_elementId"] as! String
        titleVariants = obj["titleVariants"] as! [String]
        image = obj["image"] as! String
    }

    var get: CPGridButton {
        let gridButton = CPGridButton(titleVariants: titleVariants,
                                      image: UIImage().fromFlutterAsset(name: image),
                                      handler: { _ in
                                          DispatchQueue.main.async {
                                              FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onGridButtonPressed,
                                                                               data: ["elementId": self.elementId])
                                          }
                                      })
        gridButton.isEnabled = true
        _super = gridButton
        return gridButton
    }
}
