//
//  AnalyticsManager.swift
//  ChargeNChill
//
//  Created by Filip Růžička on 11.09.2023.
//

import Foundation
import Firebase

class AnalyticsManager {

    enum Event: String {
        case bannerTap
        case tryAgainDetail
        
        case disableCategory
        case enableCategory

        case showPaywall
        case dismissPaywall
        case openInMap

        case nextIntro
        case skipIntro
        case skipIntroPaywall
        case buyFromintro
        case restoreFromintro

        case checkin
        case add_favorite
        case rm_favorite
    }

    static func track(_ event: Event, detailMessage: String? = nil) {
        var parameters: [String: Any] = [:]

        if let detailMessage {
            parameters["detailMessage"] = detailMessage
        }

        Analytics.logEvent(event.rawValue, parameters: parameters)
    }

}
