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
            case .playground:
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
        }
    }

    var color: Color {
        Color(self.rawValue)
    }

    var title: String {
        switch self {
            case .playground:
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
        }
    }

    var desc: String {
        switch self {
            case .playground:
                "all playgrounds"
            case .sport:
                "activities like swimming pools or amusement centres"
            case .zoo:
                "animals around"
            case .educational:
                "museum, libraries"
            case .nature:
                "park, nature reserves and more"
            case .cultural:
                "theatres and cinemas"
        }
    }
}
