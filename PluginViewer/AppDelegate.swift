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
        
        guard CommandLine.argc >= renderIndex + 4 else {
            failed("Arguments missing")
            return
        }
        print(FileManager.default.currentDirectoryPath)
        
        let inFile = CommandLine.arguments[renderIndex+1]
        let plugin = CommandLine.arguments[renderIndex+2]
        let outFile = CommandLine.arguments[renderIndex+3]
        //Will want samplerate and bitdepth too
        
        //print(CommandLine.argc)
        NSApplication.shared.terminate(0)
    }
    
    func failed(_ message:String) {
        print("###Error: \(message)")
        NSApplication.shared.terminate(1)
    }


}

