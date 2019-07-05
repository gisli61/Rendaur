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

        for instrumentName in listInstruments() {
            reply.append(contentsOf: instrumentName)
            reply.append(contentsOf: ",")
        }

        return reply
    }
}

class LoadPluginScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let vc = ViewController.vc else {
            return false
        }
        let pluginName = self.directParameter as! String
        
        //FIXME: change isn't reflected in popupButton
        let success = vc._changePlugin(pluginName)
        return success
    }
}

class LoadPresetScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let vc = ViewController.vc else {
            return false
        }
        
        if vc.currentInstrument == nil {
            print("no plugin loaded")
            return false
        }
        
        //CHECK: Cannot use ~ in pathname.
        let presetFile = self.directParameter as! URL
        let success = vc._selectPreset(presetFile)
        return success
    }
}

class LoadMidiScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let vc = ViewController.vc else {
            return false
        }

        //CHECK: Cannot use ~ in pathname.
        let midiFile = self.directParameter as! URL
        if !midiFile.isFileURL {
            return false
        }
        vc._selectMidi(midiFile)
        return true
    }
}

class RenderScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let vc = ViewController.vc else {
            return false
        }
        
        guard let arguments = self.evaluatedArguments else {
            return false
        }
        
        guard let wavFile = arguments["WavFilePath"] as? URL else {
            return false
        }
        
        if !wavFile.isFileURL {
            return false
        }

        let offset = arguments["Offset"] as? UInt32
        
        var success:Bool = false
        if let offset = offset {
            print("Got offset \(offset)")
            success = vc._renderMidi(wavFile, offset)
        } else {
            success = vc._renderMidi(wavFile)
        }
        
        return success
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
