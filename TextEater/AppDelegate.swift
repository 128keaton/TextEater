//
//  AppDelegate.swift
//  TextEater
//
//  Created by Keaton Burleson on 5/5/21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var menu: NSMenu?

    var statusItem: NSStatusItem?
    var selectionHandler: SelectionHandler?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.selectionHandler = SelectionHandler(delegate: self)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "TextEater"

        if let menu = menu {
            statusItem?.menu = menu
        }
    }



    @IBAction func captureToggle(sender: Any) {
        self.selectionHandler?.startListening()
    }

    @IBAction func quitApp(sender: Any) {
        NSApp.terminate(self)
    }

    @IBAction func updateMode(sender: NSMenuItem) {
        if sender.state == .on {
            sender.state = .off
            self.selectionHandler?.recognitionLevel = .accurate
        } else {
            sender.state = .on
            self.selectionHandler?.recognitionLevel = .fast
        }
    }
}

extension AppDelegate: SelectionHandlerDelegate {
    func resultsAvailable(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        print("Text Result: \(text)")
        self.selectionHandler?.stopListening()
   
        DispatchQueue.main.async {
            self.statusItem?.button?.title = "TextEater"
        }
    }

    func processingResults() {
        self.statusItem?.button?.title = "Processing..."
    }
}
