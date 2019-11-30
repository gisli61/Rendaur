//
//  MidiFilePlayer.swift
//  Rendaur
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
            audioEngine.connect(midiInstrument, to: audioEngine.outputNode, format: nil)
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
    
    //var wavFile:String?
    
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
    
    func render(_ outputURL:URL,_ offset:AVAudioFrameCount = 0,_ writeFile:Bool = true) -> Bool {

        let bufLen:AVAudioFrameCount = 512
        let sampleRate:Double = 48000.0
        let channels:AVAudioChannelCount = 2
        //FIXME: Since we are rendering twice, we cannot set this
        //pad, as then the sequence get shifted twice
        //However, by rendering twice, we may not need this to fix
        //startup problems
        let startPad:AVMusicTimeStamp = 0.0
        let maxLength:TimeInterval = 600.0

        guard let midiInstrument = midiInstrument else {
            print("###Error: no instrument loaded")
            return false
        }
        
        guard canPlay else {
            print("Not ready to render: No midi file")
            return false
        }
        
        /*
        guard let wavFile = wavFile else {
            print("Not ready to render: No wav file")
            return
        }
        */
        
        //Safer to stop audioEngine while we are setting everything up.
        //Maybe not necessary
        midiSequencer.stop()
        audioEngine.stop()
        
        guard let format = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: sampleRate, channels: channels, interleaved: true) else {
            print("###Error: AVAudioFormat failed")
            return false
        }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufLen) else {
            print("###Error: AVAudioPCMBuffer failed")
            return false
        }
        
        do {
            try audioEngine.enableManualRenderingMode(AVAudioEngineManualRenderingMode.offline, format: format, maximumFrameCount: bufLen)
        } catch {
            print("###Error: enableManualRenderingMode failed")
            return false
        }
        do {
            try midiInstrument.auAudioUnit.allocateRenderResources()
        } catch {
            print("###Could not allocate render resources")
            return false
        }
        
        midiInstrument.auAudioUnit.isRenderingOffline = true
        
        //Start because we stopped above
        
        do {
            try audioEngine.start()
        } catch {
            print("###Error: could not start engine")
            return false
        }
        
        //print(sequencer.tracks.count)
        var paddedLengthInSeconds:TimeInterval = 0
        var originalLengthInSeconds:TimeInterval = 0
        for t in midiSequencer.tracks {
            //Offsetting the rendering process to get rid of fade-in
            //problems at the start
            if t.lengthInSeconds > originalLengthInSeconds {
                originalLengthInSeconds = t.lengthInSeconds
            }
            t.offsetTime = startPad
            t.lengthInBeats += startPad
            //print("Track length:\(t.lengthInSeconds)")
            if t.lengthInSeconds > paddedLengthInSeconds {
                paddedLengthInSeconds = t.lengthInSeconds
            }
        }
        let shiftInSeconds = paddedLengthInSeconds-originalLengthInSeconds
        
        if originalLengthInSeconds > maxLength {
            print("Midi file is \(originalLengthInSeconds) seconds. Will not render")
            return false
        }
        
        //let pad:TimeInterval = 1.0
        
        
        let lengthInFrames   = UInt32(round(originalLengthInSeconds*sampleRate))
        let shiftInFrames    = UInt32(round(shiftInSeconds*sampleRate))
        let latencyInSeconds = midiInstrument.auAudioUnit.latency
        let latencyInFrames  = UInt32(round(latencyInSeconds*sampleRate))
        if writeFile {
            print("lengthInSeconds: \(originalLengthInSeconds)")
            //print("paddedLengthInSeconds: \(paddedLengthInSeconds)")
            print("lengthInFrames: \(lengthInFrames)")
            print("latency: \(latencyInFrames)")
        }
        
        //For testing purposes
        //let lengthInFrames:UInt32 = 50000
        
        //cannot be set to values < 0
        //midiSequencer.currentPositionInSeconds = -1.0
        
        midiSequencer.currentPositionInSeconds = 0
        midiSequencer.prepareToPlay()
        
        do {
            try midiSequencer.start()
        } catch {
            print("###Error: Failed to start sequencer")
            return false
        }

        //let SAMPLE_RATE = Float64(48000.0)
        
        /*
        let outputFormatSettings = [
            AVFormatIDKey:kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey:32,
            AVLinearPCMIsFloatKey: true,
            //  AVLinearPCMIsBigEndianKey: false,
            AVSampleRateKey: SAMPLE_RATE,
            AVNumberOfChannelsKey: 2
            ] as [String : Any]
        */
        
        
        let header=create48k32bitFloatWavHeader(lengthInFrames)
        
        let fileManager = FileManager.default
        
        if writeFile && !fileManager.createFile(atPath: outputURL.path, contents: nil, attributes: nil) {
            print("###Error: could not create file")
            return false
        }
        
        var fileHandle:FileHandle? = nil
        
        if writeFile {
            guard let fh = FileHandle(forWritingAtPath: outputURL.path) else {
                print("###Error: could not create file handle")
                return false
            }
            fileHandle = fh
        }
        
        if writeFile {
            fileHandle!.write(header)
        }

        /******Will do this myself, as this doesn't create float data
        let outputFile:AVAudioFile
        do {
            outputFile = try AVAudioFile(forWriting: outputURL, settings: outputFormatSettings, commonFormat: AVAudioCommonFormat.pcmFormatFloat32, interleaved: true)
        } catch {
            print("###Error: Could not open file for writing")
            return false
        }
        */
        
        //var displayInfo:Bool = true
        //var frameNum = 1
        
        let totalOffset = offset+shiftInFrames
        var remainingOffset = totalOffset
        
        while(audioEngine.manualRenderingSampleTime+Int64(bufLen)<totalOffset) {
            //Skipping buffers at beginning if offset is larger than buffer size
            do {
                try audioEngine.renderOffline(AVAudioFrameCount(bufLen), to: buffer)
            } catch {
                print("###Error: renderOffline failed")
                return false
            }
            remainingOffset -= bufLen
        }
        
        while(audioEngine.manualRenderingSampleTime<lengthInFrames+totalOffset) {
            //frameNum += 1
            //print("\(audioEngine.manualRenderingSampleTime)")
            let framesToRead = UInt32(min(Int64(lengthInFrames+totalOffset)-audioEngine.manualRenderingSampleTime,Int64(bufLen)))
            
            do {
                try audioEngine.renderOffline(AVAudioFrameCount(framesToRead), to: buffer)
            } catch {
                print("###Error: renderOffline failed")
                return false
            }
            
            
            guard let floatChannelData = buffer.floatChannelData else {
                print("###Error: Got no channelData")
                return false
            }
            
            let c = UnsafeBufferPointer<Float>(start:floatChannelData.pointee.advanced(by: Int(remainingOffset*channels)),count:Int(channels*(framesToRead-remainingOffset)))
            
            remainingOffset = 0
                //for index in 0..<512 {
                //    print("\(c[2*index])\t\(c[2*index+1])")
                //}
            
            if writeFile {
                fileHandle!.write(Data(buffer: c))
            }

            /*
            do {
                try outputFile.write(from: buffer)
            } catch let error as NSError {
                print("###Error: \(error)")
                return false
            }
            */

        }
        //print("\(audioEngine.manualRenderingSampleTime)")
        midiInstrument.auAudioUnit.deallocateRenderResources()
        audioEngine.disableManualRenderingMode()
        
        if writeFile {
            fileHandle!.closeFile()
        }
        midiSequencer.stop()
        return true
    }
    
    func create48k32bitFloatWavHeader(_ numFrames:UInt32) -> Data {
        
        let bytesPerSample:UInt16 = 4
        let numChannels:UInt16 = 2
        let sampleRate:UInt32 = 48000
        
        var intValue:UInt32 = 0
        let intValueBuffer = UnsafeBufferPointer<UInt32>(start: &intValue, count: 1)
        
        var shortValue:UInt16 = 0
        let shortValueBuffer = UnsafeBufferPointer<UInt16>(start: &shortValue, count:1)
        
        
        var header = Data()
        
        header.append(contentsOf:"RIFF".map {$0.asciiValue!}) //ckID
        
        //intValue = 4+26+12+8+UInt32(bytesPerSample)*UInt32(numChannels)*numFrames
        intValue = 4+24+8+UInt32(bytesPerSample)*UInt32(numChannels)*numFrames
        header.append(intValueBuffer) //cksize
        
        header.append(contentsOf:"WAVE".map {$0.asciiValue!}) //WAVEID
        
        header.append(contentsOf:"fmt ".map {$0.asciiValue!}) //ckID
        
        intValue = 16 //Must be 18 if cbSize is included
        header.append(intValueBuffer) //cksize
        
        shortValue = 3
        header.append(shortValueBuffer) //wFormatTag
        
        shortValue = numChannels
        header.append(shortValueBuffer) //nChannels
        
        intValue = sampleRate
        header.append(intValueBuffer)   //nSamplesPerSec
        
        intValue = intValue*UInt32(bytesPerSample)*UInt32(numChannels)
        header.append(intValueBuffer)   //nAvgBytesPerSec
        
        shortValue = bytesPerSample*numChannels
        header.append(shortValueBuffer)  //nBlockAlign
        
        shortValue = 8*bytesPerSample
        header.append(shortValueBuffer)  //wBitsPerSample
        
        /*****Left out in Ableton files*******
         shortValue = 0
         header.append(shortValueBuffer)  //cbSize. Not clear if it should be there.
         
         header.append(contentsOf:"fact".map {$0.asciiValue!}) //ckID
         
         intValue = 4
         header.append(intValueBuffer) //cksize
         
         intValue = numFrames
         header.append(intValueBuffer) //dwSampleLength
         */
        
        header.append(contentsOf:"data".map {$0.asciiValue!}) //ckID
        
        intValue = UInt32(bytesPerSample)*UInt32(numChannels)*numFrames
        header.append(intValueBuffer) //cksize
        
        return header
        
    }


}
