//
//  AudioFilePlayer.swift
//  Rendaur
//
//  Created by Gísli Másson on 09/10/2019.
//  Copyright © 2019 Gísli Másson. All rights reserved.
//

import Foundation
import AVFoundation

class AudioFilePlayer {
    private let audioEngine:AVAudioEngine
    private var audioFilePlayer:AVAudioPlayerNode
    private var canPlay:Bool = false
    
    var wavURL:URL? {
        didSet {
            guard let wavURL = wavURL else {
                canPlay = false
                return
            }
            do {
                let audioFile = try AVAudioFile(forReading: wavURL)
                audioFilePlayer.scheduleFile(audioFile, at: nil, completionHandler: nil)
            } catch {
                print("###Error: Failed to load wav file")
                canPlay = false
                return
            }
            canPlay = true
        }
    }

    init() {
        audioEngine = AVAudioEngine()
        let mainMixer = audioEngine.mainMixerNode
        audioEngine.connect(mainMixer, to: audioEngine.outputNode, format: nil)
        audioFilePlayer = AVAudioPlayerNode()
        audioEngine.attach(audioFilePlayer)
        audioEngine.connect(audioFilePlayer, to:mainMixer, format: nil)
    }
    
    func play() {
        do {
            try audioEngine.start()
        } catch {
            print("Could not start engine")
            canPlay = false
        }
        if canPlay {
            audioFilePlayer.play()
        }
    }
}
