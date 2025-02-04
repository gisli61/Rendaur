//
//  PluginManager.swift
//  Rendaur
//
//  Created by Gísli Másson on 29/05/2019.
//  Copyright © 2019 Gísli Másson. All rights reserved.
//

import Foundation
import AVFoundation

func listInstruments() -> [String] {
    var instruments:[String] = []
    
    let anyAudioUnitDescription = AudioComponentDescription(componentType:kAudioUnitType_MusicDevice,
                                                            componentSubType: 0,
                                                            componentManufacturer: 0,
                                                            componentFlags: 0,
                                                            componentFlagsMask: 0)
    
    let units = AVAudioUnitComponentManager.shared().components(matching: anyAudioUnitDescription)
    
    for x in units {
        instruments.append(x.name)
    }

    return instruments
}

func listEffects() -> [String] {
    var effects:[String] = []
    
    let effectAudioUnitDescription = AudioComponentDescription(componentType:kAudioUnitType_Effect,
                                                               componentSubType: 0,
                                                               componentManufacturer: 0,
                                                               componentFlags: 0,
                                                               componentFlagsMask: 0)
    
    let units = AVAudioUnitComponentManager.shared().components(matching: effectAudioUnitDescription)
    for x in units {
        effects.append(x.name)
    }

    return effects
}

func listPresets() -> [String] {
    /*
    return ["/Users/gislim/Documents/Verkefni/Code/raunder/Kontakt_ragtime3.plist",
            "/Users/gislim/Documents/Verkefni/Code/raunder/raunder/Kontakt_epiano.plist",
            "/Users/gislim/Documents/Verkefni/Code/raunder/Crystal_1.plist"
    ]
    */
    return []
}

func pluginInfo(_ midiInstrument: AVAudioUnitMIDIInstrument) {
    guard let parameterTree = midiInstrument.auAudioUnit.parameterTree else {
        print("No parameter tree found")
        return
    }
    //print("displayName: \(parameterTree.displayName)")
    
    for p in parameterTree.allParameters {
        print("\(p.displayName) : \(p.value)")
    }
}

func getPluginInfo(_ midiInstrument: AVAudioUnitMIDIInstrument) -> String {
    guard let parameterTree = midiInstrument.auAudioUnit.parameterTree else {
        return "No parameter tree found"
    }
    
    var reply:String=""
    var sep:String=""
    for p in parameterTree.allParameters {
        reply.append(sep)
        sep="\n"
        reply.append(p.keyPath)
        reply.append(":")
        reply.append(p.displayName)
        reply.append("=")
        reply.append(String(p.value))
    }
    return reply
}

