//
//  LocationManager.swift
//  ChargeNChill
//
//  Created by Filip Růžička on 24.08.2023.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?

    static let shared = LocationManager()

    override init() {
        super.init()
//        self.lastLocation = UserDefaultsManager.shared.userLocation
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    var statusString: String {
        guard let status = locationStatus else {
            return "LocationManager.unknown"
        }

        switch status {
            case .notDetermined: return "LocationManager.notDetermined"
            case .authorizedWhenInUse: return "LocationManager.authorizedWhenInUse"
            case .authorizedAlways: return "LocationManager.authorizedAlways"
            case .restricted: return "LocationManager.restricted"
            case .denied: return "LocationManager.denied"
            default: return "LocationManager.unknown"
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.locationStatus = status
            manager.startUpdatingLocation()
            self.objectWillChange.send()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.lastLocation = location
//            UserDefaultsManager.shared.userLocation = location
//            self.objectWillChange.send()
        }
    }
}
