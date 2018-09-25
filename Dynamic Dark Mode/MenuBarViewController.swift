//
//  MenuBarViewController.swift
//  Dynamic Dark Mode
//
//  Created by Adrien Grondin on 25/09/2018.
//  Copyright © 2018 Adrien Grondin. All rights reserved.
//

import Cocoa

class MenuBarViewController: NSViewController {
    
    var preferencesWindowController: NSWindowController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func toggleDarkMode(_ sender: NSButton) {
        let myAppleScript = """
        tell application \"System Events\"

            tell appearance preferences

                set dark mode to not dark mode

            end tell

        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: myAppleScript) {
            if let outputString = scriptObject.executeAndReturnError(&error).stringValue {
                print(outputString)
            } else if (error != nil) {
                print("error: ", error!)
            }
        }
        
        print("Toggled")
    }
    
    @IBAction func openPreferences(_ sender: NSButton) {
        if let preferencesWindownController = preferencesWindowController {
            preferencesWindownController.window?.makeKeyAndOrderFront(sender)
            
            return
        }
        
        // Load the main window with the preferences view controller.
        let storyBoard = NSStoryboard(name: "Main", bundle: nil) as NSStoryboard
        
        let windowController = storyBoard.instantiateController(withIdentifier: "MainWindowController") as? NSWindowController
        windowController?.window?.makeKeyAndOrderFront(nil)
        
        preferencesWindowController = windowController
    }
    
    @IBAction func quit(_ sender: NSButton) {
        NSApplication.shared.terminate(sender)
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
