//
//  GlobalEnvironment.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 14.02.2024.
//

import Foundation
import Combine
import RevenueCat
import Shared

class GlobalEnvironment: ObservableObject {

    // MARK: - Static variables

    static let shared = GlobalEnvironment()


    // MARK: - Variables

    @Published
    var displayIntro = false

    @Published
    var displayPaywall = false

    @Published
    var selectedPOI: POIModel?

    var appUserID: String {
        if let rcid = Purchases.shared.appUserID.split(separator: ":").last {
            return String(rcid)
        } else {
            return "unknown_rcid"
        }
    }


    // MARK: - Private variables

    var cancellables: [AnyCancellable] = []


    // MARK: - Initialize

    private init() {
        UserDefaultsManager
            .shared
            .$isPremium
            .receive(on: DispatchQueue.main)
            .sink { isPremium in
                if isPremium {
                    self.displayPaywall = false
                }
            }
            .store(in: &cancellables)

        if !UserDefaultsManager.shared.introWasPresented && !UserDefaultsManager.shared.isPremium {
            displayIntro = true
        }
    }


    // MARK: - Funcs

    func showPaywall() {
        AnalyticsManager.track(.showPaywall)
        displayPaywall = true
        UserDefaultsManager.shared.lastPaywallShow = Date()
    }

    func checkAndShowPaywall() {
        Task {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                checkCustomerInfo(customerInfo)
            }
            catch {
                logger.error("Cant check customer info")
            }

            guard !UserDefaultsManager.shared.isPremium else {
                return
            }

            let now = Date.now
            let calendar = Calendar.current

            if let lastPaywallShow = UserDefaultsManager.shared.lastPaywallShow {
                if let diff = calendar.dateComponents([.day], from: lastPaywallShow, to: now).day, diff <= 2 {
                    return
                }
            }

            DispatchQueue.main.async {
                self.showPaywall()
            }
        }
    }

    func checkCustomerInfo(_ customerInfo: CustomerInfo?) {
        DispatchQueue.main.async {
            if UserDefaultsManager.shared.premiumCode == "PremiumPower" {
                UserDefaultsManager
                    .shared
                    .isPremium = true
            }
            else {
                UserDefaultsManager
                    .shared
                    .isPremium = !(customerInfo?.activeSubscriptions.isEmpty ?? true)
            }
        }
    }
}
