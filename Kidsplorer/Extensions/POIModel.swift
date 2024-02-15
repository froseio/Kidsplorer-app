//
//  POIModel+Hashable.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 15.02.2024.
//

import Foundation
import Shared
import CoreLocation

extension POIModel: Hashable {

    public static func == (lhs: Shared.POIModel, rhs: Shared.POIModel) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
}

extension POIModel: Identifiable {

    public var id: String {
        "\(lat)\(lon)\(gpid ?? "osm")"
    }
}

extension POIModel {

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: lat,
            longitude: lon
        )
    }

    public var location: CLLocation {
        CLLocation(
            latitude: lat,
            longitude: lon
        )
    }
}