func getEffectInfo(_ effect: AVAudioUnitEffect) -> String {
    guard let parameterTree = effect.auAudioUnit.parameterTree else {
        return "No parameter tree found"
    }
    
    var reply:String=""
    var sep:String=""
    for p in parameterTree.allParameters {
        reply.append(sep)
        sep="\n"
        reply.append(p.keyPath)
        reply.append(":")
        reply.append(p.displayName)
        reply.append("=")
        reply.append(String(p.value))
    }
    return reply
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

func readState(_ plistURL:URL) -> [String:Any]? {
    var propertyListFormat =  PropertyListSerialization.PropertyListFormat.xml //Format of the Property List.
    //let plistURL = URL(fileURLWithPath: plistFile)
    var xmlData:Data
    
    do {
        xmlData = try Data(contentsOf: plistURL)
    } catch {
        print("###Error: \(plistURL.path): Could not read file")
        return nil
    }
    
    do {
        let plistData = try PropertyListSerialization.propertyList(from: xmlData, options: .mutableContainersAndLeaves, format: &propertyListFormat)
        let state = plistData as! Dictionary<String,Any>
        return state
    } catch {
        print("###Error: \(plistURL.path): Could not parse file. Is this a plist?")
        return nil
    }
    
}

func writePreset(_ midiInstrument: AVAudioUnitMIDIInstrument,_ presetFile:URL) -> Bool {
    guard let currentState = midiInstrument.auAudioUnit.fullStateForDocument else {
        print("instrument has no state defined")
        return false
    }
    do {
        let data = try PropertyListSerialization.data(fromPropertyList: currentState, format: PropertyListSerialization.PropertyListFormat.xml, options: 0)
        try data.write(to: presetFile, options: .atomic)
    } catch (let err){
        print(err.localizedDescription)
        return false
    }
    return true
}

func writeEffectPreset(_ effect: AVAudioUnitEffect,_ presetFile:URL) -> Bool {
    guard let currentState = effect.auAudioUnit.fullStateForDocument else {
        print("instrument has no state defined")
        return false
    }
    do {
        let data = try PropertyListSerialization.data(fromPropertyList: currentState, format: PropertyListSerialization.PropertyListFormat.xml, options: 0)
        try data.write(to: presetFile, options: .atomic)
    } catch (let err){
        print(err.localizedDescription)
        return false
    }
    return true
}


func loadPreset(_ midiInstrument: AVAudioUnitMIDIInstrument,_ presetFile: URL) -> Bool {
    guard let state = readState(presetFile) else {
        print("###Error: Could not read the state")
        return false
    }
    
    guard let _ = midiInstrument.auAudioUnit.fullStateForDocument else {
        print("instument has no state defined")
        return false
    }
    
    /*
    if let val = oldState["manufacturer"] {
        guard let ival = val as? Int else {
            print("could not read manufacturer")
            return false
        }
        print("Manufacturer :\(ival)")
    }
    if let val = oldState["type"] {
        print("Type :\(val)")
    }
    if let val = oldState["subtype"] {
        print("Subtype :\(val)")
    }
    */
    //TODO: make sure manufacturer, type and subtype match
    midiInstrument.auAudioUnit.fullStateForDocument = state
    return true
}

func loadEffectPreset(_ effect: AVAudioUnitEffect,_ presetFile: URL) -> Bool {
    guard let state = readState(presetFile) else {
        print("###Error: Could not read the state")
        return false
    }
    
    guard let _ = effect.auAudioUnit.fullStateForDocument else {
        print("effect has no state defined")
        return false
    }
    
    /*
    if let val = oldState["manufacturer"] {
        guard let ival = val as? Int else {
            print("could not read manufacturer")
            return false
        }
        print("Manufacturer :\(ival)")
    }
    if let val = oldState["type"] {
        print("Type :\(val)")
    }
    if let val = oldState["subtype"] {
        print("Subtype :\(val)")
    }
    */
    //TODO: make sure manufacturer, type and subtype match
    effect.auAudioUnit.fullStateForDocument = state
    return true
}

func getAVAudioUnitMIDIInstrument(_ name:String) -> AVAudioUnitMIDIInstrument? {
    let plugin:String
    
    let state:[String:Any]? = nil
    //let state = readState(name)
    
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
    
    guard let description = getAudioComponentDescription(name:plugin) else {
        print("###Error: Could not get \(plugin) description")
        return nil
    }
    
    let midiInstrument = AVAudioUnitMIDIInstrument(audioComponentDescription: description)
    
    if state != nil {
        midiInstrument.auAudioUnit.fullStateForDocument = state
    }
    
    return midiInstrument
}

func getAVAudioUnitEffect(_ name:String) -> AVAudioUnitEffect? {
    let plugin:String
    
    let state:[String:Any]? = nil
    //let state = readState(name)
    
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
    
    guard let description = getAudioComponentDescription(name:plugin) else {
        print("###Error: Could not get \(plugin) description")
        return nil
    }
    
    let effect = AVAudioUnitEffect(audioComponentDescription: description)
    
    if state != nil {
        effect.auAudioUnit.fullStateForDocument = state
    }
    
    return effect
}
