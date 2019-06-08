//
//  AudioUnitWindow.swift
//  PluginViewer
//
//  Created by Gísli Másson on 06/06/2019.
//  Copyright © 2019 Gísli Másson. All rights reserved.
//

import AVFoundation
import Cocoa

class AudioUnitWindow:NSWindowController {
    
    /*
    override var windowNibName: String? {
        return "AudioUnitWindow" // no extension .xib here
    }
    */
    
    convenience init() {
        self.init(windowNibName: "AudioUnitWindow")
    }
    
    /*
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    */
    
    override func windowDidLoad() {
        super.windowDidLoad()
        print("Window did load")
        guard let w = self.window else {
            print("Got no window!")
            return
        }
    }
    
    @IBAction func buttonPushed(_ sender: NSButton) {
        print("pushed button")
    }
    
}
