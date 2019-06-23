//
//  AppDelegate.swift
//  PluginViewer
//
//  Created by Gísli Másson on 29/05/2019.
//  Copyright © 2019 Gísli Másson. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        if let rindex = CommandLine.arguments.firstIndex(of: "render") {
            renderMidi(rindex)
        } else if let lindex = CommandLine.arguments.firstIndex(of: "list") {
            listPlugins(lindex)
        }

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func listPlugins(_ listIndex: Int) {
        for instrumentName in listInstruments() {
            print(instrumentName)
        }
        NSApplication.shared.terminate(0)
    }
    
    func renderMidi(_ renderIndex: Int) {
        
        guard CommandLine.argc >= renderIndex + 5 else {
            failed("Arguments missing")
            return
        }
        
        let midiFile = CommandLine.arguments[renderIndex+1]
        let plugin = CommandLine.arguments[renderIndex+2]
        let presetFile = CommandLine.arguments[renderIndex+3]
        let wavFile = CommandLine.arguments[renderIndex+4]
        
        let offset:UInt32
        if CommandLine.argc >= renderIndex + 6 {
            guard let tmpOffset = UInt32(CommandLine.arguments[renderIndex+5]) else {
                failed("Invalid offset")
                return
            }
            offset = tmpOffset
        } else {
            offset = 0
        }
        
        //Will want samplerate and bitdepth too
        guard let vc = ViewController.vc else {
            failed("Bug: Have no viewController")
            return
        }
        //print(FileManager.default.currentDirectoryPath)
        let midiURL = URL(fileURLWithPath: midiFile)
        let presetURL = URL(fileURLWithPath: presetFile)
        let wavURL = URL(fileURLWithPath: wavFile)
        
        if !vc._changePlugin(plugin) {
            failed("Could not load plugin")
        }
        
        vc._selectMidi(midiURL)
        
        if !vc._selectPreset(presetURL) {
            failed("Could not load preset")
        }

        if !vc._renderMidi(wavURL,offset) {
            failed("Rendering failed")
        }
        NSApplication.shared.terminate(0)
    }
    
    func failed(_ message:String) {
        print("###Error: \(message)")
        NSApplication.shared.terminate(0)
    }


}

