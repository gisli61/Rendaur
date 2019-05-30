//
//  ViewController.swift
//  PluginViewer
//
//  Created by Gísli Másson on 29/05/2019.
//  Copyright © 2019 Gísli Másson. All rights reserved.
//

import Cocoa
import AVFoundation
import CoreAudioKit

class ViewController: NSViewController {
    
    var currentInstrument:AUAudioUnit?
    private var myWindowController: NSWindowController? // Temporary store

    //MARK: Properties
    @IBOutlet weak var pluginPopup: NSPopUpButton!
    @IBOutlet weak var openPluginButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        pluginPopup.addItem(withTitle: "Select instrument...")
        for x in listInstruments() {
            pluginPopup.addItem(withTitle: x)
        }

    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    //MARK: Actions
    @IBAction func changePlugin(_ sender: NSPopUpButton) {
        guard let pluginName = sender.titleOfSelectedItem else {
            print("Could not pick item")
            return
        }
        guard let instrument = getAVAudioUnit(pluginName) else {
            print("Could not load \(pluginName)")
            return
        }
        print("Loaded \(instrument.name)")
        currentInstrument = instrument.auAudioUnit
        
        guard let current = currentInstrument else {
            print("No plugin selected!")
            return
        }
        
        current.requestViewController() { [weak self] in
            guard let vc = $0 else {
                print("viewController is nil")
                return
            }
            print("have a view controller")
            let wc = MyWindowController()
            wc.contentViewController = vc
            wc.showWindow(nil)
        }

    }
    
    @IBAction func openPluginWindow(_ sender:NSButton) {
        guard let current = currentInstrument else {
            print("No plugin selected!")
            return
        }
        
        current.requestViewController() { nsViewController in
            //guard let vc = nsViewController else {
            //    print("viewController is nil")
            //    return
            //}
            print("have a view controller")
            let wc = MyWindowController()
            //wc.showWindow(nil)
            self.myWindowController = wc
            self.myWindowController!.showWindow(nil)
            print("Got here")
        }

    }
    
}

