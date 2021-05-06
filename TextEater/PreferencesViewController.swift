//
//  PreferencesViewController.swift
//  TextEater
//
//  Created by Keaton Burleson on 5/6/21.
//

import Foundation
import AppKit
import GlobalSelection

class PreferencesViewController: NSViewController {

    @IBOutlet weak var modeButton: NSPopUpButton?
    @IBOutlet weak var debugButton: NSButton?
    @IBOutlet weak var previewButton: NSButton?
    @IBOutlet weak var notifyButton: NSButton?
    
    var selectionHandler: SelectionHandler?
    
    private var canNotify: Bool = true
    private let modes = ["Fast", "Accurate"]
    
    static func present(withSelectionHandler selectionHandler: SelectionHandler?, canNotify: Bool) {
        let storyboard = NSStoryboard(name: "Preferences", bundle: nil)
        let viewController: PreferencesViewController = storyboard.instantiateInitialController()!
        
        viewController.selectionHandler = selectionHandler
        viewController.canNotify = canNotify
        
        let window = NSWindow(contentViewController: viewController)
        let customToolbar = NSToolbar()
        window.toolbar = customToolbar
        
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let selectedMode = UserDefaults.standard.bool(forKey: "fast") ? "Fast" : "Accurate"
        let debug = UserDefaults.standard.bool(forKey: "debug")
        let showPreview = UserDefaults.standard.bool(forKey: "preview")
        let shouldNotify = UserDefaults.standard.bool(forKey: "notify")
        
        self.populateModeButton(selected: selectedMode)
        self.debugButton?.state = debug ? .on : .off
        self.previewButton?.state = showPreview ? .on : .off
        self.notifyButton?.isEnabled = self.canNotify
        self.notifyButton?.state = shouldNotify ? .on : .off
        
        if !self.canNotify {
            self.notifyButton?.toolTip = "Notifications have not been enabled for TextEater at a system-level"
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()

        view.window?.styleMask.remove(.resizable)
        view.window?.styleMask.remove(.miniaturizable)
        view.window?.center()
    }

    
    private func populateModeButton(selected: String) {
        if let modeButton = self.modeButton {
            modeButton.removeAllItems()
            modeButton.addItems(withTitles: self.modes)
            
            if let index = self.modes.firstIndex(of: selected) {
                modeButton.selectItem(at: index)
            }
        }
    }
    
    @IBAction func modeChanged(_ sender: NSPopUpButton) {
        if let selected = sender.titleOfSelectedItem {
            UserDefaults.standard.set(selected == "Fast", forKey: "fast")
            if let selectionHandler = self.selectionHandler {
                selectionHandler.recognizeFast = selected == "Fast"
            }
        }
        
    }
    
    @IBAction func debugChanged(_ sender: NSButton) {
        UserDefaults.standard.setValue(sender.state == .on, forKey: "debug")
        if let selectionHandler = self.selectionHandler {
            selectionHandler.debug = sender.state == .on
        }
    }
    
    @IBAction func previewChanged(_ sender: NSButton) {
        UserDefaults.standard.setValue(sender.state == .on, forKey: "preview")
        if let selectionHandler = self.selectionHandler {
            selectionHandler.showPreview = sender.state == .on
        }
    }
    
    @IBAction func notifyChanged(_ sender: NSButton) {
        UserDefaults.standard.setValue(sender.state == .on, forKey: "notify")
    }
}
