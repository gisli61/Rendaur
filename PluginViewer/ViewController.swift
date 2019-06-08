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
    private var myWindowController: NSWindowController? // Temporary store
    private var testWindowController: NSWindowController?

    //MARK: Properties
    @IBOutlet weak var pluginPopup: NSPopUpButton!
    @IBOutlet weak var openPluginButton: NSButton!
    @IBOutlet weak var playMidiButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    
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
    
    private func createAUWindow(viewController: NSViewController,
                                audioUnit: AVAudioUnit,
                                identifier: Int,
                                origin: NSPoint? = nil,
                                color: NSColor? = nil) {
        let incomingFrame = viewController.view.frame
        let windowController = AudioUnitWindow(audioUnit: audioUnit)
        
        guard let unitWindow = windowController.window else {
            print("Have no window")
            return
        }
        guard let auName = audioUnit.auAudioUnit.audioUnitName else {
            print("Have no audioUnitName")
            return
        }
        
        let winId = windowPrefix + String(identifier)
        //let windowFrame = NSRect(origin: origin,
        //                         size: NSSize(width: incomingFrame.width, height: incomingFrame.height + 30))
        unitWindow.delegate = self
        
        windowController.scrollView?.removeFromSuperview()
        windowController.contentViewController = viewController
        
        view.window?.addChildWindow(unitWindow, ordered: NSWindow.OrderingMode.above)
    }
    
    public func showAudioUnit(_ audioUnit: AVAudioUnit) {
        audioUnit.auAudioUnit.requestViewController { [weak self] viewController in
            guard let strongSelf = self else {
                print("self missing")
                return
            }
            
            guard let ui = viewController else {
                print("no viewController!")
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.createAUWindow(viewController:ui,
                                          audioUnit: audioUnit,
                                          identifier: 6)
            }
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
        
        /*
        current.requestViewController() { [weak self] viewController in
            guard let strongSelf = self else {
                print("Self is nil")
                return
            }
            
            guard let vc = viewController else {
                print("viewController is nil")
                return
            }
            print("have a view controller")
            DispatchQueue.main.async {
                strongSelf.myWindowController = MyWindowController()
                //strongSelf.myWindowController = AudioUnitWindow()
                
                guard let unitWindow = strongSelf.myWindowController?.window else {
                    print("got no window")
                    return
                }
                unitWindow.title = "MyAudioUnit"
                //unitWindow.delegate = strongSelf
                
                strongSelf.myWindowController!.contentViewController = vc
                strongSelf.myWindowController!.showWindow(nil)

            }
        }
       */

    }

    @IBAction func openTestWindow(_ sender:NSButton) {

        testWindowController = TestWindow()
        guard let wc = testWindowController else {
            print("Could not get window")
            return
        }
        print(wc.windowNibName ?? "No window nib name")
        wc.showWindow(nil)
        if wc.window == nil {
            print("No window here either")
        }
        
        
    }
    
    @IBAction func openPluginWindow(_ sender:NSButton) {
        guard let currentAV = currentAVInstrument else {
            print("No plugin selected!")
            return
        }
        guard let current = currentInstrument else {
            print("No plugin selected!")
            return
        }
        
        //showAudioUnit(currentAV)
        
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
