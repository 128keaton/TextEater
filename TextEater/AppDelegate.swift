//
//  AppDelegate.swift
//  TextEater
//
//  Created by Keaton Burleson on 5/5/21.
//

import Cocoa
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
