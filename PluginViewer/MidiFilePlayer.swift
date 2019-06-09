//
//  MidiFilePlayer.swift
//  PluginViewer
//
//  Created by Gísli Másson on 05/06/2019.
//  Copyright © 2019 Gísli Másson. All rights reserved.
//

import Foundation
import AVFoundation

class MidiFilePlayer {
    
    private let audioEngine:AVAudioEngine
    private let midiSequencer:AVAudioSequencer
    private var canPlay:Bool = false
    
    var midiInstrument:AVAudioUnitMIDIInstrument? {
        willSet {
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            if let midiInstrument = midiInstrument {
                audioEngine.detach(midiInstrument)
            }
        }
        didSet {
            guard let midiInstrument = midiInstrument else {
                print("Bug: midi instrument is nil!")
                return
            }
            audioEngine.attach(midiInstrument)
            audioEngine.connect(midiInstrument, to: audioEngine.mainMixerNode, format: nil)
            do {
                try audioEngine.start()
            } catch {
                print("###Error: Could not start engine")
                return
            }
        }
    }
    
    var midiFile:String? {
        didSet {
            guard let midiFile = midiFile else {
                canPlay = false
                return
            }
            let fileURL = URL(fileURLWithPath: midiFile)
            
            do {
                try midiSequencer.load(from: fileURL, options: .smfChannelsToTracks)
            } catch {
                print("###Error: Failed to load midi sequence")
                canPlay = false
                return
            }
            canPlay = true

        }
    }
    
    init() {
        audioEngine = AVAudioEngine()
        audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: nil)
        midiSequencer = AVAudioSequencer(audioEngine: audioEngine)
    }
    
    func play() {
        guard canPlay else {
            print("Not ready to play")
            return
        }
        
        if midiSequencer.isPlaying {
            midiSequencer.stop()
        }
        midiSequencer.currentPositionInSeconds = 0
        
        midiSequencer.prepareToPlay()
        
        do {
            try midiSequencer.start()
        } catch {
            print("###Error: Failed to start sequencer")
            return
        }

    }
    
    func stop() {
        midiSequencer.stop()
    }

}
