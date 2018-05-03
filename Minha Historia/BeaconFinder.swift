//
//  BeaconFinder.swift
//  Minha Historia
//
//  Created by Victor Shinya on 02/05/18.
//  Copyright © 2018 Victor Shinya. All rights reserved.
//

import Foundation
import CoreLocation

class BeaconFinder: NSObject, CLLocationManagerDelegate {
    
    // MARK: - Global vars
    
    public var locationManager = CLLocationManager()
    private var delegate: BeaconFinderDelegate?
    private var firstInteraction = false
    
    // MARK: - Initializer
    
    init(delegate: BeaconFinderDelegate) {
        self.delegate = delegate
    }
    
    // MARK: - CLLocationManagerDelegate
    
    internal func update(distance: CLProximity) {
        switch distance {
        case .unknown:
            print("[Beacon Finder] Unknown")
        case .far:
            print("[Beacon Finder] Far away (more than 10 meters)")
        case .immediate:
            print("[Beacon Finder] Beacon so close")
        case .near:
            print("[Beacon Finder] Nearby")
            if !firstInteraction {
                delegate?.updateBeaconFinder()
                firstInteraction = true
            }
        }
    }
    
    internal func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if beacons.count > 0 {
            let beacon = beacons[0]
            update(distance: beacon.proximity)
        } else {
            update(distance: .unknown)
        }
    }
    
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    find(beacon: Constants.uuid)
                }
            }
        }
    }
    
    internal func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("[Beacon Finder] Error: Fail while monitoring: \(error.localizedDescription)")
    }
    
    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[Beacon Finder] Error: Fail on Location Manager: \(error.localizedDescription)")
    }
    
    // MARK: - Find Beacon
    
    func requestAuthorization(delegate: CLLocationManagerDelegate) {
        locationManager.delegate = delegate
        locationManager.requestAlwaysAuthorization()
    }
    
    func find(beacon uuid: String) {
        let proximityUUID = UUID(uuidString: uuid)!
        let beaconRegion = CLBeaconRegion(proximityUUID: proximityUUID, major: 13, minor: 1, identifier: "MinhaHistoriaBeaconUUID")
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
    }
}

protocol BeaconFinderDelegate {
    func updateBeaconFinder()
}
