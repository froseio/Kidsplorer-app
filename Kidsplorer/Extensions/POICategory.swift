//
//  POICategory.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 15.02.2024.
//

import Foundation
import Shared
import SwiftUI

extension POICategory {

    var imageName: String {
        switch self {
            case .park:
                return "teddybear.fill"
            case .sport:
                return "figure.pool.swim"
            case .zoo:
                return "dog.fill"
            case .educational:
                return "books.vertical.fill"
            case .nature:
                return "tree"
            case .cultural:
                return "theatermasks"
            case .event:
                return "personalhotspot"
        }
    }

    var color: Color {
        Color(self.rawValue)
    }

    var title: String {
        switch self {
            case .park:
                "Playground"
            case .sport:
                "Sport"
            case .zoo:
                "Zoo"
            case .educational:
                "Edu"
            case .nature:
                "Nature"
            case .cultural:
                "Culture"
            case .event:
                "Event"
        }
    }
}