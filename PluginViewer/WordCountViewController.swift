//
//  WordCountViewController.swift
//  PluginViewer
//
//  Created by Gísli Másson on 07/06/2019.
//  Copyright © 2019 Gísli Másson. All rights reserved.
//

import Cocoa

class WordCountViewController: NSViewController {
    
    dynamic var wordCount = "aa"
    dynamic var paragraphCount = "b"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func dismissWordCountWindow(_ sender: NSButton) {
        let application = NSApplication.shared
        application.stopModal()
    }
}
