//
//  MenuBarViewController.swift
//  Dynamic Dark Mode
//
//  Created by Adrien Grondin on 25/09/2018.
//  Copyright © 2018 Adrien Grondin. All rights reserved.
//

import Cocoa

final class MenuBarViewController: NSViewController {
    
    private var preferencesWindowController: NSWindowController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    // MARK: - @IBActions
    
    @IBAction func toggleDarkMode(_ sender: NSButton) {
        //  Get the Authorization status for "System Events".
        var status: OSStatus?
        var targetAppEventDescriptor: NSAppleEventDescriptor?
        
        targetAppEventDescriptor = NSAppleEventDescriptor(bundleIdentifier: "com.apple.systemevents")
        
        status = AEDeterminePermissionToAutomateTarget(targetAppEventDescriptor?.aeDesc, typeWildCard, typeWildCard, true)
        
        // Show an alert if not authorized.
        if let status = status, status == -1743 {
            let resp = showAuthorizationAlert()
            if resp == .alertFirstButtonReturn {
                if let aString = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                    NSWorkspace.shared.open(aString)
                }
            }
            
            return
        }

        // Script to toggle the appearance.
        let myAppleScript = """
        tell application \"System Events\"

            tell appearance preferences

                set dark mode to not dark mode

            end tell

        end tell
        """
        
        // Run the script and also ask for authorization.
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: myAppleScript) {
            if let outputString = scriptObject.executeAndReturnError(&error).stringValue {
                print(outputString)
            } else if (error != nil) {
                print("error: ", error!)
            }
        }
    }
    
    @IBAction func openPreferences(_ sender: NSButton) {
        if let preferencesWindownController = self.preferencesWindowController {
            preferencesWindownController.window?.makeKeyAndOrderFront(sender)
            
            return
        }
        
        // Load the main window with the preferences view controller.
        let storyBoard = NSStoryboard(name: "Main", bundle: nil) as NSStoryboard
        
        let preferencesWindowController = storyBoard.instantiateController(withIdentifier: "MainWindowController") as? NSWindowController
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
        
        // Store the preferences window controller to prevent multiple instances.
        self.preferencesWindowController = preferencesWindowController
    }
    
    @IBAction func quit(_ sender: NSButton) {
        NSApplication.shared.terminate(sender)
    }
    
    @IBAction func ToogleDynamicDarkMode(_ sender: NSButton) {
 
    }
    // MARK: - Functions
    
    func showAuthorizationAlert() -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = "\"Dynamic Dark Mode\" does not have access to \"System Events\""
        alert.informativeText = "Access to \"System Events\" is needed to allow the app to change the appearance. Please allow access in System Preferences and restart the app."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences...")
        alert.addButton(withTitle: "Cancel")
        
        return alert.runModal()
    }
}

extension MenuBarViewController {
    // MARK: Storyboard instantiation
    static func instantiateViewController() -> MenuBarViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        guard let menuBarViewController = storyboard.instantiateController(withIdentifier: "MenuBarViewController") as? MenuBarViewController else {
            fatalError("Can't instantiate MenuBarViewController.")
        }
        return menuBarViewController
    }
}
