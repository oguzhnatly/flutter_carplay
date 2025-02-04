//
//  FCPVoiceControlState.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 09/14/2021.
//

import CarPlay

/// A custom representation of a voice control state on CarPlay.
@available(iOS 14.0, *)
class FCPVoiceControlState {
    // MARK: Properties

    /// The underlying CPPointOfInterest instance.
    private(set) var _super: CPVoiceControlState?

    /// The unique identifier for the voice control state.
    private(set) var elementId: String

    /// The identifier associated with the voice control state.
    private var identifier: String

    /// An array of title variants for the voice control state.
    private var titleVariants: [String]

    /// The name of the image associated with the voice control state.
    private var image: UIImage?

    /// A boolean value indicating whether the voice control state repeats.
    private var repeats: Bool

    // MARK: Initialization

    /// Initializes a new instance of `FCPVoiceControlState` with the specified parameters.
    ///
    /// - Parameter obj: A dictionary containing the properties of the voice control state.
    init(obj: [String: Any]) {
        guard let elementId = obj["_elementId"] as? String,
              let identifier = obj["identifier"] as? String,
              let titleVariants = obj["titleVariants"] as? [String]
        else {
            fatalError("Missing required properties for FCPVoiceControlState initialization.")
        }

        self.elementId = elementId
        self.identifier = identifier
        self.titleVariants = titleVariants

        repeats = obj["repeats"] as? Bool ?? false
        if let imageValue = obj["image"] as? String {
            image = UIImage().fromFlutterAsset(name: imageValue)
        }
    }

    // MARK: Methods

    /// Returns a `CPVoiceControlState` object representing the voice control state.
    ///
    /// - Returns: A `CPVoiceControlState` object.
    var get: CPVoiceControlState {
        let voiceControlState = CPVoiceControlState(identifier: identifier,
                                                    titleVariants: titleVariants,
                                                    image: image,
                                                    repeats: repeats)
        _super = voiceControlState
        return voiceControlState
    }
}
