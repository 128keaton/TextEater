//
//  SelectionView.swift
//  TextEater
//
//  Created by Keaton Burleson on 5/6/21.
//

import Foundation
import QuartzCore
import AppKit

public protocol SelectionViewDelegate {
    func processResults(_ rect: CGRect)
}

class SelectionView: NSView {

    /// The starting point of the selection box
    private var startPoint: NSPoint!
    
    /// The shape layer (which is the selection box itself)
    private var shapeLayer: CAShapeLayer!
    
    /// Keeps track of our drag status
    private var isDragging = false
    
    /// CGRect representing the portion of the screen we selected
    private var selectionRect: CGRect?
    
    /// Delegate for the SelectionView (callback with the selection rect)
    public var delegate: SelectionViewDelegate?

    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    /// Initializer to setup view with a delegate and an initial frame
    init(delegate: SelectionViewDelegate, frame: CGRect) {
        super.init(frame: frame)
        self.delegate = delegate
    }
    
    deinit {
        NSCursor.arrow.set()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func mouseDown(with event: NSEvent) {
        self.startDragging(event)
    }

    override func mouseUp(with event: NSEvent) {
        if let selectionRect = self.selectionRect {
            self.delegate?.processResults(selectionRect)
        }
        
        self.reset()
    }

    override func mouseDragged(with event: NSEvent) {
        if self.isDragging {
            self.handleDragging(event)
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        self.trackingAreas.forEach { area in
            self.removeTrackingArea(area)
        }
        
        let newArea = NSTrackingArea(rect: self.visibleRect, options: [.activeAlways, .mouseEnteredAndExited, .mouseMoved], owner: self, userInfo: nil)
        
        self.addTrackingArea(newArea)
    }
    
    
    override func mouseEntered(with event: NSEvent) {
        NSCursor.crosshair.set()
    }
    
    private func reset() {
        if let shapeLayer = self.shapeLayer {
            shapeLayer.removeFromSuperlayer()
            self.shapeLayer = nil
        }
        
        if let window = self.window {
            window.close()
        }

        self.selectionRect = nil
        self.startPoint = nil
        self.isDragging = false
    }

    private func handleDragging(_ event: NSEvent) {
        let mouseLoc = event.locationInWindow

        if let point = self.startPoint,
            let layer = self.shapeLayer {
            let path = CGMutablePath()
            path.move(to: point)
            path.addLine(to: NSPoint(x: self.startPoint.x, y: mouseLoc.y))
            path.addLine(to: mouseLoc)
            path.addLine(to: NSPoint(x: mouseLoc.x, y: self.startPoint.y))
            path.closeSubpath()
            layer.path = path
            self.selectionRect = path.boundingBox
        }
    }

    private func startDragging(_ event: NSEvent) {
        if let window = self.window,
            let contentView = window.contentView,
            let layer = contentView.layer,
            !self.isDragging {

            self.isDragging = true
            self.startPoint = window.mouseLocationOutsideOfEventStream

            shapeLayer = CAShapeLayer()
            shapeLayer.lineWidth = 1.0
            shapeLayer.fillColor = NSColor.white.withAlphaComponent(0.5).cgColor
            shapeLayer.strokeColor = NSColor.systemGray.cgColor
            layer.addSublayer(shapeLayer)
        }
    }

}
