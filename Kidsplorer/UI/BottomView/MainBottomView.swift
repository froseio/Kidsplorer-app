//
//  MainBottomView.swift
//  ChargeNChill
//
//  Created by Filip Růžička on 16.10.2023.
//

import SwiftUI
import Combine
import MapKit
import Shared

struct MainBottomView: View {

    // MARK: - Properties

    @State private var isScrolling = false
    @State var isSearching = false

    @EnvironmentObject var globalEnvironment: GlobalEnvironment
    @EnvironmentObject var mainVM: MainViewModel

    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var defaults = UserDefaultsManager.shared

    @Environment(\.openURL)
    var openURL

    var onAddressSelect: ((CLLocation) -> ())

    var body: some View {
        ScrollView {
            mainView()
        }
    }


    // MARK: - Main content

    @ViewBuilder
    func mainView() -> some View {

        let filterItems = POICategory.allCases
            .sorted(by: { ($0.enabled ? 1 : 0) >= ($1.enabled ? 1 : 0) })
            .map { FilterItemView.ViewModel(category: $0) }

        VStack {

            HStack {
                Button(action: {
                    isSearching.toggle()
                }, label: {
                    HStack {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Color.text)

                        Text("Search")
                            .font(.headline)
                            .foregroundStyle(Color.text)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color.background)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                })
                .sheet(isPresented: $isSearching, content: {
                    AddressInputView { loc in
                        onAddressSelect(loc)
                    }
                })

                if mainVM.isLoading {
                    ProgressView()
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .foregroundColor(.background)
                        }
                        .padding(.leading)
                }
            }
            .padding()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(filterItems) { item in
                        FilterItemView(viewModel: item)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .frame(width: 80, height: 50)
                    }
                }
                .padding(.horizontal)
            }


            // TODO: banner
            if !UserDefaultsManager.shared.isPremium {
                BannerView(subtitle: "to load all places where you can spend great time")
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding()
            }

            CenterSummaryView()

            HStack {
                Button("Terms") {
                    openURL(URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                }
                .font(.footnote)

                Spacer()

                Button("Privacy") {
                    openURL(URL(string: "https://frose.io/focusmap_privacy.html")!)
                }
                .font(.footnote)
            }
            .padding(.horizontal)
        }
    }
}

extension MKMapItem: Identifiable {

    public var id: String {
        "\(self.placemark.location?.coordinate.latitude ?? 0)\(self.placemark.location?.coordinate.longitude ?? 0)\(self.placemark.name ?? "unname")"
    }

}

