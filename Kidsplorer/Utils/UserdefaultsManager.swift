//
//  UserdefaultsManager.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 14.02.2024.
//

import Foundation
import CoreLocation
import Combine
import Shared
import RevenueCat

class UserDefaultsManager: ObservableObject {
    
    // MARK: - Submodules
    enum UserDefaultsKey: String {
        case lastPaywallShow
        case isPremium
        case userLocationKey
        case enabledCategories
        case premiumcode
    }


    // MARK: - Static variables
    static let shared = UserDefaultsManager()


    // MARK: - Private variables

    private var cancellables: [AnyCancellable] = []


    // MARK: - Variables

    @Published var premiumCode: String? {
        didSet {
            UserDefaults.standard.set(premiumCode, forKey: UserDefaultsKey.premiumcode.rawValue)
        }
    }

    @Published var isPremium: Bool = false {
        didSet {
            UserDefaults.standard.set(isPremium, forKey: UserDefaultsKey.isPremium.rawValue)
        }
    }

    @Published var lastPaywallShow: Date? {
        didSet {
            if let date = lastPaywallShow {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: UserDefaultsKey.lastPaywallShow.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKey.lastPaywallShow.rawValue)
            }
        }
    }

    @Published var userLocation: CLLocation? {
        didSet {
            guard let location = userLocation else {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKey.userLocationKey.rawValue)
                return
            }
            let data = try? NSKeyedArchiver.archivedData(withRootObject: location, requiringSecureCoding: false)
            UserDefaults.standard.set(data, forKey: UserDefaultsKey.userLocationKey.rawValue)
        }
    }

    @Published var enabledCategories: Set<String> {
        didSet {
            let data = try? NSKeyedArchiver.archivedData(withRootObject: enabledCategories, requiringSecureCoding: false)
            UserDefaults.standard.set(data, forKey: UserDefaultsKey.enabledCategories.rawValue)
        }
    }


    // MARK: - Initialize

    init() {
        if let timeInterval = UserDefaults.standard.value(forKey: UserDefaultsKey.lastPaywallShow.rawValue) as? TimeInterval {
            let date = Date(timeIntervalSince1970: timeInterval)
            self.lastPaywallShow = date
        }

        self.userLocation = {
            guard let data = UserDefaults.standard.data(forKey: UserDefaultsKey.userLocationKey.rawValue),
                  let location = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CLLocation.self, from: data) else {
                return nil
            }
            return location
        }()

        self.enabledCategories = {
            guard let data = UserDefaults.standard.data(forKey: UserDefaultsKey.enabledCategories.rawValue),
                  let categories = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSSet.self, NSString.self], from: data) as? Set<String> else {
                return [POICategory.playground.rawValue, POICategory.sport.rawValue]
            }
            return categories
        }()

        if let premiumCode = UserDefaults.standard.value(forKey: UserDefaultsKey.premiumcode.rawValue) as? String {
            self.premiumCode = premiumCode
        }
    }


    // MARK: - Private funcs

    private func data(forKey key: UserDefaultsKey) -> Data? {
        return UserDefaults.standard.data(forKey: key.rawValue)
    }

    private func set(_ data: Data?, forKey key: UserDefaultsKey) {
        UserDefaults.standard.set(data, forKey: key.rawValue)
    }
}
