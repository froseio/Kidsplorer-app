//
//  CenterSummaryView.swift
//  ChargeNChill
//
//  Created by Filip Růžička on 08.12.2023.
//

import SwiftUI
import CoreLocation
import MapKit
import Shared
import SwiftData

struct CenterSummaryView: View {

    // MARK: - Properties
    // MARK: Public
//    @ObservedObject 
    var locationManager = LocationManager.shared

    @ObservedObject
    var defaults = UserDefaultsManager.shared

    // MARK: Private
    @EnvironmentObject
    var globalEnvironment: GlobalEnvironment

    @EnvironmentObject
    var mainViewModel: MainViewModel

    @Environment(\.modelContext)
    private var modelContext
    
//    @Query
    var favorites: [FavoritePoi] = []

    var body: some View {

        let centerCoord = locationManager.lastLocation?.coordinate
        let centerLocation = CLLocation(latitude: centerCoord?.latitude ?? 0, longitude: centerCoord?.longitude ?? 0)

        LazyVStack(alignment: .leading) {
            SectionView(name: "Nearest places", count: mainViewModel.pois.count)
                .padding(.horizontal)
            rowContent(
                mainViewModel
                    .pois
                    .sorted {
                        let p1Loc = CLLocation(latitude: $0.lat, longitude: $0.lon)
                        let p2Loc = CLLocation(latitude: $1.lat, longitude: $1.lon)
                        let d1 = centerLocation.distance(from: p1Loc)
                        let d2 = centerLocation.distance(from: p2Loc)
                        return d1 < d2
                    }
                    .prefix(UserDefaultsManager.shared.isPremium ? 10 : Int.random(in: 3...5))
                    .compactMap {
                        POIListItemView(from: $0, centerLocation: centerLocation)
                    }
            )
            .accessibilityIdentifier("nearestRow")

            if !UserDefaultsManager.shared.isPremium {
                BannerView(subtitle: "to load all places where you can spend great time")
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding()
            }

            SectionView(name: "Favorite places", count: favorites.count)
                .padding(.horizontal)
            rowContent(
                favorites
                    .map { $0.poiModel }
                    .sorted {
                        let p1Loc = CLLocation(latitude: $0.lat, longitude: $0.lon)
                        let p2Loc = CLLocation(latitude: $1.lat, longitude: $1.lon)
                        let d1 = centerLocation.distance(from: p1Loc)
                        let d2 = centerLocation.distance(from: p2Loc)
                        return d1 < d2
                    }
                    .prefix(UserDefaultsManager.shared.isPremium ? favorites.count : 3)
                    .compactMap {
                        POIListItemView(from: $0, centerLocation: centerLocation)
                    }
            )
            .accessibilityIdentifier("favoriteRow")

            ForEach(POICategory.allCases, id: \.rawValue) { c in
                let availableItems = mainViewModel
                    .pois
                    .filter {
                        $0.category == c
                    }
                    .sorted {
                        let p1Loc = CLLocation(latitude: $0.lat, longitude: $0.lon)
                        let p2Loc = CLLocation(latitude: $1.lat, longitude: $1.lon)
                        let d1 = centerLocation.distance(from: p1Loc)
                        let d2 = centerLocation.distance(from: p2Loc)
                        return d1 < d2
                    }
                    .prefix(UserDefaultsManager.shared.isPremium ? 10 : 3)
                    .compactMap {
                        POIListItemView(from: $0, centerLocation: centerLocation)
                    }

                if !availableItems.isEmpty {
                    VStack {
                        HStack(spacing: 2) {
                            if UserDefaultsManager.shared.isPremium {
                                NavigationLink(value: c) {
                                    SectionView(category: c, count: mainViewModel
                                        .pois
                                        .filter {
                                            $0.category == c
                                        }.count)
                                }
                            }
                            else {
                                SectionView(category: c, count: mainViewModel
                                    .pois
                                    .filter {
                                        $0.category == c
                                    }.count)
                                    .onTapGesture {
                                        globalEnvironment.showPaywall()
                                    }
                            }
                            Image(systemName: "chevron.right")
                        }
                        .padding(.horizontal)
                        rowContent(availableItems)
                    }
                }
            }
        }
    }

    func rowContent(_ items: [POIListItemView]) -> some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(items) { item in
                    item
                        .onTapGesture {
                            globalEnvironment.selectedPOI = item.poi
                        }
                }

                if !UserDefaultsManager.shared.isPremium, let lastItem = items.last {
                    ZStack {
                        lastItem
                            .blur(radius: 4)

                        Rectangle()
                            .foregroundStyle(Color.black)
                            .opacity(0.4)

                        VStack {
                            Text("Get premium")
                                .font(.headline)

                            Text("to load more places")
                                .font(.subheadline)
                        }
                        .foregroundStyle(Color.white)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .onTapGesture {
                        globalEnvironment.showPaywall()
                    }

                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
    }
}
//
//#Preview {
//    CenterSummaryView()
//}

struct SectionView: View {

    @State var category: POICategory?
    @State var name: String?
    @State var count: Int

    var body: some View {
        HStack {
            Text((category?.rawValue ?? name ?? "").capitalized)
                .font(.headline)
            Spacer()
            Text("\(count)")
                .font(.caption)
            if category != nil {
//                Image(systemName: "chevron.right")
//                    .font(.caption)
            }
        }
        .foregroundColor(.text)
    }
}

struct POIListItemView: View, Identifiable {

    var id: String
    var title: String
    var location: CLLocation
    var detail: Bool = false
    var centerLocation: CLLocation?
    var gpid: String?

    var poi: POIModel

    @ObservedObject
    var imgLoader: PlaceImgLoader

    var distanceCenter: Double? {
        guard
            let d = centerLocation?.distance(from: location),
            d < 100000
        else {
            return nil
        }
        return d
    }

    init(from poi: POIModel, centerLocation: CLLocation?) {
        detail = true
        self.poi = poi
        id = poi.id
        title = poi.name
        location = CLLocation(latitude: poi.lat, longitude: poi.lon)
        self.centerLocation = centerLocation

        self.imgLoader = PlaceImgLoader(id: poi.id, location: location)
    }

    var body: some View {
        ZStack {
            if let img = imgLoader.image {
                Image(uiImage: img)
                    .resizable()
            }
            else {
                ProgressView()
            }

            VStack {
                HStack {
                    if let distanceCenter {
                        Text(distanceCenter.formatedDistance())
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.black.opacity(2))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .padding(10)
                    }
                    Spacer()
                }
                // TODO: Favorite button on right
                Spacer()
                ZStack(alignment: .bottom) {

                    LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.7)]), startPoint: .top, endPoint: .bottom)

                    HStack {
                        Text(title)
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .padding(10)

                        Spacer()
                    }
                }
            }

        }
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .frame(width: 200, height: 150)
        .onAppear {
            imgLoader.getImage()
        }        
    }
}
