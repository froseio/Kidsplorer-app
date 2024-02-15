//
//  Double.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 15.02.2024.
//

import Foundation

extension Double {
    func formatedDistance() -> String {
//        if UserDefaultsManager.shared.imperialUnits {
//            let feet = self * 3.28084
//            if feet > 999 {
//                let miles = feet / 5280
//                return String(format: "%.1f mi", miles)
//            } else {
//                return String(format: "%.0f ft", feet)
//            }
//        } else {
            if self > 999 {
                let km = self / 1000
                return String(format: "%.1f km", km)
            } else {
                return String(format: "%.0f m", self)
            }
//        }
    }
}
