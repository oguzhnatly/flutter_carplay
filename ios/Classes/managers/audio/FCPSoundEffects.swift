//
//  FCPSoundEffects.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 09/15/2021.
//

import AVFoundation

/// A singleton class responsible for managing sound effects in the Flutter CarPlay plugin.
public final class FCPSoundEffects: NSObject {
    /// Shared instance of the sound effects manager.
    public static let shared = FCPSoundEffects()

    /// The audio player used for playing sound effects.
    var audioPlayer: AVPlayer? = nil

    /// The URL of the audio file used for sound effects.
    var audioURL: URL? = nil

    /// The duration of the currently loaded audio file.
    var duration: CMTimeScale {
        return (audioPlayer?.currentItem?.asset.duration.timescale)!
    }

    /// Private initializer to ensure a singleton instance.
    override private init() {}

    /// Prepares the sound effects with the specified audio file and volume.
    ///
    /// - Parameters:
    ///   - sound: The name of the audio file.
    ///   - volume: The volume level for the sound effects.
    func prepare(sound: String, volume: Float) {
        let x = SwiftFlutterCarplayPlugin.registrar?.lookupKey(forAsset: sound)

        guard let s = Bundle.main.path(forResource: x, ofType: nil) else {
            fatalError("[FlutterCarPlay]: Music could not be found in the resources.")
        }

        audioURL = URL(fileURLWithPath: s)
        audioPlayer = AVPlayer(url: audioURL ?? URL(fileURLWithPath: ""))
        audioPlayer?.volume = volume
    }

    /// Plays the prepared sound effects.
    func play() {
        audioPlayer?.play()
    }

    /// Pauses the currently playing sound effects.
    func pause() {
        audioPlayer?.pause()
    }
}
