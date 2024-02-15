//
//  KidsplorerApp.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 14.02.2024.
//

import SwiftUI
import SwiftData

import os

import FirebaseCore
import GooglePlaces

import RevenueCat
import RevenueCatUI

let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "App")

class AppDelegate: NSObject, UIApplicationDelegate {

    var globalEnvironment = GlobalEnvironment.shared

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        GMSPlacesClient.provideAPIKey("AIzaSyCKa1BD_sfCeLtXgMz3dgsoIEJF-Or_icA")

        Purchases.logLevel = .error
        Purchases.configure(withAPIKey:"appl_kPlSEWNisJwfAMZeFigmyuYAlxV")

        globalEnvironment.checkAndShowPaywall()

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        globalEnvironment.checkAndShowPaywall()
    }
}

@main
struct KidsplorerApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject
    var globalEnvironment = GlobalEnvironment.shared

    let mainViewModel = MainViewModel()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            //            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {

    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(mainViewModel)
                .environmentObject(globalEnvironment)
                .sheet(isPresented: $globalEnvironment.displayPaywall, content: {
                    PaywallView()
                        .onRestoreCompleted({ customerInfo in
                            globalEnvironment.checkCustomerInfo(customerInfo)
                        })
                        .onPurchaseCompleted({ customerInfo in
                            globalEnvironment.checkCustomerInfo(customerInfo)
                        })
                })
        }
        .modelContainer(sharedModelContainer)
    }
}
