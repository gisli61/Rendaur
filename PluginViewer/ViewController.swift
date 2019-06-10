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
    
    static var vc:ViewController?
    
    //MARK: Properties
    var currentInstrument:AVAudioUnitMIDIInstrument?
    private var midiFilePlayer:MidiFilePlayer?
    private var testWindowController: NSWindowController?

    //MARK: Outlets
    @IBOutlet weak var pluginPopup: NSPopUpButton!
    @IBOutlet weak var playMidiButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    
    //MARK: Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        midiFilePlayer = MidiFilePlayer()
        
        // Do any additional setup after loading the view.
        pluginPopup.addItem(withTitle: "Select instrument...")
        for x in listInstruments() {
            pluginPopup.addItem(withTitle: x)
        }
        for x in listPresets() {
            pluginPopup.addItem(withTitle: x)
        }
        ViewController.vc = self
    }
    
    //MARK: Functions
    func _changePlugin(_ pluginName:String) {
        guard let instrument = getAVAudioUnitMIDIInstrument(pluginName) else {
            print("Could not load \(pluginName)")
            return
        }
        print("Loaded \(instrument.name)")
        currentInstrument = instrument
        
        guard let midiFilePlayer = midiFilePlayer else {
            print("No midi file player!! Something serious happened")
            return
        }
        
        midiFilePlayer.midiInstrument = currentInstrument
    }
    
    func _renderMidi() {
        guard let midiFilePlayer = midiFilePlayer else {
            print("No midi player!")
            return
        }
        guard currentInstrument != nil else {
            print("No plugin selected")
            return
        }
        midiFilePlayer.midiFile = "/Users/gislim/Documents/Verkefni/Code/raunder/out.mid"
        midiFilePlayer.wavFile  = "/Users/gislim/Documents/Verkefni/Code/raunder/out.wav"
        midiFilePlayer.render()
    }

    //MARK: Actions
    @IBAction func changePlugin(_ sender: NSPopUpButton) {
        guard let pluginName = sender.titleOfSelectedItem else {
            print("Could not pick item")
            return
        }
        self._changePlugin(pluginName)
    }
    
    @IBAction func playMidi(_ sender:NSButton) {
        guard let midiFilePlayer = midiFilePlayer else {
            print("No midi player!")
            return
        }
        guard currentInstrument != nil else {
            print("No plugin selected")
            return
        }
        //midiFilePlayer.midiInstrument = instrument
        midiFilePlayer.midiFile   = "/Users/gislim/Documents/Verkefni/Code/raunder/out.mid"
        midiFilePlayer.play()
    }
    
    @IBAction func renderMidi(_ sender:NSButton) {
        self._renderMidi()
    }
    
    @IBAction func stop(_ sender:NSButton) {
        guard let midiFilePlayer = midiFilePlayer else {
            print("No midi player!")
            return
        }
        midiFilePlayer.stop()
    }
    
    @IBAction func openPluginWindow(_ sender: NSButton) {
        
        guard let current = currentInstrument else {
            print("no plugin selected!")
            return
        }

        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let auWindowController = storyboard.instantiateController(withIdentifier: "AU Window Controller") as! NSWindowController
        
        guard let auName = current.auAudioUnit.audioUnitName else {
            print("Found no name!")
            return
        }
        
        guard let auWindow = auWindowController.window else {
            print("No window!")
            return
        }
        
        auWindow.title=auName
        auWindow.delegate=self
        
        current.auAudioUnit.requestViewController() { [weak self] nsViewController in
            guard let vc = nsViewController else {
                print("viewController is nil")
                return
            }

            auWindowController.contentViewController = vc

        }
        
        auWindowController.showWindow(nil)
    }

}

extension ViewController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
    }

}
