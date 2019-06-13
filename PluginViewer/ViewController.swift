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
    var currentMidiURL:URL?
    var currentPresetURL:URL?
    private var midiFilePlayer:MidiFilePlayer?
    //private var testWindowController: NSWindowController?

    //MARK: Outlets
    @IBOutlet weak var pluginPopup: NSPopUpButton!
    @IBOutlet weak var playMidiButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var midiField: NSTextField!
    @IBOutlet weak var presetField: NSTextField!
    
    //MARK: Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        //print("viewDidLoad")
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
        currentPresetURL = nil
        presetField.stringValue = ""
        
        guard let midiFilePlayer = midiFilePlayer else {
            print("No midi file player!! Something serious happened")
            return
        }
        
        midiFilePlayer.midiInstrument = currentInstrument
        
    }
    
    func _renderMidi(_ outputURL:URL) {
        guard let midiFilePlayer = midiFilePlayer else {
            print("No midi player!")
            return
        }
        guard currentInstrument != nil else {
            print("No plugin selected")
            return
        }
        //midiFilePlayer.midiFile = "/Users/gislim/Documents/Verkefni/Code/raunder/out.mid"
        midiFilePlayer.midiURL = currentMidiURL
        //midiFilePlayer.wavFile  = "/Users/gislim/Documents/Verkefni/Code/raunder/out.wav"
        midiFilePlayer.render(outputURL)
    }
    
    func _selectMidi(_ midiURL:URL) {
        currentMidiURL = midiURL
        midiField.stringValue = midiURL.path
    }
    
    func _selectPreset(_ presetFile:URL) {
        guard let instrument = currentInstrument else {
            print("No instrument selected! Should not be here")
            return
        }
        let success = loadPreset(instrument,presetFile)
        if success {
            currentPresetURL = presetFile
            presetField.stringValue = presetFile.path
        } else {
            print("Couldn't load preset")
        }
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
        //midiFilePlayer.midiFile   = "/Users/gislim/Documents/Verkefni/Code/raunder/out.mid"
        midiFilePlayer.midiURL = currentMidiURL
        midiFilePlayer.play()
    }
    
    @IBAction func selectMidi(_ sender:NSButton) {
        let dialog = NSOpenPanel()
        
        dialog.title = "Select a midi file"
        dialog.allowedFileTypes = ["mid","midi"]
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            guard let result = dialog.url else {
                print("Something went wrong")
                return
            }
            _selectMidi(result)
        } else {
            print("User cancelled")
        }
    }
    
    @IBAction func selectPreset(_ sender:NSButton) {
        
        if currentInstrument == nil {
            print("No instrument selected! Button should be disabled")
            return
        }

        let dialog = NSOpenPanel()
        
        dialog.title = "Select a preset"
        dialog.allowedFileTypes = ["plist","preset"]
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            guard let result = dialog.url else {
                print("Something went wrong")
                return
            }
            _selectPreset(result)
        } else {
            print("User cancelled")
        }
    }
    
    @IBAction func renderMidi(_ sender:NSButton) {
        if currentInstrument == nil {
            print("No instrument selected! Button should be disabled")
            return
        }
        if currentMidiURL == nil {
            print("No midi file selected! Button should be disabled")
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.showsTagField = false
        savePanel.nameFieldStringValue = "out.wav"
        savePanel.begin { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                print("Get the URL")
                guard let outputURL = savePanel.url else {
                    print("Didn't get any url")
                    return
                }
                self._renderMidi(outputURL)
            }
        }
        //self._renderMidi()
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
