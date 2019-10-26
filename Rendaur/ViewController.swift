//
//  ViewController.swift
//  Rendaur
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
    var currentEffect:AVAudioUnitEffect?
    var currentMidiURL:URL?
    var currentPresetURL:URL?
    var currentWavURL:URL?
    private var midiFilePlayer:MidiFilePlayer?
    private var audioFilePlayer:AudioFilePlayer?
    //private var testWindowController: NSWindowController?

    //MARK: Outlets
    @IBOutlet weak var pluginPopup: NSPopUpButton!
    @IBOutlet weak var effectPopup: NSPopUpButton!
    @IBOutlet weak var openPluginButton: NSButton!
    @IBOutlet weak var openEffectButton: NSButton!
    @IBOutlet weak var savePresetButton: NSButton!
    @IBOutlet weak var saveEffectPresetButton: NSButton!
    @IBOutlet weak var presetField: NSTextField!
    @IBOutlet weak var effectPresetField: NSTextField!
    @IBOutlet weak var selectPresetButton: NSButton!
    @IBOutlet weak var selectEffectPresetButton: NSButton!
    @IBOutlet weak var midiField: NSTextField!
    @IBOutlet weak var wavField: NSTextField!
    @IBOutlet weak var selectMidiButton: NSButton!
    @IBOutlet weak var selectWavButton: NSButton!
    @IBOutlet weak var playMidiButton: NSButton!
    @IBOutlet weak var playWavButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var stopWavButton: NSButton!
    @IBOutlet weak var renderButton: NSButton!
    @IBOutlet weak var renderWavButton: NSButton!
    @IBOutlet weak var controllerField: NSTextField!
    @IBOutlet weak var contollerKnob: NSSliderCell!
    
    
    //MARK: Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        //print("viewDidLoad")
        midiFilePlayer = MidiFilePlayer()
        audioFilePlayer = AudioFilePlayer()
        
        // Do any additional setup after loading the view.
        pluginPopup.addItem(withTitle: "Select instrument...")
        for x in listInstruments() {
            pluginPopup.addItem(withTitle: x)
        }
        for x in listPresets() {
            pluginPopup.addItem(withTitle: x)
        }
        effectPopup.addItem(withTitle: "Select effect...")
        for x in listEffects() {
            effectPopup.addItem(withTitle: x)
        }
        ViewController.vc = self
    }
    
    //MARK: Functions
    func _changePlugin(_ pluginName:String) -> Bool {
        guard let instrument = getAVAudioUnitMIDIInstrument(pluginName) else {
            print("Could not load \(pluginName)")
            return false
        }
        //print("Loaded \(instrument.name)")
        currentInstrument = instrument
        currentPresetURL = nil
        presetField.stringValue = ""
        
        guard let midiFilePlayer = midiFilePlayer else {
            print("No midi file player!! Something serious happened")
            return false
        }
        pluginPopup.selectItem(withTitle: pluginName)
        midiFilePlayer.midiInstrument = currentInstrument
        openPluginButton.isEnabled = true
        savePresetButton.isEnabled = true
        selectPresetButton.isEnabled = true
        return true
    }
    
    func _changeEffect(_ effectName:String) -> Bool {
        guard let effect = getAVAudioUnitEffect(effectName) else {
            print("Could not load \(effectName)")
            return false
        }
        //print("Loaded \(instrument.name)")
        currentEffect = effect
        currentPresetURL = nil
        presetField.stringValue = ""
        
        guard let audioFilePlayer = audioFilePlayer else {
            print("No audio file player!! Something serious happened")
            return false
        }
        effectPopup.selectItem(withTitle: effectName)
        audioFilePlayer.effect = effect
        openEffectButton.isEnabled = true
        saveEffectPresetButton.isEnabled = true
        selectEffectPresetButton.isEnabled = true
        return true
    }
    
    func _renderMidi(_ outputURL:URL,_ offset:UInt32=0) -> Bool {
        guard let midiFilePlayer = midiFilePlayer else {
            print("No midi player!")
            return false
        }
        guard currentInstrument != nil else {
            print("No plugin selected")
            return false
        }
        //midiFilePlayer.midiFile = "/Users/gislim/Documents/Verkefni/Code/raunder/out.mid"
        midiFilePlayer.midiURL = currentMidiURL
        //midiFilePlayer.wavFile  = "/Users/gislim/Documents/Verkefni/Code/raunder/out.wav"
        //Rendering twice to get rid of startup problems in some instruments
        if !midiFilePlayer.render(outputURL,offset,false) {
            print("Rendering preflight failed")
        }
        let success = midiFilePlayer.render(outputURL,offset)
        
        return success
    }

    func _renderWav(_ outputURL:URL,_ offset:UInt32=0) -> Bool {
        guard let audioFilePlayer = audioFilePlayer else {
            print("No audio file player!")
            return false
        }
        guard currentEffect != nil else {
            print("No effect selected")
            return false
        }
        audioFilePlayer.wavURL = currentWavURL
        //midiFilePlayer.wavFile  = "/Users/gislim/Documents/Verkefni/Code/raunder/out.wav"
        //Rendering twice to get rid of startup problems in some instruments
        //if !midiFilePlayer.render(outputURL,offset,false) {
        //    print("Rendering preflight failed")
        //}
        
        let success = audioFilePlayer.render(outputURL,offset)
        
        return success
    }

    func _selectMidi(_ midiURL:URL) {
        currentMidiURL = midiURL
        midiField.stringValue = midiURL.path
        playMidiButton.isEnabled = true
        stopButton.isEnabled = true
        renderButton.isEnabled = true
    }
    
    func _selectWav(_ wavURL:URL) {
        currentWavURL = wavURL
        wavField.stringValue = wavURL.path
        playWavButton.isEnabled = true
        stopWavButton.isEnabled = true
        renderWavButton.isEnabled = true
    }
    
    func _selectPreset(_ presetFile:URL) -> Bool {
        guard let instrument = currentInstrument else {
            print("No instrument selected! Should not be here")
            return false
        }
        let success = loadPreset(instrument,presetFile)
        if success {
            currentPresetURL = presetFile
            presetField.stringValue = presetFile.path
        } else {
            print("Couldn't load preset")
            return false
        }
        return true
    }

    func _selectEffectPreset(_ presetFile:URL) -> Bool {
        guard let effect = currentEffect else {
            print("No effect selected! Should not be here")
            return false
        }
        let success = loadEffectPreset(effect,presetFile)
        if success {
            currentPresetURL = presetFile
            effectPresetField.stringValue = presetFile.path
        } else {
            print("Couldn't load preset")
            return false
        }
        return true
    }

    func _savePreset(_ presetFile:URL) -> Bool {
        guard let instrument = currentInstrument else {
            print("No instrument selected! Cannot save preset")
            return false
        }
        let success = writePreset(instrument, presetFile)
        return success
    }

    func _saveEffectPreset(_ presetFile:URL) -> Bool {
        guard let effect = currentEffect else {
            print("No effect selected! Cannot save preset")
            return false
        }
        let success = writeEffectPreset(effect, presetFile)
        return success
    }

    func _pluginInfo() -> Bool {
        guard let instrument = currentInstrument else {
            print("No instrument selected! Cannot save preset")
            return false
        }

        pluginInfo(instrument)
        return true
    }
    
    //MARK: Actions
    @IBAction func changePlugin(_ sender: NSPopUpButton) {
        guard let pluginName = sender.titleOfSelectedItem else {
            print("Could not pick item")
            return
        }
        let _ = self._changePlugin(pluginName)
    }
    
    @IBAction func changeEffect(_ sender: NSPopUpButton) {
        guard let effectName = sender.titleOfSelectedItem else {
            print("Could not pick item")
            return
        }
        let _ = self._changeEffect(effectName)
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
    
    @IBAction func playWav(_ sender:NSButton) {
        guard let audioFilePlayer = audioFilePlayer else {
            print("No audio player!")
            return
        }
        audioFilePlayer.wavURL = currentWavURL
        audioFilePlayer.play()
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
    
    @IBAction func selectWav(_ sender:NSButton) {
        let dialog = NSOpenPanel()
        
        dialog.title = "Select a wav file"
        dialog.allowedFileTypes = ["wav"]
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            guard let result = dialog.url else {
                print("Something went wrong")
                return
            }
            _selectWav(result)
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
            let _ = _selectPreset(result)
        } else {
            print("User cancelled")
        }
    }
    
    @IBAction func selectEffectPreset(_ sender:NSButton) {
        if currentEffect == nil {
            print("No effect selected! Button should be disabled")
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
            let _ = _selectEffectPreset(result)
        } else {
            print("User cancelled")
        }
    }
    
    @IBAction func savePreset(_ sender:NSButton) {
        let savePanel = NSSavePanel()
        savePanel.showsTagField = false
        savePanel.nameFieldStringValue = "out.plist"
        
        savePanel.begin { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                print("Get the URL")
                guard let outputURL = savePanel.url else {
                    print("Didn't get any url")
                    return
                }
                let _ = self._savePreset(outputURL)
            }
        }

    }
    
    @IBAction func saveEffectPreset(_ sender:NSButton) {
        let savePanel = NSSavePanel()
        savePanel.showsTagField = false
        savePanel.nameFieldStringValue = "out.plist"
        
        savePanel.begin { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                print("Get the URL")
                guard let outputURL = savePanel.url else {
                    print("Didn't get any url")
                    return
                }
                let _ = self._saveEffectPreset(outputURL)
            }
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
                let _ = self._renderMidi(outputURL)
            }
        }
        /*
        guard let outputURL = savePanel.url else {
            print("Didn't get any url")
            return
        }
        self._renderMidi(outputURL)
        //self._renderMidi()
        */
    }
    
    @IBAction func renderWav(_ sender:NSButton) {
        /*
        if currentEffect == nil {
            print("No instrument selected! Button should be disabled")
            return
        }
        */
        if currentWavURL == nil {
            print("No wav file selected! Button should be disabled")
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.showsTagField = false
        savePanel.nameFieldStringValue = "out.wav"
        
        savePanel.begin { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                print("Get the effect wav URL")
                guard let outputURL = savePanel.url else {
                    print("Didn't get any url")
                    return
                }
                let _ = self._renderWav(outputURL)
            }
        }
    }

    @IBAction func stop(_ sender:NSButton) {
        guard let midiFilePlayer = midiFilePlayer else {
            print("No midi player!")
            return
        }
        midiFilePlayer.stop()
    }
    
    @IBAction func stopWav(_ sender:NSButton) {
        guard let audioFilePlayer = audioFilePlayer else {
            print("No audio player!")
            return
        }
        audioFilePlayer.stop()
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
        
        current.auAudioUnit.requestViewController() { nsViewController in
            guard let vc = nsViewController else {
                print("viewController is nil")
                return
            }

            auWindowController.contentViewController = vc

        }
        
        auWindowController.showWindow(nil)
    }

    @IBAction func openEffectWindow(_ sender: NSButton) {
        
        guard let current = currentEffect else {
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
        
        current.auAudioUnit.requestViewController() { nsViewController in
            guard let vc = nsViewController else {
                print("viewController is nil")
                return
            }
            
            auWindowController.contentViewController = vc
            
        }
        
        auWindowController.showWindow(nil)
    }

    var prevValue:UInt8 = 128
    
    @IBAction func sentControllerMessage(_ sender:NSSliderCell) {
        let controller = UInt8(controllerField.intValue)
        let value = UInt8(sender.intValue)
        if value == prevValue {
            return
        }
        prevValue = value
        
        if let instrument = currentInstrument {
            instrument.sendController(controller, withValue: value, onChannel: 0)
        } else {
            print("controller: \(controller), value: \(value)")
        }
    }

}

extension ViewController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
    }

}
