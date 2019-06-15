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
        //print("applicationDidFinishLaunching")
        
        /*
        guard let vc = ViewController.vc else {
            print("no viewcontroller")
            return
        }
        //vc._changePlugin("Crystal")
        vc._changePlugin("/Users/gislim/Documents/Verkefni/Code/raunder/Kontakt_ragtime3.plist")
        vc._renderMidi()
        NSApplication.shared.terminate(0)
        */
        
        if let rindex = CommandLine.arguments.firstIndex(of: "render") {
            runFromCommandLine(rindex)
        }

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func runFromCommandLine(_ renderIndex: Int) {
        
        guard CommandLine.argc >= renderIndex + 5 else {
            failed("Arguments missing")
            return
        }
        print(FileManager.default.currentDirectoryPath)
        
        let midiFile = CommandLine.arguments[renderIndex+1]
        let plugin = CommandLine.arguments[renderIndex+2]
        let presetFile = CommandLine.arguments[renderIndex+3]
        let wavFile = CommandLine.arguments[renderIndex+4]
        //Will want samplerate and bitdepth too
        guard let vc = ViewController.vc else {
            print("###Bug: have not viewController")
            NSApplication.shared.terminate(0)
            return
        }
        //print(FileManager.default.currentDirectoryPath)
        let midiURL = URL(fileURLWithPath: midiFile)
        let presetURL = URL(fileURLWithPath: presetFile)
        let wavURL = URL(fileURLWithPath: wavFile)
        //print(inURL)
        vc._changePlugin(plugin)
        vc._selectMidi(midiURL)
        vc._selectPreset(presetURL)
        vc._renderMidi(wavURL)
        //print(CommandLine.argc)
        NSApplication.shared.terminate(0)
    }
    
    func failed(_ message:String) {
        print("###Error: \(message)")
        NSApplication.shared.terminate(1)
    }


}

