//
//  ScriptingClasses.swift
//  Rendaur
//
//  Created by Gísli Másson on 03/07/2019.
//  Copyright © 2019 Gísli Másson. All rights reserved.
//

import Foundation

// The following command works now
//   tell application "Rendaur" to list in "blah"
//

//Look at https://stackoverflow.com/questions/37194835/making-cocoa-application-scriptable-swift
//and the zip file provided in the answer

//See also tutorial at raywenderlich (doesn't quite work)

//See dev docs: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ScriptableCocoaApplications/SApps_design_apps/SAppsDesignApp.html

//Info on sdef:
// https://www.shadowlab.org/softwares/SdefEditor/sdef-format.html#DirectParameter

// The standard suite can be found in
// /System/Library/ScriptingDefinitions/CocoaStandard.sdef

class ListScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        var reply = ""
        
        var sep = ""
        for instrumentName in listInstruments() {
            reply.append(sep)
            sep = ","
            reply.append(contentsOf: instrumentName)
        }

        return reply
    }
}

class ListEffectsScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        var reply = ""
        
        var sep = ""
        for effectName in listEffects() {
            reply.append(sep)
            sep = ","
            reply.append(contentsOf: effectName)
        }
        
        return reply
    }
}

class LoadPluginScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let vc = ViewController.vc else {
            scriptErrorString = "Application not ready"
            scriptErrorNumber = 1001
            return nil
        }
        let pluginName = self.directParameter as! String
        
        //FIXME: change isn't reflected in popupButton
        let success = vc._changePlugin(pluginName)
        return success
    }
}

class LoadEffectScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let vc = ViewController.vc else {
            scriptErrorString = "Application not ready"
            scriptErrorNumber = 1001
            return nil
        }
        let effectName = self.directParameter as! String
        
        //FIXME: change isn't reflected in popupButton
        let success = vc._changeEffect(effectName)
        return success
    }
}

class LoadPresetScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let vc = ViewController.vc else {
            scriptErrorString = "Application not ready"
            scriptErrorNumber = 1001
            return nil
        }
        
        if vc.currentInstrument == nil {
            scriptErrorString = "No plugin loaded"
            scriptErrorNumber = 1003
            return nil
        }
        
        //CHECK: Cannot use ~ in pathname.
        
        guard let presetFile = self.directParameter as? URL else {
            scriptErrorString = "Could not preset path parameter"
            scriptErrorNumber = 1004
            return nil
        }
        let success = vc._selectPreset(presetFile)
        if !success {
            scriptErrorString = "Could not load preset. Has plugin been loaded?"
            scriptErrorNumber = 1005
            return nil
        }
        return nil
    }
}

class LoadEffectPresetScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let vc = ViewController.vc else {
            scriptErrorString = "Application not ready"
            scriptErrorNumber = 1001
            return nil
        }
        
        if vc.currentEffect == nil {
            scriptErrorString = "No effect loaded"
            scriptErrorNumber = 1003
            return nil
        }
        
        //CHECK: Cannot use ~ in pathname.
        
        guard let presetFile = self.directParameter as? URL else {
            scriptErrorString = "Could not preset path parameter"
            scriptErrorNumber = 1004
            return nil
        }
        let success = vc._selectEffectPreset(presetFile)
        if !success {
            scriptErrorString = "Could not load preset. Has effect been loaded?"
            scriptErrorNumber = 1005
            return nil
        }
        return nil
    }
}

class LoadMidiScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let vc = ViewController.vc else {
            scriptErrorString = "Application not ready"
            scriptErrorNumber = 1001
            return nil
        }

        //CHECK: Cannot use ~ in pathname.
        guard let midiFile = self.directParameter as? URL else {
            scriptErrorString = "Could not read midi path parameter"
            scriptErrorNumber = 1006
            return nil
        }
        
        //Should double check if file loads properly
        vc._selectMidi(midiFile)
        return nil
    }
}

class LoadWavScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let vc = ViewController.vc else {
            scriptErrorString = "Application not ready"
            scriptErrorNumber = 1001
            return nil
        }

        //CHECK: Cannot use ~ in pathname.
        guard let wavFile = self.directParameter as? URL else {
            scriptErrorString = "Could not read wav path parameter"
            scriptErrorNumber = 1006
            return nil
        }
        
        //Should double check if file loads properly
        vc._selectWav(wavFile)
        return nil
    }
}

class RenderScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let vc = ViewController.vc else {
            scriptErrorString = "Application not ready"
            scriptErrorNumber = 1001
            return nil
        }
        
        guard let arguments = self.evaluatedArguments else {
            scriptErrorString = "Unknown error. Got no arguments"
            scriptErrorNumber = 1007
            return nil
        }
        
        guard let wavFile = arguments["WavFilePath"] as? URL else {
            scriptErrorString = "Could not wav file path parameter"
            scriptErrorNumber = 1008
            return nil
        }

        let offset = arguments["Offset"] as? UInt32
        
        var success:Bool = false
        
        if let offset = offset {
            //print("Got offset \(offset)")
            success = vc._renderMidi(wavFile, offset)
        } else {
            success = vc._renderMidi(wavFile)
        }
        
        if !success {
            scriptErrorString = "Unknown error. Rendering failed"
            scriptErrorNumber = 1009
            return nil
        }
        return nil
    }
}

class RenderEffectScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let vc = ViewController.vc else {
            scriptErrorString = "Application not ready"
            scriptErrorNumber = 1001
            return nil
        }
        
        guard let arguments = self.evaluatedArguments else {
            scriptErrorString = "Unknown error. Got no arguments"
            scriptErrorNumber = 1007
            return nil
        }
        
        guard let wavFile = arguments["WavFilePath"] as? URL else {
            scriptErrorString = "Could not wav file path parameter"
            scriptErrorNumber = 1008
            return nil
        }

        let offset = arguments["Offset"] as? UInt32
        
        var success:Bool = false
        
        if let offset = offset {
            //print("Got offset \(offset)")
            success = vc._renderWav(wavFile, offset)
        } else {
            success = vc._renderWav(wavFile)
        }
        
        if !success {
            scriptErrorString = "Unknown error. Rendering failed"
            scriptErrorNumber = 1009
            return nil
        }
        return nil
    }
}

class InfoScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let vc = ViewController.vc else {
            scriptErrorString = "Application not ready"
            scriptErrorNumber = 1001
            return nil
        }
        
        guard let instrument = vc.currentInstrument else {
            scriptErrorString = "No plugin selected. Cannot get info"
            scriptErrorNumber = 1002
            return nil
        }

        return getPluginInfo(instrument)
    }
}

class EffectInfoScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let vc = ViewController.vc else {
            scriptErrorString = "Application not ready"
            scriptErrorNumber = 1001
            return nil
        }
        
        guard let effect = vc.currentEffect else {
            scriptErrorString = "No plugin selected. Cannot get info"
            scriptErrorNumber = 1002
            return nil
        }

        return getEffectInfo(effect)
    }
}

/*
 
 Objects in application:
 plugins, presets, midi files
 
 Commands
   get all plugins
   set current plugin to "Kontakt"
   set preset to ...
   set midi to ...
   make wav file at "
 
   render midi file 1 with plugin 2 using preset 3
 
 */
