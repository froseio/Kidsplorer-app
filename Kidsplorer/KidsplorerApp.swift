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
        
        GMSPlacesClient.provideAPIKey("AIzaSyD_lAXB4mIa_t30M4_PIw3INUx2k5v82vo")

        #if !DEBUG
        FirebaseApp.configure()
        #endif

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

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var delegate

    @StateObject
    var globalEnvironment = GlobalEnvironment.shared

    let mainViewModel: MainViewModel
    var sharedModelContainer: ModelContainer

    init() {
        let schema = Schema([
            FavoritePoi.self,
            VisitedPoi.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            self.sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        mainViewModel = MainViewModel(modelContext: sharedModelContainer.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            if globalEnvironment.displayIntro {
                OnboardingView()
                    .analyticsScreen(name: "OnboardingView")
                    .environmentObject(globalEnvironment)
            }
            else if globalEnvironment.displayPaywall {
                ZStack(alignment: .topTrailing) {
                    PaywallView()
                        .onRestoreCompleted({ customerInfo in
                            globalEnvironment.checkCustomerInfo(customerInfo)
                        })
                        .onPurchaseCompleted({ customerInfo in
                            globalEnvironment.checkCustomerInfo(customerInfo)
                        })
                        .analyticsScreen(name: "PaywallView_main")

                    Button("Skip") {
                        globalEnvironment.displayPaywall = false
                        AnalyticsManager.track(.dismissPaywall)
                    }
                    .foregroundColor(Color.black)
                    .padding()
                }
            }
            else {
                MainView()
//                LastVisitedPlacesView()
                    .modelContainer(sharedModelContainer)
                    .environmentObject(mainViewModel)
                    .environmentObject(globalEnvironment)                    
            }
        }        
    }
}
