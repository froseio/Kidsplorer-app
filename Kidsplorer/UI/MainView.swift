//
//  MainView.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 14.02.2024.
//

import SwiftUI
import MapKit
import Shared
import SwiftData

struct MainView: View {

    // MARK: - Static variables

    static let minimalDetent: PresentationDetent = .height(120)
    
    static var initLocation: CLLocationCoordinate2D {
        LocationManager.shared.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 50.35383344991647, longitude: 13.8096231193514)
    }


    // MARK: - Environment variables

    @EnvironmentObject
    var viewModel: MainViewModel

    @EnvironmentObject
    var globalEnvironment: GlobalEnvironment

    // MARK: - Private variables

    @State
    private var mapPosition: MapCameraPosition = .userLocation(
        fallback: .region(MKCoordinateRegion(
            center: Self.initLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        )
    )

    @State
    private var selectedItem: MKMapItem?

    @State
    private var bottomPresented: Bool = true

    @State
    private var showRefreshButton = false

    @State
    private var region: MKCoordinateRegion?

    @Environment(\.modelContext)
    private var modelContext
    
    @Query
    var favoritePois: [FavoritePoi]

    // MARK: - View variables

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $mapPosition, selection: $selectedItem) {

                pins(pins: viewModel.pois)

                favoritePins()

                UserAnnotation()
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .onMapCameraChange { context in
                if viewModel.pois.isEmpty {
                    self.viewModel.loadMapPins(region: context.region)
                }

                showRefreshButton = true
                region = context.region
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
                MapPitchToggle()
            }

            if showRefreshButton {
                Button {
                    showRefreshButton = false
                    if let region {
                        viewModel.loadMapPins(region: region)
                    }
                } label: {
                    Text("Search this area")
                        .padding()
                        .background(Color.background)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .padding()
            }
        }
        .sheet(isPresented: $bottomPresented) {
            NavigationStack {
                MainBottomView(onAddressSelect: { loc in
                    mapPosition = .camera(MapCamera(centerCoordinate: loc.coordinate, distance: 10000))
                })
                    .navigationDestination(for: POIModel.self) { poi in
                        POIDetailView(poi: poi, detail: poi.detail)
                    }
                    .navigationDestination(for: POICategory.self) { cat in
                        CenterCategoryView(
                            center: CLLocation(
                                latitude: mapPosition.region?.center.latitude ?? 0,
                                longitude: mapPosition.region?.center.longitude ?? 0),
                            category: cat)
                    }
            }
            .presentationBackground(.regularMaterial)
            .presentationDetents([Self.minimalDetent, .medium, .large])
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled()
        }
        .onChangeOf(viewModel.pois, perform: { newValue in
            if !newValue.isEmpty {
                showRefreshButton = false
            }
        })
        .onChangeOf(globalEnvironment.selectedPOI) { _ in
            updateBottomViewVisibility()
        }
        .sheet(item: $globalEnvironment.selectedPOI) { poi in
            POIDetailView(poi: poi, detail: poi.detail)
                .presentationBackground(.regularMaterial)
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.enabled)
        }
    }

    func updateBottomViewVisibility() {
        bottomPresented =  (
            globalEnvironment.selectedPOI == nil
        )
    }

    // MARK: - View funcs

    func pins(pins: [POIModel]) -> some MapContent {
        ForEach(pins) { poi in
            Annotation(
                poi.name,
                coordinate: poi.coordinate,
                anchor: .bottom
            ) {
                ZStack {
                    Circle()
                        .foregroundStyle(poi.category.color)
                        .frame(minWidth: 15, minHeight: 15)
                        .overlay(
                            Circle()
                                .stroke(.text, lineWidth: 1)
                        )

                    if poi.gpid != nil {
                        Image(systemName: poi.category.imageName)
                            .resizable()
                            .foregroundColor(.text)
                            .frame(width: 15, height: 15)
                            .padding(5)
                    }
                }
                .onTapGesture {
                    globalEnvironment.selectedPOI = poi
                }
            }
            .annotationTitles(.hidden)
        }
    }

    func favoritePins() -> some MapContent {
        ForEach(favoritePois) { poi in
            Annotation(
                poi.name,
                coordinate: poi.coordinate,
                anchor: .bottom
            ) {
                ZStack {
                    Circle()
                        .foregroundStyle(.red)
                        .frame(minWidth: 15, minHeight: 15)
                        .overlay(
                            Circle()
                                .stroke(.text, lineWidth: 1)
                        )

                    Image(systemName: "heart.fill")
                        .resizable()
                        .foregroundColor(.text)
                        .frame(width: 15, height: 15)
                        .padding(5)
                }
                .onTapGesture {
                    globalEnvironment.selectedPOI = poi.poiModel
                }
            }
            .annotationTitles(.hidden)
        }
    }
}


#Preview {
    MainView()
}
