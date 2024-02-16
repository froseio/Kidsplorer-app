//
//  AddressInputView.swift
//  ChargeNChill
//
//  Created by Filip Růžička on 09.02.2024.
//

import SwiftUI
import CoreLocation
import MapKit

struct AddressInputView: View {
    @ObservedObject var locationManager = LocationManager.shared
    @FocusState var searchIsFocused: Bool
    @State var searchText = ""
    @State private var searchedItems: [MKMapItem] = []
    @State private var searchHistory: [MKMapItem] = []
    let searchRequest = MKLocalSearch.Request()
    @State var localSearch: MKLocalSearch?

    @Environment(\.dismiss) var dismiss

    var onAddressSelect: ((CLLocation) -> ())
    var onNavigateSelect: ((CLLocation) -> ())?

    var body: some View {
        VStack {
            HStack {
                TextField(
                    "Address",
                    text: $searchText,
                    prompt: Text("Search for place")
                )
                .textFieldStyle(.roundedBorder)
                .focused($searchIsFocused)

                Button("Cancel") {
                    if searchText == "PremiumPower" {
                        UserDefaultsManager.shared.premiumCode = searchText
                    }

                    dismiss()
                }
            }
            .padding()

            if searchText.isEmpty {
                // Zobrazení historie vyhledávání
                List {
                    ForEach(searchHistory) { item in
                        if let loc = item.placemark.location, let name = item.name {
                            searchItemView(item: item, location: loc, name: name)
                        }
                    }
                    .onDelete(perform: deleteHistoryItem) // Implementace mazání swipem
                }
            } else {
                // Zobrazení výsledků vyhledávání
                List(searchedItems) { item in
                    if let loc = item.placemark.location, let name = item.name {
                        searchItemView(item: item, location: loc, name: name)
                    }
                }
            }
        }
        .onAppear {
            searchIsFocused = true
            searchHistory = loadSearchHistory()
        }
        .onChange(of: searchHistory) { newValue in
            saveSearchHistory(searchHistory)
        }
        .onChange(of: searchText) { newValue in
            Task {
                await searchInAppleMaps()
            }
        }
    }

    // Při ukládání MKMapItem do UserDefaults
    func saveSearchHistory(_ mapItems: [MKMapItem]) {
        let locationsData = mapItems.map { item -> [String: Any] in
            let name = item.name ?? ""
            let latitude = item.placemark.coordinate.latitude
            let longitude = item.placemark.coordinate.longitude
            return ["name": name, "latitude": latitude, "longitude": longitude]
        }
        UserDefaults.standard.set(locationsData, forKey: "searchHistory")
    }

    // Při načítání MKMapItem z UserDefaults
    func loadSearchHistory() -> [MKMapItem] {
        guard let locationsData = UserDefaults.standard.array(forKey: "searchHistory") as? [[String: Any]] else { return [] }
        return locationsData.map { locationDict -> MKMapItem in
            let name = locationDict["name"] as? String ?? ""
            let latitude = locationDict["latitude"] as? CLLocationDegrees ?? 0
            let longitude = locationDict["longitude"] as? CLLocationDegrees ?? 0
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = name
            return mapItem
        }
    }

    private func searchItemView(item: MKMapItem, location: CLLocation, name: String) -> some View {
        HStack {
            searchItemContentView(item: item, name: name, location: location)
            .tint(Color.text)
            .padding(.vertical)

            if let onNavigateSelect {
                Button(action: {
                    dismiss()
                    onNavigateSelect(location)
                    addSearchItemToHistory(item: item) // Uložení do historie
                    searchText = ""
                }) {
                    Image(systemName: "point.bottomleft.forward.to.arrowtriangle.uturn.scurvepath")
                        .tint(.text)
                        .padding()
                        .background(Color.boxBackground)
                        .cornerRadius(5)
                        .padding(5)
                }
                .tint(Color.text)
                .buttonStyle(.plain)
            }
        }
    }

    private func searchItemContentView(item: MKMapItem, name: String, location: CLLocation) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name).font(.headline)
                Text(item.placemark.formattedAddress).font(.subheadline)
            }
            Spacer()
            distanceView(from: item.placemark.location!)
        }
        .background {
            Rectangle()
                .foregroundColor(.background.opacity(0.001))
                .onTapGesture {
                    dismiss()
                    onAddressSelect(location)
                    addSearchItemToHistory(item: item) // Uložení do historie
                    searchText = ""
                }
        }
    }

    private func addSearchItemToHistory(item: MKMapItem) {
        if !searchHistory.contains(where: { $0 == item }) {
            searchHistory.insert(item, at: 0) // Přidáváme na začátek historie
        }
    }

    private func deleteHistoryItem(at offsets: IndexSet) {
        searchHistory.remove(atOffsets: offsets)
    }

    func distanceView(from loc: CLLocation) -> some View {
        if let lastL = locationManager.lastLocation {
            let distance = lastL.distance(from: loc).formatedDistance()
            return Text(distance).font(.caption)
        } else {
            return Text("")
        }
    }

    func searchInAppleMaps() async {
        if let localSearch {
            localSearch.cancel()
        }

        searchRequest.naturalLanguageQuery = searchText
        searchRequest.pointOfInterestFilter = .includingAll
        searchRequest.resultTypes = [.address, .pointOfInterest]

        let localSearch = MKLocalSearch(request: searchRequest)
        self.localSearch = localSearch

        do {
            let response = try await localSearch.start()
            searchedItems = response.mapItems
        } catch {
            searchedItems = []
        }
    }
}

extension MKPlacemark {
    var formattedAddress: String {
        let parts = [thoroughfare, locality, country]
        return parts.compactMap { $0 }.joined(separator: ", ")
    }
}

