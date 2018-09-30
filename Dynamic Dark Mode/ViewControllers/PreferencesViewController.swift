//
//  ViewController.swift
//  Dynamic Dark Mode
//
//  Created by Adrien Grondin on 25/09/2018.
//  Copyright © 2018 Adrien Grondin. All rights reserved.
//

import Cocoa
import ServiceManagement

protocol PreferencesViewControllerDelegate: class {
    func didCloseView()
}

class PreferencesViewController: NSViewController {
    
    @IBOutlet weak var launchOnStartupButton: NSButton!
    
    weak var delegate: PreferencesViewControllerDelegate?
    let userDefaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let launchOnStartup = userDefaults.bool(forKey: "com.adriengrondin.Dynamic-Dark-Mode.launchOnStartup")
        
        if launchOnStartup {
            launchOnStartupButton.state = .on
        } else {
            launchOnStartupButton.state = .off
        }
    }
    
    override func viewDidDisappear() {
        delegate?.didCloseView()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func launchOnStartupPressed(_ sender: NSButton) {
        switch sender.state {
        case .on:
            SMLoginItemSetEnabled("com.adriengrondin.Dynamic-Dark-Mode-Launch-Helper" as CFString, true)
            userDefaults.set(true, forKey: "com.adriengrondin.Dynamic-Dark-Mode.launchOnStartup")
        case .off:
            SMLoginItemSetEnabled("com.adriengrondin.Dynamic-Dark-Mode-Launch-Helper" as CFString, false)
            userDefaults.set(false, forKey: "com.adriengrondin.Dynamic-Dark-Mode.launchOnStartup")
        default:
            break
        }
    }
}

