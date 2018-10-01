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
    @IBOutlet weak var preferencesButton: NSButton!
    
    private var isPreferencesWindowShowed = false
    private let userDefaults = UserDefaults.standard

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let isDynamicDarkModActivated = userDefaults.bool(forKey: "com.adriengrondin.Dynamic-Dark-Mode.isDynamicDarkModeActivated")
        
        if isDynamicDarkModActivated {
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
            let alert = showSystemEventsAuthorizationAlert()
            if alert == .alertFirstButtonReturn {
                if let stringURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                    NSWorkspace.shared.open(stringURL)
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
        if !isPreferencesWindowShowed {
            // Load the main window with the preferences view controller.
            let storyBoard = NSStoryboard(name: "Main", bundle: nil) as NSStoryboard
            
            let preferencesWindowController = storyBoard.instantiateController(withIdentifier: "MainWindowController") as? NSWindowController
            preferencesWindowController?.window?.level = .modalPanel
            preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
            
            let preferencesViewController = preferencesWindowController?.window?.contentViewController as! PreferencesViewController
            preferencesViewController.delegate = self
            
            isPreferencesWindowShowed = true
            preferencesButton.isEnabled = false
        }
    }
    
    @IBAction func quitButtonPressed(_ sender: NSButton) {
        NSApplication.shared.terminate(sender)
    }
    
    @IBAction func toggleDynamicDarkModePressed(_ sender: NSButton) {
        switch sender.state {
        case .on:
            quickToggleButton.isEnabled = false
            userDefaults.set(true, forKey: "com.adriengrondin.Dynamic-Dark-Mode.isDynamicDarkModeActivated")
            
            print("Dynamic Dark Mode ON")
            DynamicDarkModeScheduler.shared.startDynamicDarkMode()

        case .off:
            quickToggleButton.isEnabled = true
            userDefaults.set(false, forKey: "com.adriengrondin.Dynamic-Dark-Mode.isDynamicDarkModeActivated")
            
            print("Dynamic Dark Mode OFF")
            DynamicDarkModeScheduler.shared.stopDynamicDarkMode()

        default:
            break
        }
    }
    
    // MARK: - Alerts
    
    private func showSystemEventsAuthorizationAlert() -> NSApplication.ModalResponse {
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

// MARK: - PreferencesViewControllerDelegate

extension MenuBarViewController: PreferencesViewControllerDelegate {
    
    func didCloseView() {
        isPreferencesWindowShowed = false
        preferencesButton.isEnabled = true
    }
}
