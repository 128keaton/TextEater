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

public protocol SelectionHandlerDelegate {
    func processingResults()
    func resultsAvailable(text: String?, error: String?)
}

public class SelectionHandler: SelectionViewDelegate {
    private var globalWindow: NSWindow?
    private var delegate: SelectionHandlerDelegate?
    private var selectionView: SelectionView?
    private var recognitionLevel: VNRequestTextRecognitionLevel = .fast
    private var previewWindow: PreviewWindow?
    private var locale: String = "en_US"

    public var keepLineBreaks: Bool = false
    public var showPreview: Bool = true
    public var debug: Bool = false
    public var recognizeFast: Bool = true {
        didSet {
            self.recognitionLevel = recognizeFast ? .fast : .accurate
        }
    }


    public init(delegate: SelectionHandlerDelegate) {
        self.delegate = delegate
        
        if let locale = NSLocale.preferredLanguages.first {
            self.locale = locale
        }
    }
    
    public func getLocale() -> String {
        return self.locale
    }

    public func startListening() {
        self.globalWindow = self.setupWindow(windowRect: self.getScreenWithMouse()!.frame)
    }

    private func hidePreviewWindow() {
        DispatchQueue.main.async {
            if let previewWindow = self.previewWindow {
                previewWindow.close()
            }

            self.previewWindow = nil
        }
    }

    private func getTextRecognitionRequest() -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest(completionHandler: self.handleDetection)

        print("Creating request with recognition level: \(self.recognitionLevel == .fast ? "fast" : "accurate")")
        print("Show preview window: \(self.showPreview ? "yes" : "no")")
        print("Show debug overlay: \(self.debug ? "yes" : "no")")
        print("Using \(self.locale) for text recognition")
        
        request.recognitionLanguages = [self.locale]
        request.recognitionLevel = self.recognitionLevel

        return request
    }

    private func handleDetection(request: VNRequest?, error: Error?) {
        if let error = error {
            print("ERROR: \(error)")
            self.delegate?.resultsAvailable(text: nil, error: error.localizedDescription)
            return
        }
        guard let results = request?.results, results.count > 0 else {
            print("No text found")
            self.delegate?.resultsAvailable(text: nil, error: "No text found")
            return
        }

        print("Keep line breaks: \(self.keepLineBreaks ? "yes" : "no")")
        
        let textResult: String = results.map { result in
            if let observation = result as? VNRecognizedTextObservation {
                return observation.topCandidates(1).map { text in
                    return text.string
                }.joined(separator: self.keepLineBreaks ? "\n" : " ")

            }

            return ""
        }.joined(separator: self.keepLineBreaks ? "\n" : " ")

        self.delegate?.resultsAvailable(text: textResult, error: nil)
    }

    private func setupWindow(windowRect: NSRect) -> NSWindow {
        print("setupWindow: \(windowRect)")
        if let window = self.globalWindow,
            window.frame == windowRect {
            return window
        } else if let window = self.globalWindow {
            window.close()
            self.globalWindow = nil
        }

        let window = SelectionWindow(frame: windowRect, selectionDelegate: self, debug: self.debug)
        window.becomeKey()
        NSApplication.shared.activate(ignoringOtherApps: true)

        return window
    }

    private func showPreviewWindow(image: NSImage) {
        if self.showPreview {
            self.previewWindow = PreviewWindow(image: image)
        }
    }

    public func processResults(_ rect: CGRect) {
        if let windowID = self.globalWindow?.windowNumber,
            let screen = self.getScreenWithMouse(), rect.width > 5 && rect.height > 5 {
            self.delegate?.processingResults()
            var correctedRect = rect

            correctedRect.origin.y = screen.frame.height - rect.origin.y - rect.height;

            if (screen.frame.origin.y < 0) {
                correctedRect.origin.y = correctedRect.origin.y - screen.frame.origin.y
            }


            correctedRect.origin.x = correctedRect.origin.x + screen.frame.origin.x
            let cgScreenshot = CGWindowListCreateImage(correctedRect, .optionOnScreenBelowWindow, CGWindowID(windowID), .bestResolution)


            let rep = NSBitmapImageRep(cgImage: cgScreenshot!)
            let image = NSImage()
            image.addRepresentation(rep)

            self.showPreviewWindow(image: image)

            let requests = [self.getTextRecognitionRequest()]
            let imageRequestHandler = VNImageRequestHandler(cgImage: cgScreenshot!, orientation: .up, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try imageRequestHandler.perform(requests)
                } catch let error {
                    print("Error: \(error)")
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.hidePreviewWindow()
            }
        }

        self.globalWindow = nil
    }


    private func getScreenWithMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let screenWithMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })

        return screenWithMouse
    }

}
