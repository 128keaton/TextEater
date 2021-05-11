//
//  PreviewWindow.swift
//  GlobalSelection
//
//  Created by Keaton Burleson on 5/6/21.
//

import Foundation
import AppKit

class PreviewWindow: NSWindow {

    public var locked: Bool = false

    private var imageView: PreviewImageView?
    private var visualEffect: NSVisualEffectView?
    private var lockButton: NSButton?
    private var closeButton: NSButton?
    private var lockTimer: Timer?
    private var lockTimerExpired: Bool = false
    
    init(image: NSImage) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 200, height: 200), styleMask: .titled, backing: .buffered, defer: true)

        self.setupImageView(image)
        self.setupEffectView()
        self.configureWindow(image)
        self.addBaseConstraints()
        self.addLockButton()
        self.addCloseButton()
        self.fadeIn(self)
    }
    
    override func close() {
        print("Is self \(self) locked? \(self.locked)")
        if !self.locked {
            self.fadeOut(self)
        }
    }

    @objc func toggleLocked(sender: NSButton) {
        self.locked = !self.locked
        
        if let lockButton = self.lockButton {
            lockButton.image = self.locked ? NSImage(named: "NSLockLockedTemplate") : NSImage(named: "NSLockUnlockedTemplate")
        }
        
      
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.close()
        }
    }

    @objc func closeFadeOut() {
        self.fadeOut(self)
    }
    
    private func addLockButton() {
        if let contentView = self.contentView {
            self.lockButton = NSButton(frame: NSRect(x: contentView.frame.maxX - 25, y: contentView.frame.maxY - 25, width: 22, height: 22))
            self.lockButton?.image = NSImage(named: "NSLockUnlockedTemplate")
            self.lockButton?.action = #selector(toggleLocked)
            self.lockButton?.target = self
            self.lockButton?.imagePosition = .imageOnly
            self.lockButton?.isBordered = false
            
            contentView.addSubview(self.lockButton!)
        }
    }
    
    private func addCloseButton() {
        if let contentView = self.contentView {
            self.closeButton = NSButton(frame: NSRect(x: 8, y: contentView.frame.maxY - 25, width: 22, height: 22))
            self.closeButton?.image = NSImage(named: "NSStopProgressFreestandingTemplate")
            self.closeButton?.action = #selector(closeFadeOut)
            self.closeButton?.target = self
            self.closeButton?.imagePosition = .imageOnly
            self.closeButton?.isBordered = false
            
            contentView.addSubview(self.closeButton!)
        }
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
        self.backgroundColor = .clear
        self.isMovableByWindowBackground = true
        self.isReleasedWhenClosed = false
        self.styleMask.insert(.fullSizeContentView)
        self.contentView = self.visualEffect
        self.level = NSWindow.Level.init(Int(CGWindowLevelForKey(.statusWindow)))
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
