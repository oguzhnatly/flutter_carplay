//
//  FCPVoiceControlState.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 09/14/2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPVoiceControlState {
    private(set) var _super: CPVoiceControlState?
    private(set) var elementId: String
    private var identifier: String
    private var titleVariants: [String]
    private var image: String?
    private var repeats: Bool

    init(obj: [String: Any]) {
        elementId = obj["_elementId"] as! String
        identifier = obj["identifier"] as! String
        titleVariants = obj["titleVariants"] as! [String]
        image = obj["image"] as? String
        repeats = obj["repeats"] as? Bool ?? false
    }

    var get: CPVoiceControlState {
        let voiceControlState = CPVoiceControlState(identifier: identifier,
                                                    titleVariants: titleVariants,
                                                    image: image != nil ? UIImage().fromFlutterAsset(name: image!) : nil,
                                                    repeats: repeats)
        _super = voiceControlState
        return voiceControlState
    }
}
