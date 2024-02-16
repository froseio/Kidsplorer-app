//
//  MainView.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 14.02.2024.
//

import SwiftUI
import MapKit
import Shared

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
    private var bottomNavigationPath = NavigationPath()

    @State
    private var bottomDetent: PresentationDetent = minimalDetent


    // MARK: - View variables

    var body: some View {
        Map(position: $mapPosition, selection: $selectedItem) {

            // TODO: Uprav Z pozici
            pins(pins: viewModel.pois)

            UserAnnotation()
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .onMapCameraChange { context in
            self.viewModel.loadMapPins(region: context.region)
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
            MapPitchToggle()
        }
        .sheet(isPresented: $bottomPresented) {
            NavigationStack(path: $bottomNavigationPath) {
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
            .presentationDetents([Self.minimalDetent, .medium, .large], selection: $bottomDetent)
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled()

        }
        .onChangeOf(globalEnvironment.displayPaywall) { _ in
            updateBottomViewVisibility()
        }
        .onChangeOf(globalEnvironment.selectedPOI) { _ in
            updateBottomViewVisibility()
        }
        .sheet(item: $globalEnvironment.selectedPOI) { poi in
            POIDetailView(poi: poi, detail: poi.detail)
                .presentationBackground(.regularMaterial)
                .presentationDetents([.medium, .large], selection: $bottomDetent)
                .presentationBackgroundInteraction(.enabled)
        }
    }

    func updateBottomViewVisibility() {
        bottomPresented =  (
            !globalEnvironment.displayPaywall
            && globalEnvironment.selectedPOI == nil
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
}


#Preview {
    MainView()
}
