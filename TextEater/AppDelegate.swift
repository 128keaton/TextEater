//
//  AppDelegate.swift
//  TextEater
//
//  Created by Keaton Burleson on 5/5/21.
//

import Cocoa
import HotKey
import Carbon
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var statusBarManager: StatusBarManager?
    
    public var hotKey: HotKey? {
        didSet {
            guard let hotKey = hotKey else {
                return
            }

            hotKey.keyDownHandler = { [weak self] in
                self?.statusBarManager?.startCapturing()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if Storage.fileExists("globalKeybind.json", in: .documents) {

            let globalKeybinds = Storage.retrieve("globalKeybind.json", from: .documents, as: GlobalKeybindPreferences.self)
            hotKey = HotKey(keyCombo: KeyCombo(carbonKeyCode: globalKeybinds.keyCode, carbonModifiers: globalKeybinds.carbonFlags))
        } else {
            hotKey = HotKey(key: .two, modifiers: [.command, .option])
        }
    }
}
