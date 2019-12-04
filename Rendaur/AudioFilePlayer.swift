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
    private var audioFile:AVAudioFile?
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
            audioEngine.disconnectNodeInput(audioEngine.mainMixerNode)
            audioEngine.disconnectNodeOutput(audioFilePlayer)
        }
        didSet {
            if let effect = effect {
                audioEngine.attach(effect)
                /*
                 For general info on connecting audio units etc see AudioKit
                 Look at connectEffects in AKAudioUnitManager
                 and createEffectAudioUnit
                 Look at connect function in AudioKit/Internals/AudioKit+SafeConnections
                 Convology is not happy getting nil as format. It throws error -10868 which
                 according to osstatus.com is kAudioUnitErr_FormatNotSupported
                 It seems to be ok to feed the input format to the effects, so I do that.
                 */
                let format = effect.inputFormat(forBus: 0)
                audioEngine.connect(audioFilePlayer, to:effect, format: format)
                audioEngine.connect(effect, to:audioEngine.outputNode, format: format)
            } else {
                audioEngine.connect(audioFilePlayer, to:audioEngine.mainMixerNode, format: nil)
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
                audioFile = try AVAudioFile(forReading: wavURL)
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
        //audioEngine.connect(audioFilePlayer, to:audioEngine.outputNode, format: nil)
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
        
        guard let audioFile = audioFile else {
            print("no audio file selected")
            return
        }
        
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
        
        if canPlay {
            audioFilePlayer.scheduleFile(audioFile, at: nil, completionHandler: nil)
            audioFilePlayer.play()
        }
        
    }
    
    func stop() {
        audioFilePlayer.stop()
    }
    
    func render(_ outputURL:URL,_ offset:AVAudioFrameCount = 0,_ writeFile:Bool = true) -> Bool {
 
        let bufLen:AVAudioFrameCount = 512
        let sampleRate:Double = 48000.0
        let channels:AVAudioChannelCount = 2
        
        let tailPadInSeconds:TimeInterval = 10.0
        let tailPadInFrames = UInt32(round(sampleRate*tailPadInSeconds))

        guard canPlay else {
            print("Not ready to render: No midi file")
            return false
        }
        
        guard let audioFile = audioFile else {
            print("No audio file!")
            return false
        }
        
        audioFilePlayer.stop()
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
            audioEngine.reset()
            try audioEngine.enableManualRenderingMode(AVAudioEngineManualRenderingMode.offline, format: format, maximumFrameCount: bufLen)
        } catch {
            print("###Error: enableManualRenderingMode failed")
            return false
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("###Error: could not start engine")
            return false
        }
        
        let lengthInFrames   = UInt32(audioFile.length)
        let shiftInFrames    = UInt32(0)

        audioFilePlayer.scheduleFile(audioFile, at: nil, completionHandler: nil)
        audioFilePlayer.play()

        let header=create48k32bitFloatWavHeader(lengthInFrames+tailPadInFrames)
        
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

        let totalOffset = offset+shiftInFrames
        var remainingOffset = totalOffset
        
        while(audioEngine.manualRenderingSampleTime+Int64(bufLen)<totalOffset) {
            //Skipping buffers at beginning if offset is larger than buffer size
            print("preflight:\(audioEngine.manualRenderingSampleTime)")
            do {
                let status = try audioEngine.renderOffline(AVAudioFrameCount(bufLen), to: buffer)
                print("Rendering status=\(status)")
            } catch {
                print("###Error: renderOffline failed")
                return false
            }
            remainingOffset -= bufLen
        }

        while(audioEngine.manualRenderingSampleTime<lengthInFrames+totalOffset+tailPadInFrames) {
            let framesToRead = UInt32(min(Int64(lengthInFrames+totalOffset+tailPadInFrames)-audioEngine.manualRenderingSampleTime,Int64(bufLen)))
            
            do {
                let status = try audioEngine.renderOffline(AVAudioFrameCount(framesToRead), to: buffer)
                switch status {
                case .success:
                    break
                case .error:
                    print("error")
                case .insufficientDataFromInputNode:
                    print("insuff")
                case .cannotDoInCurrentContext:
                    print("cannot")
                @unknown default:
                    print("unknown")
                }
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
            
            if writeFile {
                fileHandle!.write(Data(buffer: c))
            }

        }

        audioFilePlayer.auAudioUnit.deallocateRenderResources()
        audioEngine.disableManualRenderingMode()
        
        if writeFile {
            fileHandle!.closeFile()
        }
        audioFilePlayer.stop()

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
