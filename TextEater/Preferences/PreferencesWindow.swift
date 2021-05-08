//
//  PreferencesWindow.swift
//  TextEater
//
//  Created by Keaton Burleson on 5/7/21.
//

import Foundation
import Cocoa

class PreferencesWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        if let vc = self.contentViewController as? PreferencesViewController {
            if vc.listening {
                vc.updateGlobalShortcut(event)
            } else {
                super.keyDown(with: event)
            }
        } else {
            super.keyDown(with: event)
        }
    }
}
