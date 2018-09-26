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
    
    @objc func startDynamicMode() {
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
    
    @objc private func toggleAppereanceMode(_ sender: Any?) {
        print("Toggle appearance mode")
        guard let coordinate = self.coordinate else { return }
        let solar = Solar(for: Date(), coordinate: coordinate)
        
        guard let isDaytime = solar?.isDaytime else { return }
        
        if isDaytime {
            print("Is daytime")

            // Light Mode
            let dayScript = """
                tell application id "com.apple.systemevents"
                tell appearance preferences
                    if dark mode is true then
                        set dark mode to false
                    end if
                end tell
            end tell
            """
            
            // Run the script and also ask for authorization.
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: dayScript) {
                if let outputString = scriptObject.executeAndReturnError(&error).stringValue {
                    print(outputString)
                } else if (error != nil) {
                    print("error: ", error!)
                }
            }
        } else {
            print("Is night time")

            // Dark Mode
            let nightScript = """
                tell application id "com.apple.systemevents"
                tell appearance preferences
                    if dark mode is false then
                        set dark mode to true
                    end if
                end tell
            end tell
            """
            
            // Run the script and also ask for authorization.
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: nightScript) {
                if let outputString = scriptObject.executeAndReturnError(&error).stringValue {
                    print(outputString)
                } else if (error != nil) {
                    print("error: ", error!)
                }
            }
        }
    }
    
    private func startTimer() {
        print("Start timer")

        // Ensure that no timer is already running.
        guard self.timer == nil else { return }
        
        // Create the timer.
        //self.timer = Timer(timeInterval: 600, target: self, selector: #selector(toggleAppereanceMode(_:)), userInfo: nil, repeats: true)
        self.timer = Timer(timeInterval: 5, target: self, selector: #selector(toggleAppereanceMode(_:)), userInfo: nil, repeats: true)
        
        // Add the timer to the RunLoop.
        guard let timer = self.timer else { return }
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
    }
    
    private func startLocationTimer() {
        print("Start timer")
        
        // Ensure that no timer is already running.
        guard self.locationTimer == nil else { return }
        
        // Create the timer.
        //self.timer = Timer(timeInterval: 3600, target: self, selector: #selector(toggleAppereanceMode(_:)), userInfo: nil, repeats: true)
        self.locationTimer = Timer(timeInterval: 3600, target: self, selector: #selector(startDynamicMode), userInfo: nil, repeats: true)
        
        // Add the timer to the RunLoop.
        guard let locationTimer = self.locationTimer else { return }
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
        
        startTimer()
        startLocationTimer()
        toggleAppereanceMode(self)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .denied {
            // Location updates are not authorized.
            return
        }
        // Notify the user of any errors.
    }
}
