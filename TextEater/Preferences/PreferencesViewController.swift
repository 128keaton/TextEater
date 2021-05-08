//
//  PreferencesViewController.swift
//  TextEater
//
//  Created by Keaton Burleson on 5/6/21.
//

import Foundation
import Cocoa
import GlobalSelection
import HotKey
import Carbon

class PreferencesViewController: NSViewController {

    @IBOutlet weak var modeButton: NSPopUpButton?
    @IBOutlet weak var debugButton: NSButton?
    @IBOutlet weak var previewButton: NSButton?
    @IBOutlet weak var notifyButton: NSButton?
    @IBOutlet weak var clearButton: NSButton!
    @IBOutlet weak var keybindField: KeyBindField!

    var selectionHandler: SelectionHandler?

    var listening = false {
        didSet {
            if listening {
                DispatchQueue.main.async { [weak self] in
                    self?.keybindField.focus = true
                    self?.keybindField.needsDisplay = true
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.keybindField.focus = false
                    self?.keybindField.needsDisplay = true
                }
            }
        }
    }

    private var canNotify: Bool = true
    private let modes = ["Fast", "Accurate"]

    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        print("key down bb")
    }

    static func present(withSelectionHandler selectionHandler: SelectionHandler?, canNotify: Bool) {
        let storyboard = NSStoryboard(name: "Preferences", bundle: nil)
        let viewController: PreferencesViewController = storyboard.instantiateInitialController()!
        
        viewController.selectionHandler = selectionHandler
        viewController.canNotify = canNotify
        
        let window = PreferencesWindow(contentViewController: viewController)
        let customToolbar = NSToolbar()
        window.toolbar = customToolbar

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    override func viewDidAppear() {
        self.keybindField.resignFirstResponder()
        self.view.window?.makeFirstResponder(self)
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

        if Storage.fileExists("globalKeybind.json", in: .documents) {
            let globalKeybinds = Storage.retrieve("globalKeybind.json", from: .documents, as: GlobalKeybindPreferences.self)
            updateKeybindButton(globalKeybinds)
            updateClearButton(globalKeybinds)
        }
        
        let clickShortcutField = NSClickGestureRecognizer(target: self, action: #selector(self.register))
        self.keybindField.addGestureRecognizer(clickShortcutField)
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

    @objc func register(_ sender: Any) {
        unregister(nil)
        listening = true
        view.window?.makeFirstResponder(nil)
    }

    @IBAction func unregister(_ sender: Any?) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.hotKey = HotKey(key: .two, modifiers: [.command, .option])
        keybindField.stringValue = ""
        clearButton.isEnabled = false

        Storage.remove("globalKeybind.json", from: .documents)
    }


    func updateGlobalShortcut(_ event: NSEvent) {
        self.listening = false

        if let characters = event.charactersIgnoringModifiers {
            let newGlobalKeybind = GlobalKeybindPreferences.init(
                function: event.modifierFlags.contains(.function),
                control: event.modifierFlags.contains(.control),
                command: event.modifierFlags.contains(.command),
                shift: event.modifierFlags.contains(.shift),
                option: event.modifierFlags.contains(.option),
                capsLock: event.modifierFlags.contains(.capsLock),
                carbonFlags: event.modifierFlags.carbonFlags,
                characters: characters,
                keyCode: UInt32(event.keyCode)
            )

            Storage.store(newGlobalKeybind, to: .documents, as: "globalKeybind.json")
            updateKeybindButton(newGlobalKeybind)
            clearButton.isEnabled = true
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.hotKey = HotKey(keyCombo: KeyCombo(carbonKeyCode: UInt32(event.keyCode), carbonModifiers: event.modifierFlags.carbonFlags))
        }

    }

    func updateClearButton(_ globalKeybindPreference: GlobalKeybindPreferences?) {
        if globalKeybindPreference != nil {
            clearButton.isEnabled = true
        } else {
            clearButton.isEnabled = false
        }
    }

    func updateKeybindButton(_ globalKeybindPreference: GlobalKeybindPreferences) {
        keybindField.stringValue = globalKeybindPreference.description
    }
}
