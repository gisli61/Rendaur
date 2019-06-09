//
//  PluginManager.swift
//  PluginViewer
//
//  Created by Gísli Másson on 29/05/2019.
//  Copyright © 2019 Gísli Másson. All rights reserved.
//

import Foundation
import AVFoundation

func listInstruments() -> [String] {
    var instruments:[String] = []
    
    let anyAudioUnitDescription = AudioComponentDescription()
    
    let units = AVAudioUnitComponentManager.shared().components(matching: anyAudioUnitDescription)
    
    for x in units {
        //if x.hasMIDIInput && x.hasCustomView {
        //    instruments.append(x.name)
        //}
        if x.hasMIDIInput {
            instruments.append(x.name)
        }
    }

    return instruments
}

func getInstrument(_ name: String) -> AVAudioUnitComponent? {
    let anyAudioUnitDescription = AudioComponentDescription()
    let componentManager = AVAudioUnitComponentManager.shared()
    let units = componentManager.components(matching: anyAudioUnitDescription)

    for x in units {
        if x.name == name {
            return x
        }
    }
    return nil
}

func getAudioComponentDescription(name: String) -> AudioComponentDescription? {
    let anyAudioUnitDescription = AudioComponentDescription()
    let units = AVAudioUnitComponentManager.shared().components(matching: anyAudioUnitDescription)
    for x in units {
        if x.name == name {
            return x.audioComponentDescription
        }
    }
    return nil
}

/*
func getAVAudioUnit(_ name:String) -> AVAudioUnit? {
    var a:AVAudioUnit?
    
    guard let desc = getAudioComponentDescription(name:name) else {
        print("###Error: Could not get \(name) description")
        return nil
    }
    
    let flags = AudioComponentFlags(rawValue: desc.componentFlags)
    let canLoadInProcess = flags.contains(AudioComponentFlags.canLoadInProcess)
    print("Can load in process: \(canLoadInProcess)")
    let loadOptions: AudioComponentInstantiationOptions = canLoadInProcess ? .loadInProcess : .loadOutOfProcess
    
    AVAudioUnit.instantiate(with: desc, options: loadOptions) {  avAudioUnit, error in
        if error != nil {
            print("###Error: \(String(describing: error)): getAVAudioUnit")
            a = avAudioUnit
        } else {
            a = avAudioUnit
        }
        
    }
    return a
}
*/

func readState(_ plistFile:String) -> [String:Any]? {
    var propertyListFormat =  PropertyListSerialization.PropertyListFormat.xml //Format of the Property List.
    let plistURL = URL(fileURLWithPath: plistFile)
    var xmlData:Data
    
    do {
        xmlData = try Data(contentsOf: plistURL)
    } catch {
        //print("###Warning: \(plistFile): Could not read file")
        return nil
    }
    
    do {
        let plistData = try PropertyListSerialization.propertyList(from: xmlData, options: .mutableContainersAndLeaves, format: &propertyListFormat)
        let state = plistData as! Dictionary<String,Any>
        return state
    } catch {
        print("###Error: \(plistFile): Could not parse file. Is this a plist?")
        return nil
    }
    
}

func getAVAudioUnitMIDIInstrument(_ name:String) -> AVAudioUnitMIDIInstrument? {
    let plugin:String
    
    let state = readState(name)
    
    if state != nil {
        //pluginName = String(plugin.split(separator:"_")[0])
        guard let fileName = name.split(separator:"/").last else {
            print("###:Error: Could not figure out filename")
            return nil
        }
        plugin = String(fileName.split(separator:"_")[0])
    } else {
        plugin = name
    }
    
    guard let synth1 = getAudioComponentDescription(name:plugin) else {
        print("###Error: Could not get \(plugin) description")
        return nil
    }
    
    let midiInstrument = AVAudioUnitMIDIInstrument(audioComponentDescription: synth1)
    
    if state != nil {
        midiInstrument.auAudioUnit.fullStateForDocument = state
    }
    
    return midiInstrument
}

func play(midiFile:String, plugin:String="AUMIDISynth") {
    
    guard let midiInstrument = getAVAudioUnitMIDIInstrument(plugin) else {
        print("###Error: Could not get \(plugin)")
        return
    }
    
    let audioEngine = AVAudioEngine()
    
    audioEngine.attach(midiInstrument)
    audioEngine.connect(midiInstrument, to: audioEngine.mainMixerNode, format: nil)
    audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: nil)
        
    do {
        try audioEngine.start()
    } catch {
        print("###Error: could not start engine")
        return
    }
    
    let sequencer = AVAudioSequencer(audioEngine: audioEngine)
    
    print(midiFile)
    
    let fileURL = URL(fileURLWithPath: midiFile)
    
    print(fileURL.absoluteString)
    
    do {
        try sequencer.load(from: fileURL, options: .smfChannelsToTracks)
    } catch {
        print("###Error: Failed to load midi sequence")
        return
    }
    
    var lengthInSeconds:TimeInterval = 0
    for t in sequencer.tracks {
        if t.lengthInSeconds > lengthInSeconds {
            lengthInSeconds = t.lengthInSeconds
        }
    }
    
    if lengthInSeconds > 60.0 {
        print("Midi file is \(lengthInSeconds) seconds. Will not play")
        return
    }
    
    sequencer.prepareToPlay()
    
    do {
        try sequencer.start()
    } catch {
        print("###Error: Failed to start sequencer")
        return
    }
    
    print("playing")
    sleep(UInt32(lengthInSeconds+0.5))
    
}
