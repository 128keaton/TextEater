//
//  PreviewImageView.swift
//  GlobalSelection
//
//  Created by Keaton Burleson on 5/6/21.
//

import Foundation
import AppKit

class PreviewImageView: NSImageView {
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
}
