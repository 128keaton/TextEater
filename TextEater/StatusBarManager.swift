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

    override init() {
        super.init()

        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]

        center.delegate = self
        center.requestAuthorization(options: options) { (granted, error) in
            self.canNotify = granted

            if granted {
                let processResultCategory = UNNotificationCategory(identifier: "processResult", actions: [], intentIdentifiers: [], options: [])
                UNUserNotificationCenter.current().setNotificationCategories([processResultCategory])
            }

            if let error = error {
                print(error)
            }
        }
        
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
        }
        
        completionHandler()
    }
}
