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
  private var titleVariants: Array<String>
  private var image: String?
  private var repeats: Bool
  
  init(obj: [String : Any]) {
    self.elementId = obj["_elementId"] as! String
    self.identifier = obj["identifier"] as! String
    self.titleVariants = obj["titleVariants"] as! Array<String>
    self.image = obj["image"] as? String
    self.repeats = obj["repeats"] as? Bool ?? false
  }
  
  var get: CPVoiceControlState {
    let voiceControlState = CPVoiceControlState(identifier: self.identifier,
                                                titleVariants: self.titleVariants,
                                                image: self.image != nil ? UIImage().fromFlutterAsset(name: self.image!) : nil,
                                                repeats: self.repeats)
    self._super = voiceControlState
    return voiceControlState
  }
}
