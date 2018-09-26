//
//  DynamicDarkModeManager.swift
//  Dynamic Dark Mode
//
//  Created by Adrien Grondin on 26/09/2018.
//  Copyright © 2018 Adrien Grondin. All rights reserved.
//

import Foundation
import CoreLocation

final class DynamicDarkModeManager: NSObject {
    
    static let shared = DynamicDarkModeManager()
    
    private override init() { }
    
    private let locationManager = CLLocationManager()
    private var timer: Timer?
    private var locationTimer: Timer?
    
    private var coordinate: CLLocationCoordinate2D?
    
    // MARK: - Functions
    
    @objc func startDynamicDarkMode() {
        print("Start getting location")
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            print("Not Determined")
            break
            
        case .restricted, .denied:
            // Disable location features
            print("Restrited/Denied")
            break
            
        case .authorizedWhenInUse:
            // Enable basic location features
            print("Authorized When In Use")
            break
            
        case .authorizedAlways:
            // Enable any of your app's location features
            print("Authorized Always")
            break
        }
    
        //        let authorizationStatus = CLLocationManager.authorizationStatus()
        //        if authorizationStatus != .authorizedAlways {
        //            // User has not authorized access to location information.
        //            return
        //        }
        
        // Do not start services that aren't available.
        if !CLLocationManager.locationServicesEnabled() {
            // Location services is not available.
            return
        }
        
        // Configure and start the service.
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.delegate = self
        locationManager.requestLocation()
    }
    
    func stopDynamicMode() {
        stopTimers()
    }
    
    @objc private func toggleAppereanceMode() {
        guard let coordinate = self.coordinate else { return }
        let solar = Solar(for: Date(), coordinate: coordinate)
        var appleScript: String = ""
        
        guard let isDaytime = solar?.isDaytime else { return }
        
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
        self.timer = Timer(timeInterval: 10, target: self, selector: #selector(toggleAppereanceMode), userInfo: nil, repeats: true)
        self.locationTimer = Timer(timeInterval: 3600, target: self, selector: #selector(startDynamicDarkMode), userInfo: nil, repeats: true)
        
        // Add the timer to the RunLoop.
        guard let timer = self.timer, let locationTimer = self.locationTimer else { return }
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
        RunLoop.current.add(locationTimer, forMode: RunLoop.Mode.common)
    }
    
    private func stopTimers() {
        guard let timer = self.timer , let locationTimer = self.locationTimer else { return }
        timer.invalidate()
        locationTimer.invalidate()
    }
}

extension DynamicDarkModeManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,  didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last!
        
        // Do something with the location.
        print(lastLocation.coordinate.latitude)
        self.coordinate = lastLocation.coordinate
        
        startTimers()
        toggleAppereanceMode()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .denied {
            // Location updates are not authorized.
            return
        }
        // Notify the user of any errors.
    }
}
