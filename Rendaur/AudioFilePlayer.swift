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
    
    var effect:AVAudioUnitEffect? {
        willSet {
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            if let effect = effect {
                audioEngine.disconnectNodeInput(effect)
                audioEngine.disconnectNodeOutput(effect)
                audioEngine.detach(effect)
            }
            audioEngine.disconnectNodeInput(audioEngine.outputNode)
            audioEngine.disconnectNodeOutput(audioFilePlayer)
        }
        didSet {
            if let effect = effect {
                audioEngine.attach(effect)
                audioEngine.connect(audioFilePlayer, to:effect, format: nil)
                audioEngine.connect(effect, to:audioEngine.outputNode, format: nil)
            } else {
                audioEngine.connect(audioFilePlayer, to:audioEngine.outputNode, format: nil)
            }

            do {
                try audioEngine.start()
            } catch {
                print("###Error: Could not start engine")
                return
            }
        }
    }
    
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
        //let mainMixer = audioEngine.mainMixerNode
        //audioEngine.connect(mainMixer, to: audioEngine.outputNode, format: nil)
        audioFilePlayer = AVAudioPlayerNode()
        audioEngine.attach(audioFilePlayer)
        //audioEngine.connect(audioFilePlayer, to:mainMixer, format: nil)
        audioEngine.connect(audioFilePlayer, to:audioEngine.outputNode, format: nil)
        do {
            try audioEngine.start()
        } catch {
            print("###Error: Could not start engine")
            return
        }
        print("started engine")
        if audioEngine.isRunning {
            print("engine running")
        }
    }
    
    func play() {
        if !audioEngine.isRunning {
            print("Engine not running. starting it")
            do {
                try audioEngine.start()
            } catch {
                print("Could not start engine")
            }
        }
        guard audioEngine.isRunning else {
            print("Engine not running")
            return
        }
        
        /*
        do {
            try audioEngine.start()
        } catch {
            print("Could not start engine")
            canPlay = false
        }
        */
        if canPlay {
            audioFilePlayer.play()
        }
    }
    
    func stop() {
        audioFilePlayer.stop()
    }
}
