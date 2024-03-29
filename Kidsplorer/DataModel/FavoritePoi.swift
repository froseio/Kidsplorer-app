//
//  FavoritePoi.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 26.02.2024.
//

import Foundation
import SwiftData
import Shared
import CoreLocation

@Model
final class FavoritePoi{
    let lat: Double
    let lon: Double
    let name: String
    let category: POICategory
    let gpid: String?

    init(lat: Double, lon: Double, name: String, category: POICategory, gpid: String?) {
        self.lat = lat
        self.lon = lon
        self.name = name
        self.category = category
        self.gpid = gpid
    }
}

extension FavoritePoi: Identifiable {
    var id: String {
        if let gpid {
            return gpid
        }
        else {
            return "\(lat)_\(lon)_\(category)"
        }
    }

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

    var poiModel: POIModel {
        var detail: POIDetailModel?
        if gpid == nil {
            detail = POIDetailModel()
        }

        return POIModel(lat: lat, lon: lon, name: name, category: category, detail: detail, gpid: gpid)
    }
}
