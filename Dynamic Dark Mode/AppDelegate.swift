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

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    let popover = NSPopover()
    var eventMonitor: EventMonitor?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        // Put the app's window on top.
        NSApp.activate(ignoringOtherApps: true)
        
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
            button.action = #selector(togglePopover(_:))
        }
        
        popover.contentViewController = MenuBarViewController.instantiateViewController()
        
        //constructMenu()
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(sender: event)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func ShowPreferences(_ sender: Any?) {
        let storyBoard = NSStoryboard(name: "Main", bundle: nil) as NSStoryboard
        
        let windowController = storyBoard.instantiateController(withIdentifier: "MainWindowController") as? NSWindowController
        windowController?.window?.makeKeyAndOrderFront(nil)
    }
    
    func constructMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(AppDelegate.ShowPreferences(_:)), keyEquivalent: "P"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Dynamic Dark Mode", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }
    
    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
        
        eventMonitor?.start()
    }
    
    func closePopover(sender: Any?) {
        popover.performClose(sender)
        
        eventMonitor?.stop()
    }
}

