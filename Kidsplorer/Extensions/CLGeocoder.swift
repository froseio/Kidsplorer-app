//
//  CLGeocoder.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 15.02.2024.
//

import Foundation
import CoreLocation

extension CLGeocoder {
    func getAddress(coordinate: CLLocationCoordinate2D) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            self.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let placemarks = placemarks?.first, let address = self.formatAddressFromPlacemark(placemark: placemarks) {
                    continuation.resume(returning: address)
                } else {
                    continuation.resume(throwing: NSError(domain: "CLGeocoderError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Neznámá chyba"]))
                }
            }
        }
    }

    func formatAddressFromPlacemark(placemark: CLPlacemark) -> String? {
        var addressParts: [String] = []

        if let street = placemark.thoroughfare {
            addressParts.append(street)
        }

        //        if let subThoroughfare = placemark.subThoroughfare {
        //            addressParts.append(subThoroughfare)
        //        }

        if let city = placemark.locality {
            addressParts.append(city)
        }

        //        if let postalCode = placemark.postalCode {
        //            addressParts.append(postalCode)
        //        }

        if let country = placemark.country {
            addressParts.append(country)
        }

        let joined = addressParts.joined(separator: ", ")

        if addressParts.isEmpty {
            return nil
        }

        return joined
    }
}
