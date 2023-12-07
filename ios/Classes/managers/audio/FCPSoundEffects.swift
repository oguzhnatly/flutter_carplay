//
//  FCPSoundEffects.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 09/15/2021.
//

import AVFoundation

public final class FCPSoundEffects: NSObject {
    static let shared = FCPSoundEffects()

    var audioPlayer: AVPlayer? = nil
    var audioURL: URL? = nil

    var duration: CMTimeScale {
        return (audioPlayer?.currentItem?.asset.duration.timescale)!
    }

    override private init() {}

    func prepare(sound: String, volume: Float) {
        let x = SwiftFlutterCarplayPlugin.registrar?.lookupKey(forAsset: sound)

        guard let s = Bundle.main.path(forResource: x, ofType: nil) else {
            fatalError("[FlutterCarPlay]: Music could not be found in the resources.")
        }

        audioURL = URL(fileURLWithPath: s)
        audioPlayer = AVPlayer(url: audioURL!)
        audioPlayer?.volume = volume
    }

    func play() {
        audioPlayer?.play()
    }

    func pause() {
        audioPlayer?.pause()
    }
}
