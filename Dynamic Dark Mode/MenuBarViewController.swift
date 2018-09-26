//
//  MenuBarViewController.swift
//  Dynamic Dark Mode
//
//  Created by Adrien Grondin on 25/09/2018.
//  Copyright © 2018 Adrien Grondin. All rights reserved.
//

import Cocoa

final class MenuBarViewController: NSViewController {
    
    @IBOutlet weak var dynamicDarkModeButton: NSButton!
    @IBOutlet weak var quickToggleButton: NSButton!
    
    private var preferencesWindowController: NSWindowController?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let userDefaults = UserDefaults.standard
        let isDynamicDarkModChecked = userDefaults.bool(forKey: "com.adriengrondin.Dynamic-Dark-Mode.isDynamicDarkModeActivated")
        
        if isDynamicDarkModChecked {
            dynamicDarkModeButton.state = .on
            quickToggleButton.isEnabled = false
            
        } else {
            dynamicDarkModeButton.state = .off
            quickToggleButton.isEnabled = true
        }
    }
    
    // MARK: - @IBActions
    
    @IBAction func quickToggleButtonPressed(_ sender: NSButton) {
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
    
    @IBAction func preferencesButtonPressed(_ sender: NSButton) {
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
    
    @IBAction func quitButtonPressed(_ sender: NSButton) {
        NSApplication.shared.terminate(sender)
    }
    
    @IBAction func toggleDynamicDarkModePressed(_ sender: NSButton) {
        let userDefaults = UserDefaults.standard
        
        switch sender.state {
        case .on:
            quickToggleButton.isEnabled = false
            userDefaults.set(true, forKey: "com.adriengrondin.Dynamic-Dark-Mode.isDynamicDarkModeActivated")
            
            print("Dynamic Dark Mode ON")
            DynamicDarkModeManager.shared.startDynamicMode()

        case .off:
            quickToggleButton.isEnabled = true
            userDefaults.set(false, forKey: "com.adriengrondin.Dynamic-Dark-Mode.isDynamicDarkModeActivated")
            
            print("Dynamic Dark Mode OFF")
            DynamicDarkModeManager.shared.stopDynamicMode()

        default:
            break
        }
    }
    
    // MARK: - Functions
    
    private func showAuthorizationAlert() -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = "\"Dynamic Dark Mode\" does not have access to \"System Events\""
        alert.informativeText = "Access to \"System Events\" is needed to allow the app to change the appearance. Please allow access in System Preferences and restart the app."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences...")
        alert.addButton(withTitle: "Cancel")
        
        return alert.runModal()
    }
}

// MARK: - Storyboard instantiation

extension MenuBarViewController {
    
    static func instantiateViewController() -> MenuBarViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)

        guard let menuBarViewController = storyboard.instantiateController(withIdentifier: "MenuBarViewController") as? MenuBarViewController else {
            fatalError("Can't instantiate MenuBarViewController from Main.storyboard.")
        }
        return menuBarViewController
    }
}
