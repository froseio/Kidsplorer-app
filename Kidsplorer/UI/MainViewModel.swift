//
//  MainViewModel.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 14.02.2024.
//

import Foundation
import Combine
import Shared
import MapKit
import SwiftData

class MainViewModel: ObservableObject {

    // MARK: - Variables

    @Published
    var selectedPoi: POIModel?

    @Published
    var pois = [POIModel]()

    @Published
    var isLoading: Bool = false


    // MARK: - Private variables

    private var lastLoadedRegion: MKCoordinateRegion?
    private var cancellables: Set<AnyCancellable> = []
    private var workItem: DispatchWorkItem?
    private var currentDataTask: Task<Void, any Error>?
    private var modelContext: ModelContext


    // MARK: - Initialize

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        UserDefaultsManager
            .shared
            .$enabledCategories
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { categories in
                if let lastLoadedRegion = self.lastLoadedRegion {
                    self.loadMapPins(force: true, region: lastLoadedRegion)
                }
            }
            .store(in: &cancellables)

        UserDefaultsManager
            .shared
            .$isPremium
            .sink { _ in
                if let lastLoadedRegion = self.lastLoadedRegion {
                    self.loadMapPins(force: true, region: lastLoadedRegion)
                }
            }
            .store(in: &cancellables)
    }


    // MARK: - Private funcs

    private func mapChangeRegion(newRegion: MKCoordinateRegion) {
        if lastLoadedRegion == nil {
            lastLoadedRegion = newRegion
        }

        workItem?.cancel()
        workItem = DispatchWorkItem { [weak self] in
            self?.loadMapPins(region: newRegion)
        }

        if let workItem = workItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
        }
    }

    private func hasRegionChangedSignificantly(from oldRegion: MKCoordinateRegion?, to newRegion: MKCoordinateRegion) -> Bool {

        guard let oldRegion else {
            return true
        }

        let threshold: Double = 0.01
        let deltaLatitude = abs(newRegion.center.latitude - oldRegion.center.latitude)
        let deltaLongitude = abs(newRegion.center.longitude - oldRegion.center.longitude)
        let deltaSpanLatitude = newRegion.span.latitudeDelta - oldRegion.span.latitudeDelta
        let deltaSpanLongitude = newRegion.span.longitudeDelta - oldRegion.span.longitudeDelta

        // Pokud uživatel oddálí mapu
        if deltaSpanLatitude > 0 || deltaSpanLongitude > 0 {
            return true
        }

        // Pokud uživatel přiblíží mapu a pohne se jí, ale stále zůstává v původním načteném regionu
        if (deltaSpanLatitude < 0 || deltaSpanLongitude < 0) &&
            (newRegion.center.latitude + newRegion.span.latitudeDelta / 2 <= oldRegion.center.latitude + oldRegion.span.latitudeDelta / 2 &&
             newRegion.center.latitude - newRegion.span.latitudeDelta / 2 >= oldRegion.center.latitude - oldRegion.span.latitudeDelta / 2 &&
             newRegion.center.longitude + newRegion.span.longitudeDelta / 2 <= oldRegion.center.longitude + oldRegion.span.longitudeDelta / 2 &&
             newRegion.center.longitude - newRegion.span.longitudeDelta / 2 >= oldRegion.center.longitude - oldRegion.span.longitudeDelta / 2) {
            return false
        }

        // Pokud se střed mapy posunul o více než threshold
        return deltaLatitude > threshold || deltaLongitude > threshold
    }


    // MARK: - Public funcs
    
    func loadMapPins(force: Bool = false, region: MKCoordinateRegion) {

//        if force {
//            self.pois.removeAll()
//        }

//        guard (force || hasRegionChangedSignificantly(from: lastLoadedRegion, to: region)) else {
//            return
//        }

        currentDataTask?.cancel()

        DispatchQueue.main.async {
            self.isLoading = false
        }

        let categories: [POICategory] = UserDefaultsManager
            .shared
            .enabledCategories
            .compactMap({ POICategory(rawValue: $0) })

        let span = min(region.span.longitudeDelta, region.span.latitudeDelta)
        let lat = region.center.latitude
        let lon = region.center.longitude

        currentDataTask = Task {
            DispatchQueue.main.async {
                self.isLoading = true
            }

            if categories.isEmpty {
                return
            }

            let languageCode = Locale.current.language.languageCode?.identifier ?? "en"

            let reqModel = PlacesEndpoint.GetPlaces.Request(
                centerLatitude: lat,
                centerLongitude: lon,
                span: span,
                categories: categories,
                isPremium: UserDefaultsManager.shared.isPremium,
                lang: languageCode
            )

            let endpoint = PlacesEndpoint.GetPlaces(
                requestModel: reqModel
            )

            let response = try await CCAPIClient.shared.load(endpoint: endpoint)
            self.lastLoadedRegion = region

            let desc = FetchDescriptor<FavoritePoi>()
            let fetchedItems = (try? modelContext.fetch(desc).map({$0.id})) ?? []

            DispatchQueue.main.async {
                self.pois = response.pois.filter({ p in
                    !fetchedItems.contains(p.id)
                })

                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}
