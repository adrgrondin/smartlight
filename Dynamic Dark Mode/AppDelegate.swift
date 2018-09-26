//
//  AppDelegate.swift
//  Dynamic Dark Mode
//
//  Created by Adrien Grondin on 25/09/2018.
//  Copyright © 2018 Adrien Grondin. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    private let popover = NSPopover()
    private var eventMonitor: EventMonitor?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        // Put the app's windows on top.
        NSApp.activate(ignoringOtherApps: true)
        
        // Activate the Dynamic Dark Mode.
        let userDefaults = UserDefaults.standard
        let isDynamicDarkModeActivated = userDefaults.bool(forKey: "com.adriengrondin.Dynamic-Dark-Mode.isDynamicDarkModeActivated")
        
        if isDynamicDarkModeActivated {
            DynamicDarkModeManager.shared.startDynamicDarkMode()
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
}

