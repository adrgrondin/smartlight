//
//  AppDelegate.swift
//  Dynamic Dark Mode
//
//  Created by Adrien Grondin on 25/09/2018.
//  Copyright © 2018 Adrien Grondin. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    private let popover = NSPopover()
    private var eventMonitor: EventMonitor?
    private let userDefaults = UserDefaults.standard

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        // Manage the launch on startup.
        let launcherAppId = "com.adriengrondin.Dynamic-Dark-Mode-Launch-Helper"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty
        
        // Turn on launch on startup the first time the app is launched and disable Dynamic Dark Mode.
        if !isAppAlreadyLaunchedOnce() {
            SMLoginItemSetEnabled(launcherAppId as CFString, true)
            userDefaults.setValue(true, forKey: "com.adriengrondin.Dynamic-Dark-Mode.launchOnStartup")
            userDefaults.set(false, forKey: "com.adriengrondin.Dynamic-Dark-Mode.isDynamicDarkModeActivated")
        }
        
        if isRunning {
            DistributedNotificationCenter.default().post(name: .killLauncher, object: Bundle.main.bundleIdentifier!)
        }
        
        // Put the app's windows on top.
        NSApp.activate(ignoringOtherApps: true)
        
        // Activate the Dynamic Dark Mode.
        let isDynamicDarkModeActivated = userDefaults.bool(forKey: "com.adriengrondin.Dynamic-Dark-Mode.isDynamicDarkModeActivated")
        
        if isDynamicDarkModeActivated {
            DynamicDarkModeScheduler.shared.startDynamicDarkMode()
        }
        
        // Add image and action to the menu bar button.
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
            button.action = #selector(togglePopover(_:))
        }
        
        popover.contentViewController = MenuBarViewController.instantiateViewController()
        
        // Create an event monitor to hide the popover when a click occurs outside.
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(sender: event)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // MARK: - Functions
    
    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }
    
    private func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
        
        eventMonitor?.start()
    }
    
    private func closePopover(sender: Any?) {
        popover.performClose(sender)
        
        eventMonitor?.stop()
    }
    
    private func isAppAlreadyLaunchedOnce() -> Bool {
        if let _ = userDefaults.string(forKey: "com.adriengrondin.Dynamic-Dark-Mode.isAppAlreadyLaunchedOnce"){
            return true
        } else {
            userDefaults.set(true, forKey: "com.adriengrondin.Dynamic-Dark-Mode.isAppAlreadyLaunchedOnce")
            return false
        }
    }
}

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}
