//
//  AppDelegate.swift
//  Dynamic Dark Mode Launch Helper
//
//  Created by Adrien Grondin on 30/09/2018.
//  Copyright © 2018 Adrien Grondin. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        // Check if the main app is running and close the launch helper.
        let mainAppIdentifier = "com.adriengrondin.Dynamic-Dark-Mode"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == mainAppIdentifier }.isEmpty
        
        if !isRunning {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.terminate), name: .killLauncher, object: mainAppIdentifier)
            
            var path = Bundle.main.bundlePath as NSString
            
            for _ in 1...4 {
                path = path.deletingLastPathComponent as NSString
            }
            
            NSWorkspace.shared.launchApplication(path as String)
        }
        else {
            self.terminate()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // MARK: - Functions
    
    @objc func terminate() {
        NSApp.terminate(nil)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}
