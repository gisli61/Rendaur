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
