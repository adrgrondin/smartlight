//
//  DynamicDarkModeManager.swift
//  Dynamic Dark Mode
//
//  Created by Adrien Grondin on 26/09/2018.
//  Copyright © 2018 Adrien Grondin. All rights reserved.
//

import Foundation
import Cocoa
import CoreLocation

final class DynamicDarkModeScheduler: NSObject {
    
    static let shared = DynamicDarkModeScheduler()
    
    private override init() { }
    
    private let locationManager = CLLocationManager()
    private var timer: Timer?
    private var locationTimer: Timer?
    private var activity: NSBackgroundActivityScheduler?
    
    private var coordinate: CLLocationCoordinate2D?
    
    // MARK: - Functions
    
    func startDynamicDarkMode() {
        updateLocation()
    }
    
    func stopDynamicDarkMode() {
        stopTimers()
    }
    
    @objc private func updateLocation() {
        print("Update location")
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request always authorization initially.
            break
            
        case .restricted, .denied:
            // Disable location features
            print("Restrited/Denied")
            
            let alert = showLocationServicesAuthorizationAlert()
            if alert == .alertFirstButtonReturn {
                if let stringURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
                    NSWorkspace.shared.open(stringURL)
                }
            }
            
            return
        
        case .authorizedAlways:
            // Enable any of your app's location features
            print("Authorized Always")
            break
        }
        
        // Do not start services that aren't available.
        if !CLLocationManager.locationServicesEnabled() {
            // Location services is not available.
            let alert = showLocationServicesAuthorizationAlert()
            if alert == .alertFirstButtonReturn {
                if let stringURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
                    NSWorkspace.shared.open(stringURL)
                }
            }
            return
        }
        
        // Configure and start the service.
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.delegate = self
        locationManager.requestLocation()
    }
    
    @objc private func toggleAppearanceMode() {
        guard let coordinate = self.coordinate else { return }
        
        let twilightRawValue = UserDefaults.standard.integer(forKey: "com.adriengrondin.Dynamic-Dark-Mode.twilightType")
        
        guard let twilight = Solar.Twilight(rawValue: twilightRawValue) else { return }
        
        let solar = Solar(for: Date(), coordinate: coordinate, twilight: twilight)
        
        guard let isDaytime = solar?.isDaytime else { return }
        
        var appleScript: String = ""
        
        if isDaytime {
            print("Toogle Light Mode (daytime)")

            // Light Mode
            appleScript = """
            tell application id "com.apple.systemevents"
                tell appearance preferences
                    if dark mode is true then
                        set dark mode to false
                    end if
                end tell
            end tell
            """
        } else {
            print("Toggle Dark Mode (night time)")

            // Dark Mode
            appleScript = """
            tell application id "com.apple.systemevents"
                tell appearance preferences
                    if dark mode is false then
                        set dark mode to true
                    end if
                end tell
            end tell
            """
        }
        
        // Run the script and also ask for authorization.
        var error: NSDictionary?
        
        if let scriptObject = NSAppleScript(source: appleScript) {
            if let outputString = scriptObject.executeAndReturnError(&error).stringValue {
                print(outputString)
            } else if (error != nil) {
                print("error: ", error!)
            }
        }
    }
    
    private func startTimers() {
        print("Start timers")
        
        // Ensure that no timers are already running.
        guard self.timer == nil, self.locationTimer == nil else { return }
        
        // Create the timers.
        self.timer = Timer(timeInterval: 300, target: self, selector: #selector(toggleAppearanceMode), userInfo: nil, repeats: true)
        self.timer?.tolerance = 120
        self.locationTimer = Timer(timeInterval: 3600, target: self, selector: #selector(updateLocation), userInfo: nil, repeats: true)
        self.locationTimer?.tolerance = 3600
        
        // Add the timer to the RunLoop.
        guard let timer = self.timer, let locationTimer = self.locationTimer else { return }
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
        RunLoop.current.add(locationTimer, forMode: RunLoop.Mode.common)
        
        
        /*
        guard self.timer == nil else { return }
        self.timer = Timer(timeInterval: 5, target: self, selector: #selector(toggleAppearanceMode), userInfo: nil, repeats: true)
        guard let timer = self.timer else { return }
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
        */
        
        /*
        guard self.activity == nil else { return }
        
        activity = NSBackgroundActivityScheduler(identifier: "com.adriengrondin.Dynamic-Dark-Mode.DynamicDarkModeTimer")
        activity?.repeats = true
        activity?.interval = 5
        activity?.qualityOfService = .userInitiated
        //activity?.tolerance = 5
        
        activity?.schedule() { (completion: NSBackgroundActivityScheduler.CompletionHandler) in
            // Perform the activity
            
            self.toggleAppearanceMode()
            
            completion(NSBackgroundActivityScheduler.Result.finished)
        }
        */
    }
    
    private func stopTimers() {
        guard let timer = self.timer , let locationTimer = self.locationTimer else { return }
        timer.invalidate()
        locationTimer.invalidate()
    }
    
    // MARK: - Alerts
    
    private func showLocationServicesAuthorizationAlert() -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = "\"Dynamic Dark Mode\" does not have access to \"Location Services\""
        alert.informativeText = "Access to \"Location Services\" is needed for the Dynamic Dark Mode functionnality. Please allow access in System Preferences."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences...")
        alert.addButton(withTitle: "Cancel")
        
        return alert.runModal()
    }
    
    private func showLocationServicesDisabledAlert() -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = "\"Location Services\" is disabled."
        alert.informativeText = "\"Location Services\" must be enabled for the Dynamic Dark Mode functionnality. Please enable it in System Preferences."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences...")
        alert.addButton(withTitle: "Cancel")
        
        return alert.runModal()
    }
}

// MARK: - CLLocationManagerDelegate

extension DynamicDarkModeScheduler: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,  didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.first!
        
        // Do something with the location.
        print(lastLocation.coordinate.latitude)
        self.coordinate = lastLocation.coordinate
        
        startTimers()
        toggleAppearanceMode()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .denied {
            // Location updates are not authorized.
            return
        }
        // Notify the user of any errors.
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            updateLocation()
            break
        
        case .restricted, .denied:
            let alert = showLocationServicesAuthorizationAlert()
            if alert == .alertFirstButtonReturn {
                if let stringURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
                    NSWorkspace.shared.open(stringURL)
                }
            }
            return
        
        case .authorizedAlways:
            updateLocation()
            break
        }
    }
}
