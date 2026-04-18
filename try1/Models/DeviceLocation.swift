//
//  DeviceLocation.swift
//  try1
//
//  Created by sal_grey_62283 on 4/18/26.
//

import CoreLocation

struct DeviceLocation {
    let lat: Double
    let lon: Double
    let timestamp: TimeInterval

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    // Parser for Firebase?
    init?(firebaseData: [String: Any]) {
        guard
            let lat = firebaseData["lat"] as? Double,
            let lon = firebaseData["lon"] as? Double
        else {
            return nil
        }
        
        let timestamp = (firebaseData["timestamp"] as? TimeInterval) ?? Date().timeIntervalSince1970
        
        self.lat = lat
        self.lon = lon
        self.timestamp = timestamp
    }
}
