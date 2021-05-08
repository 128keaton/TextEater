//
//  PreferencesWindowController.swift
//  TextEater
//
//  Created by Keaton Burleson on 5/7/21.
//

import Foundation
import AppKit

class PreferencesWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        self.becomeFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)

        if let vc = self.contentViewController as? PreferencesViewController {
            if vc.listening {
                vc.updateGlobalShortcut(event)
            }
        }
    }
}

