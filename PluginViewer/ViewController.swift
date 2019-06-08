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
    
    let windowPrefix = "FX"
    var currentInstrument:AUAudioUnit?
    var currentAVInstrument:AVAudioUnit?
    private var midiFilePlayer:MidiFilePlayer?
    private var testWindowController: NSWindowController?

    //MARK: Properties
    @IBOutlet weak var pluginPopup: NSPopUpButton!
    //@IBOutlet weak var openPluginButton: NSButton!
    @IBOutlet weak var playMidiButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    
    //MARK: Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        midiFilePlayer = MidiFilePlayer()
        
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
        guard let instrument = getAVAudioUnitMIDIInstrument(pluginName) else {
            print("Could not load \(pluginName)")
            return
        }
        print("Loaded \(instrument.name)")
        currentAVInstrument = instrument
        currentInstrument = instrument.auAudioUnit
        
        guard let current = currentInstrument else {
            print("No plugin selected!")
            return
        }

    }
    
    @IBAction func playMidi(_ sender:NSButton) {
        guard let midiFilePlayer = midiFilePlayer else {
            print("No midi player!")
            return
        }
        //midiFilePlayer.instrument = "AUMIDISynth"
        midiFilePlayer.instrument = "AUMIDISynth"
        midiFilePlayer.midiFile   = "/Users/gislim/Documents/Verkefni/Code/raunder/out.mid"
        midiFilePlayer.play()
    }
    
    @IBAction func stop(_ sender:NSButton) {
        guard let midiFilePlayer = midiFilePlayer else {
            print("No midi player!")
            return
        }
        midiFilePlayer.stop()
    }
    
    @IBAction func openAUWindow(_ sender: NSButton) {
        guard let current = currentInstrument else {
            print("No plugin selected!")
            return
        }

        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let auWindowController = storyboard.instantiateController(withIdentifier: "AU Window Controller") as! NSWindowController
        
        guard let auName = current.audioUnitName else {
            print("Found no name!")
            return
        }
        
        guard let auWindow = auWindowController.window else {
            print("No window!")
            return
        }
        
        auWindow.title=auName
        auWindow.delegate=self
        
        
        current.requestViewController() { [weak self] nsViewController in
            guard let vc = nsViewController else {
                print("viewController is nil")
                return
            }
            print("have a view controller")
            auWindowController.contentViewController = vc
            print("Did the completion")
        }
        
        auWindowController.showWindow(nil)
    }

}

extension ViewController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
    }

}
