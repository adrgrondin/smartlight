//
//  ViewController.swift
//  Dynamic Dark Mode
//
//  Created by Adrien Grondin on 25/09/2018.
//  Copyright © 2018 Adrien Grondin. All rights reserved.
//

import Cocoa

protocol PreferencesViewControllerDelegate: class {
    func didCloseView()
}

class PreferencesViewController: NSViewController {
    
    weak var delegate: PreferencesViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear() {
        delegate?.didCloseView()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

