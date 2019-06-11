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
    
    var midiURL:URL? {
        didSet {
            guard let midiURL = midiURL else {
                canPlay = false
                return
            }
            do {
                try midiSequencer.load(from: midiURL, options: .smfChannelsToTracks)
            } catch {
                print("###Error: Failed to load midi sequence")
                canPlay = false
                return
            }
            canPlay = true
        }
    }
    
    /*
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
    */
    
    var wavFile:String?
    
    init() {
        audioEngine = AVAudioEngine()
        audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: nil)
        midiSequencer = AVAudioSequencer(audioEngine: audioEngine)
    }
    
    func play() {
        
        guard canPlay else {
            print("Not ready to play: No midi file")
            return
        }
        guard midiInstrument != nil else {
            print("Not ready to play: No plugin")
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
        midiSequencer.currentPositionInSeconds = 0
    }
    
    func render() {

        guard let midiInstrument = midiInstrument else {
            print("###Error: no instrument loaded")
            return
        }
        
        guard canPlay else {
            print("Not ready to render: No midi file")
            return
        }
        
        guard let wavFile = wavFile else {
            print("Not ready to render: No wav file")
            return
        }
        
        //Safer to stop audioEngine while we are setting everything up.
        //Maybe not necessary
        midiSequencer.stop()
        audioEngine.stop()
        
        guard let format = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: 48000.0, channels: 2, interleaved: true) else {
            print("###Error: AVAudioFormat failed")
            return
        }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 512) else {
            print("###Error: AVAudioPCMBuffer failed")
            return
        }
        
        do {
            try audioEngine.enableManualRenderingMode(AVAudioEngineManualRenderingMode.offline, format: format, maximumFrameCount: 512)
        } catch {
            print("###Error: enableManualRenderingMode failed")
            return
        }
        do {
            try midiInstrument.auAudioUnit.allocateRenderResources()
        } catch {
            print("###Could not allocate render resources")
            return
        }
        
        //Start because we stopped above
        
        do {
            try audioEngine.start()
        } catch {
            print("###Error: could not start engine")
            return
        }
        
        //print(sequencer.tracks.count)
        var lengthInSeconds:TimeInterval = 0
        for t in midiSequencer.tracks {
            print("Track length:\(t.lengthInSeconds)")
            if t.lengthInSeconds > lengthInSeconds {
                lengthInSeconds = t.lengthInSeconds
            }
        }
        
        if lengthInSeconds > 60.0 {
            print("Midi file is \(lengthInSeconds) seconds. Will not render")
            return
        }

        let lengthInFrames = UInt32(lengthInSeconds*48000+0.5)
        
        midiSequencer.prepareToPlay()
        
        do {
            try midiSequencer.start()
        } catch {
            print("###Error: Failed to start sequencer")
            return
        }

        let SAMPLE_RATE = Float64(48000.0)
        
        let outputFormatSettings = [
            AVFormatIDKey:kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey:32,
            AVLinearPCMIsFloatKey: true,
            //  AVLinearPCMIsBigEndianKey: false,
            AVSampleRateKey: SAMPLE_RATE,
            AVNumberOfChannelsKey: 2
            ] as [String : Any]
        
        let outputURL = URL(fileURLWithPath: wavFile)
        let outputFile:AVAudioFile
        do {
            outputFile = try AVAudioFile(forWriting: outputURL, settings: outputFormatSettings, commonFormat: AVAudioCommonFormat.pcmFormatFloat32, interleaved: true)
        } catch {
            print("###Error: Could not open file for writing")
            return
        }
        while(audioEngine.manualRenderingSampleTime<lengthInFrames) {
            //print("\(audioEngine.manualRenderingSampleTime)")
            do {
                try audioEngine.renderOffline(512, to: buffer)
            } catch {
                print("###Error: renderOffline failed")
                return
            }
            
            do {
                try outputFile.write(from: buffer)
            } catch let error as NSError {
                print("###Error: \(error)")
                return
            }
        }
        print("\(audioEngine.manualRenderingSampleTime)")
        midiInstrument.auAudioUnit.deallocateRenderResources()
        audioEngine.disableManualRenderingMode()
    }

}
