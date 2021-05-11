//
//  StatusBarManager.swift
//  TextEater
//
//  Created by Keaton Burleson on 5/6/21.
//

import Foundation
import AppKit
import GlobalSelection
import UserNotifications
import AVFoundation

class StatusBarManager: NSObject {

    @IBOutlet weak var menu: NSMenu?
    @IBOutlet var appDelegate: AppDelegate?
    @IBOutlet weak var keepLineBreaksItem: NSMenuItem?
    @IBOutlet weak var clearHistoryItem: NSMenuItem?
    @IBOutlet weak var continuousItem: NSMenuItem?

    var statusItem: NSStatusItem?
    var selectionHandler: SelectionHandler?
    var progressIndicator: NSProgressIndicator?

    private let history = History.shared
    private let delegate = AppDelegate()
    private let defaultStatusImage = NSImage(named: "NSAddTemplate")
    private let loadingStatusImage = NSImage(named: "EmptyIconImage")
    
    private var canNotify: Bool = false
    private var shouldNotify: Bool = true
    private var useContinuousClipboard: Bool = false
    private var synth: AVSpeechSynthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()

        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]

        center.delegate = self
        center.requestAuthorization(options: options) { (granted, error) in
            self.canNotify = granted

            if granted {
                let readAloudChoice = UNNotificationAction(identifier: "readAloud", title: "Read Aloud", options: [])
                let processResultCategory = UNNotificationCategory(identifier: "processResult", actions: [readAloudChoice], intentIdentifiers: [], options: [])
                UNUserNotificationCenter.current().setNotificationCategories([processResultCategory])
            }

            if let error = error {
                print(error)
            }
        }
        
        self.synth.delegate = self
        self.appDelegate?.statusBarManager = self
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        if UserDefaults.standard.value(forKey: "notify") == nil {
            UserDefaults.standard.set(true, forKey: "notify")
        }
        
        if UserDefaults.standard.value(forKey: "keepLineBreaks") == nil {
            UserDefaults.standard.set(false, forKey: "keepLineBreaks")
        }

        if UserDefaults.standard.value(forKey: "useContinuousClipboard") == nil {
            UserDefaults.standard.set(false, forKey: "useContinuousClipboard")
        }

        let useFastRecognition = UserDefaults.standard.bool(forKey: "fast")
        let debug = UserDefaults.standard.bool(forKey: "debug")
        let keepLineBreaks = UserDefaults.standard.bool(forKey: "keepLineBreaks")

        self.shouldNotify = UserDefaults.standard.bool(forKey: "notify")
        self.useContinuousClipboard = UserDefaults.standard.bool(forKey: "useContinuousClipboard")
        
        self.selectionHandler = SelectionHandler(delegate: self)
        self.selectionHandler?.recognizeFast = useFastRecognition
        self.selectionHandler?.debug = debug
        self.selectionHandler?.keepLineBreaks = keepLineBreaks

        self.continuousItem?.state = self.useContinuousClipboard ? .on : .off

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = self.defaultStatusImage

        if let menu = menu {
            statusItem?.menu = menu
        }
        
        if let keepLineBreaksItem = self.keepLineBreaksItem {
            keepLineBreaksItem.state = keepLineBreaks ? .on : .off
        }

        if let button = self.statusItem?.button {
            let frame = NSRect(x: 6, y: 2, width: 18, height: 18)

            self.progressIndicator = NSProgressIndicator(frame: frame)
            self.progressIndicator?.style = .spinning
            self.progressIndicator?.isIndeterminate = true
            self.progressIndicator?.alphaValue = 0.0
            self.progressIndicator?.usesThreadedAnimation = true
            self.progressIndicator?.toolTip = "Processing.."

            button.addSubview(self.progressIndicator!)
        }
    }

    @IBAction func showPreferences(sender: NSMenuItem) {
        PreferencesViewController.present(withSelectionHandler: self.selectionHandler, canNotify: self.canNotify)
    }

    @IBAction func captureToggle(sender: Any) {
        self.startCapturing()
    }

    @IBAction func keepLineBreaksToggle(sender: NSMenuItem) {
        sender.state = sender.state == .on ? .off : .on
        let keepLineBreaks = sender.state == .on
        
        UserDefaults.standard.set(keepLineBreaks, forKey: "keepLineBreaks")
        self.selectionHandler?.keepLineBreaks = keepLineBreaks
        print("Keep line breaks: \(keepLineBreaks ? "yes" : "no")")
    }
    
    @IBAction func useContinuousClipboardToggle(sender: NSMenuItem) {
        sender.state = sender.state == .on ? .off : .on
        let useContinuousClipboard = sender.state == .on
        
        UserDefaults.standard.set(useContinuousClipboard, forKey: "useContinuousClipboard")
        print("Use continuous clipboard: \(useContinuousClipboard ? "yes" : "no")")
        
        self.history.clear()
        self.useContinuousClipboard = useContinuousClipboard
        self.clearHistoryItem?.isEnabled = false
    }
    
    @IBAction func clearContinuousClipboard(sender: NSMenuItem) {
        self.history.clear()
        sender.isEnabled = false
    }
    
    @IBAction func openAboutPanel(sender: NSMenuItem) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(sender)
    }
    
    public func startCapturing() {
        self.selectionHandler?.startListening()
    }
    
    func copyWithZone(zone: NSZone) {
        self.selectionHandler?.startListening()
    }
    
    @objc func stopSpeaking() {
        self.synth.stopSpeaking(at: .immediate)
        self.removeStopSpeakingMenuItem()
    }

    private func showProcessedNotification(text: String?, error: String?) {
        if !self.shouldNotify || !self.canNotify {
            print("Should notify: \(self.shouldNotify ? "yes" : "no")")
            print("Can notify: \(self.canNotify ? "yes" : "no")")
            return
        }

        let notificationContent = UNMutableNotificationContent()

        notificationContent.title = error == nil ? "Text Processed" : "Error"
        notificationContent.categoryIdentifier = "processResult"

        if let error = error {
            notificationContent.subtitle = "There was an error processing the text"
            notificationContent.body = error
        } else if let text = text {
            notificationContent.body = text
            notificationContent.userInfo["text"] = text
        }

        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: "textItem", content: notificationContent, trigger: notificationTrigger)

        UNUserNotificationCenter.current().add(request) { (err) in
            if let error = err {
                print("Could not add notification: \(error.localizedDescription)")
            }
        }
    }

    private func showLoadingIndicator() {
        DispatchQueue.main.async {
            if let button = self.statusItem?.button,
                let progressIndicator = self.progressIndicator {

                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.25
                    context.timingFunction = .easeOut
                    button.animator().alphaValue = 0.0
                } completionHandler: {
                    button.isEnabled = false
                    button.image = self.loadingStatusImage
                    progressIndicator.startAnimation(self)
                    progressIndicator.alphaValue = 1.0

                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 0.25
                        context.timingFunction = .easeIn
                        button.animator().alphaValue = 1.0
                    }
                }

            }
        }
    }

    private func hideLoadingIndicator() {
        DispatchQueue.main.async {
            if let button = self.statusItem?.button,
                let progressIndicator = self.progressIndicator {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.25
                    context.timingFunction = .easeOut
                    button.animator().alphaValue = 0.0
                } completionHandler: {
                    button.isEnabled = true
                    button.image = self.defaultStatusImage
                    progressIndicator.stopAnimation(self)
                    progressIndicator.alphaValue = 0.0

                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 0.25
                        context.timingFunction = .easeIn
                        button.animator().alphaValue = 1.0
                    }
                }
            }
        }
    }
    
    private func showStopSpeakingMenuItem() {
        DispatchQueue.main.async {
            let stopSpeakingItem = NSMenuItem(title: "Stop Speaking", action: #selector(self.stopSpeaking), keyEquivalent: "")
            stopSpeakingItem.target = self
            stopSpeakingItem.isEnabled = true
            
            if let menu = self.menu,
               let captureItem = menu.item(withTitle: "Capture"),
               let index = menu.items.lastIndex(of: captureItem) {
                menu.insertItem(stopSpeakingItem, at: index)
            }
        }
    }
    
    private func removeStopSpeakingMenuItem() {
        DispatchQueue.main.async {
            if let menu = self.menu,
               let stopSpeakingItem = menu.item(withTitle: "Stop Speaking") {
                menu.removeItem(stopSpeakingItem)
            }
        }
    }
    
    private func readAloud(_ utteranceString: String) {
        let utterance = AVSpeechUtterance(string: utteranceString)
        utterance.voice = AVSpeechSynthesisVoice(language: self.selectionHandler?.getLocale())
        utterance.rate = 0.1

        self.synth.speak(utterance)
    }
}

extension StatusBarManager: SelectionHandlerDelegate {
    func resultsAvailable(text: String?, error: String?) {
        if let text = text {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            
            if self.useContinuousClipboard {
                self.history.add(text)
                self.clearHistoryItem?.isEnabled = true
                
                pasteboard.setString(self.history.getString(), forType: .string)
            } else {
                pasteboard.setString(text, forType: .string)
            }

            print("Text Result: \(text)")
        }

        self.showProcessedNotification(text: text, error: error)

        if !self.selectionHandler!.recognizeFast {
            self.hideLoadingIndicator()
        }
    }

    func processingResults() {
        NSApp.deactivate()

        if !self.selectionHandler!.recognizeFast {
            self.showLoadingIndicator()
        }
    }
}

extension StatusBarManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let text = response.notification.request.content.userInfo["text"] as? String {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)

            print("Text Copied: \(text)")
            
            if response.actionIdentifier == "readAloud" {
                self.readAloud(text)
            }
        }
        
        completionHandler()
    }
}


extension StatusBarManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        self.showStopSpeakingMenuItem()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.removeStopSpeakingMenuItem()
    }
}
