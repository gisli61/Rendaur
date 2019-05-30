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
        if x.hasCustomView {
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

func getAVAudioUnit(_ name:String) -> AVAudioUnit? {
    var a:AVAudioUnit?
    
    guard let desc = getAudioComponentDescription(name:name) else {
        print("###Error: Could not get \(name) description")
        return nil
    }
    
    AVAudioUnit.instantiate(with: desc, options: AudioComponentInstantiationOptions.loadInProcess) { avAudioUnit, error in
        if error != nil {
            print("###Error: \(String(describing: error)): getAVAudioUnit")
            a = nil
        } else {
            a = avAudioUnit
        }
    }
    return a
}

