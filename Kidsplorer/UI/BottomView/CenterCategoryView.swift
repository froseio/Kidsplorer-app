//
//  CenterCategoryView.swift
//  ChargeNChill
//
//  Created by Filip Růžička on 09.12.2023.
//

import SwiftUI
import CoreLocation
import MapKit
import Shared

struct CenterCategoryView: View {
    
    // MARK: - Properties

    @State
    var center: CLLocation

    var category: POICategory

    @EnvironmentObject
    var mainViewModel: MainViewModel

    var body: some View {
        listView(mainViewModel
            .pois
            .filter({$0.category == category})
            .sorted {
            let p1Loc = CLLocation(latitude: $0.lat, longitude: $0.lon)
            let p2Loc = CLLocation(latitude: $1.lat, longitude: $1.lon)
            let d1 = center.distance(from: p1Loc)
            let d2 = center.distance(from: p2Loc)
            return d1 < d2
        })
        .analyticsScreen(name: "center_category_view")
    }


    // MARK: Subviews

    var columns: [GridItem] = [
        GridItem(.flexible(maximum: 200)),
        GridItem(.flexible(maximum: 200)),
    ]

    func listView(_ items: [POIModel]) -> some View {

        return ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(items) { item in
                    POIListItemView(from: item, centerLocation: center)
                        .frame(height: 150)
                        .onTapGesture {
                            mainViewModel.selectedPoi = item
                        }
                }
            }
        }
    }
}
