//
//  KeyBindField.swift
//  TextEater
//
//  Created by Keaton Burleson on 5/7/21.
//

import Foundation
import Cocoa

class KeyBindField: NSTextField {
    public var focus: Bool = false
    
    override func awakeFromNib() {
        self.focusRingType = NSFocusRingType.none
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if focus {
            let bounds = self.bounds
            let outerRect = NSMakeRect(bounds.origin.x - 2, bounds.origin.y - 2, bounds.size.width + 4, bounds.size.height + 4)
            let innerRect = NSInsetRect(outerRect, 1, 1)
            let clipPath = NSBezierPath(rect: outerRect)
            clipPath.append(NSBezierPath(rect: innerRect))
            clipPath.windingRule = NSBezierPath.WindingRule.evenOdd
            clipPath.setClip()

            NSColor(calibratedWhite: 0.6, alpha: 1.0).setFill()
            NSBezierPath(rect: outerRect).fill()
            self.backgroundColor = NSColor.systemBlue
        }

    }
}
