//
//  PreviewWindow.swift
//  GlobalSelection
//
//  Created by Keaton Burleson on 5/6/21.
//

import Foundation
import AppKit

class PreviewWindow: NSWindow {
    
    private var imageView: PreviewImageView?
    private var visualEffect: NSVisualEffectView?
    
    init(image: NSImage) {
        super.init(contentRect: NSRect(x: 0, y: PreviewWindow.getScreenWithMouse()?.frame.maxX ?? 0, width: 200, height: 200), styleMask: .titled, backing: .buffered, defer: true)
        
        
        self.setupImageView(image)
        self.setupEffectView()
        self.configureWindow(image)
        self.addBaseConstraints()
        self.fadeIn(self)
    }
    
    
    override func close() {
        self.fadeOut(self)
    }
    
    private func setupImageView(_ image: NSImage) {
        self.imageView = PreviewImageView(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        self.imageView?.image = image
        self.imageView?.wantsLayer = true
        self.imageView?.layer?.cornerRadius = 16.0
    }

    private func setupEffectView() {
        self.visualEffect = NSVisualEffectView()
        self.visualEffect?.translatesAutoresizingMaskIntoConstraints = false
        self.visualEffect?.state = .active
        self.visualEffect?.wantsLayer = true
        self.visualEffect?.layer?.cornerRadius = 16.0
        self.visualEffect?.addSubview(self.imageView!)
    }
    
    private func configureWindow(_ image: NSImage) {
        self.title = "Preview"
        self.titlebarAppearsTransparent = true
        self.level = NSWindow.Level.init(Int(CGWindowLevelForKey(.statusWindow)))
        self.backgroundColor = .clear
        self.isMovableByWindowBackground = true
        self.isReleasedWhenClosed = false
        self.styleMask.insert(.fullSizeContentView)
        self.contentView = self.visualEffect
        
        self.minSize = NSSize(width: 120, height: 120)
        self.maxSize = NSSize(width: 250, height: 250)
        self.contentMaxSize = self.maxSize
        self.contentMinSize = self.minSize
        
        let sizeWithTitlebar = NSSize(width: image.size.width, height: image.size.height + self.titlebarHeight)
        self.setContentSize(sizeWithTitlebar)
        self.contentAspectRatio = sizeWithTitlebar
        
        self.moveTopRight()
    }
    
    private func addBaseConstraints() {
        guard let constraints = self.contentView else {
          return
        }
        
        guard let visualEffect = self.visualEffect else {
            return
        }

        visualEffect.leadingAnchor.constraint(equalTo: constraints.leadingAnchor).isActive = true
        visualEffect.trailingAnchor.constraint(equalTo: constraints.trailingAnchor).isActive = true
        visualEffect.topAnchor.constraint(equalTo: constraints.topAnchor).isActive = true
        visualEffect.bottomAnchor.constraint(equalTo: constraints.bottomAnchor).isActive = true
    }
    
    private static func getScreenWithMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let screenWithMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })

        return screenWithMouse
    }
}
