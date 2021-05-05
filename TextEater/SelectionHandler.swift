//
//  SelectionHandler.swift
//  TextEater
//
//  Created by Keaton Burleson on 5/5/21.
//

import Foundation
import Vision
import CoreML
import AppKit

protocol SelectionHandlerDelegate {
    func processingResults()
    func resultsAvailable(text: String)
}

class SelectionHandler {
    private var dragMonitor: Any?
    private var leftMouseDownMonitor: Any?
    private var leftMouseUpMonitor: Any?
    private var isDragging = false
    private var globalWindow: NSWindow?
    private var startPoint: NSPoint!
    private var shapeLayer: CAShapeLayer!
    private var rect: CGRect?
    private var delegate: SelectionHandlerDelegate?
    
    var recognitionLevel: VNRequestTextRecognitionLevel = .fast
    

    init(delegate: SelectionHandlerDelegate) {
        self.delegate = delegate
    }

    func startListening() {
        
        NSCursor.crosshair.set()
        
        self.dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { event in
            self.handleDragging(event)
        }

        self.leftMouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [self] event in
            self.startDragging(event)
        }

        self.leftMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { event in
            self.processResult()
        }
    }

    func stopListening() {
        
        NSCursor.arrow.set()
        
        if self.dragMonitor != nil {
            NSEvent.removeMonitor(self.dragMonitor!)
            self.dragMonitor = nil
        }

        if self.leftMouseDownMonitor != nil {
            NSEvent.removeMonitor(self.leftMouseDownMonitor!)
            self.leftMouseDownMonitor = nil
        }

        if self.leftMouseUpMonitor != nil {
            NSEvent.removeMonitor(self.leftMouseUpMonitor!)
            self.leftMouseUpMonitor = nil
        }
    }

    private func getTextRecognitionRequest() -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest(completionHandler: self.handleDetection)
        
        print("Creating request with recognition level: \(self.recognitionLevel == .fast ? "Fast" : "Accurate")")
        request.recognitionLevel = self.recognitionLevel
        request.recognitionLanguages = ["en_US"]

        return request
    }

    private func handleDetection(request: VNRequest?, error: Error?) {
        if let error = error {
            print("ERROR: \(error)")
            return
        }
        guard let results = request?.results, results.count > 0 else {
            print("No text found")
            return
        }

        let textResult: String = results.map { result in
            if let observation = result as? VNRecognizedTextObservation {
                return observation.topCandidates(1).map { text in
                    return text.string
                }.joined(separator: " ")

            }

            return ""
        }.joined(separator: " ")

        self.delegate?.resultsAvailable(text: textResult)
    }

    private func setupWindow(windowRect: NSRect) -> NSWindow? {
        print("setupWindow: \(windowRect)")
        if let window = self.globalWindow,
            window.frame == windowRect {
            return window
        } else if let window = self.globalWindow {
            window.close()
            self.globalWindow = nil
        }

        self.globalWindow = NSWindow(contentRect: windowRect, styleMask: .borderless, backing: .buffered, defer: false)
        self.globalWindow?.isOpaque = false
        self.globalWindow?.backgroundColor = NSColor.clear
        self.globalWindow?.level = NSWindow.Level.init(Int(CGWindowLevelForKey(.statusWindow)))
     //   self.globalWindow?.setAccessibilityHidden(true)
        self.globalWindow?.makeKeyAndOrderFront(nil)
        self.globalWindow?.contentView?.wantsLayer = true
        self.globalWindow?.acceptsMouseMovedEvents = true
        self.globalWindow?.isReleasedWhenClosed = false

        NSApplication.shared.activate(ignoringOtherApps: true)
        return self.globalWindow
    }

    private func processResult() {
        if let imageRect = self.rect,
            let windowID = self.globalWindow?.windowNumber,
            let screen = self.getScreenWithMouse(), imageRect.width > 5 && imageRect.height > 5 {
            self.delegate?.processingResults()
            
            let cgScreenshot = CGWindowListCreateImage(screen.frame, .optionOnScreenBelowWindow, CGWindowID(windowID), .bestResolution)

            let goodPoint = screen.frame.height - NSMaxY(imageRect)
            let correctedRect = CGRect(x: imageRect.origin.x, y: goodPoint, width: imageRect.width, height: imageRect.height)
            if let croppedCGScreenshot = cgScreenshot?.cropping(to: correctedRect) {


                let rep = NSBitmapImageRep(cgImage: croppedCGScreenshot)
                let image = NSImage()
                image.addRepresentation(rep)


                let requests = [self.getTextRecognitionRequest()]
                let imageRequestHandler = VNImageRequestHandler(cgImage: croppedCGScreenshot, orientation: .up, options: [:])

                DispatchQueue.main.async {
                    do {
                        try imageRequestHandler.perform(requests)
                    } catch let error {
                        print("Error: \(error)")
                    }
                }
            }
        }

        if let shapeLayer = self.shapeLayer {
            shapeLayer.removeFromSuperlayer()
            self.shapeLayer = nil
        }

        if let window = self.globalWindow {
            window.close()
            self.globalWindow = nil
        }

        self.rect = nil
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
            self.rect = path.boundingBox
        }
    }

    private func startDragging(_ event: NSEvent) {
        if !self.isDragging {
            if let window = self.setupWindow(windowRect: self.getScreenWithMouse()!.frame),
                let contentView = window.contentView,
                let layer = contentView.layer {

                self.isDragging = true

                self.startPoint = window.mouseLocationOutsideOfEventStream

                shapeLayer = CAShapeLayer()
                shapeLayer.lineWidth = 1.0
                shapeLayer.fillColor = NSColor.white.withAlphaComponent(0.5).cgColor
                shapeLayer.strokeColor = NSColor.black.cgColor
                shapeLayer.lineDashPattern = [10, 5]
                layer.addSublayer(shapeLayer)

                var dashAnimation = CABasicAnimation()
                dashAnimation = CABasicAnimation(keyPath: "lineDashPhase")
                dashAnimation.duration = 0.75
                dashAnimation.fromValue = 0.0
                dashAnimation.toValue = 15.0
                dashAnimation.repeatCount = .infinity
                shapeLayer.add(dashAnimation, forKey: "linePhase")
            }
        }
    }

    private func getScreenWithMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let screenWithMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })

        return screenWithMouse
    }

}
