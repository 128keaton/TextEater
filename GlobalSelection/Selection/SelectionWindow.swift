//
//  SelectionWindow.swift
//  TextEater
//
//  Created by Keaton Burleson on 5/6/21.
//

import Foundation
import AppKit

public class SelectionWindow: NSWindow {
    
    public init(frame: CGRect, selectionDelegate: SelectionViewDelegate, debug: Bool = false) {
        super.init(contentRect: frame, styleMask: .fullSizeContentView, backing: .buffered, defer: false)
        
        let propertyString = CFStringCreateWithCString(kCFAllocatorDefault, "SetsCursorInBackground", 0)
        CGSSetConnectionProperty(_CGSDefaultConnection(), _CGSDefaultConnection(), propertyString, kCFBooleanTrue)
        
        self.contentView = SelectionView(delegate: selectionDelegate, frame: frame)
        self.isOpaque = false
      
        if debug {
            self.backgroundColor = NSColor.red.withAlphaComponent(0.2)
        } else {
            self.backgroundColor = NSColor.gray.withAlphaComponent(0.01)
        }
        
        self.titleVisibility = .hidden
        self.styleMask.remove(.titled)
        self.level = NSWindow.Level.init(Int(CGWindowLevelForKey(.statusWindow)))
        self.setAccessibilityHidden(true)
        self.makeKeyAndOrderFront(nil)
        self.contentView?.wantsLayer = true
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.isReleasedWhenClosed = false
    }
    
    public override func becomeKey() {
        super.becomeKey()
        
        NSCursor.crosshair.push()
    }
}
