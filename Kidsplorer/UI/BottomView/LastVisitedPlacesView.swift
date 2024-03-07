//
//  LastVisitedPlacesView.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 29.02.2024.
//

import SwiftUI
import SwiftData
import CoreLocation

struct LastVisitedPlacesView: View {

    @Environment(\.modelContext)
    private var modelContext

    // Struktura pro skupinování podle dnů
    struct DaySection: Identifiable {
        let day: Date
        var pois: [VisitedPoi]
        var id: Date { day }
    }

    @State
    var sections: [DaySection] = []

    @State var selectedPoi: VisitedPoi?

    var body: some View {
        Group {
            if sections.isEmpty {
                Text("Tap on checkin in the place details to create a list of places you have visited")
                    .foregroundStyle(Color.text)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    ForEach(sections) { section in
                        Section(header: Text("\(section.day, formatter: itemFormatter)")) {
                            ForEach(section.pois) { poi in
                                LastVisitedPlaceItemView(poi: poi)
                                    .foregroundStyle(Color.text)
                                    .onTapGesture {
                                        selectedPoi = poi
                                    }
                                    .sheet(item: $selectedPoi) { i in
                                        let pm = poi.poiModel
                                        POIDetailView(poi: pm, detail: pm.detail)
                                            .presentationBackground(.regularMaterial)
                                    }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Visited places")
        .analyticsScreen(name: "Visited_places")
        .onAppear {
            loadData()
        }
    }

    // Funkce pro načtení a zpracování dat
    private func loadData() {

        let desc = FetchDescriptor<VisitedPoi>()
        let fetchedItems = (try? modelContext.fetch(desc)) ?? []

        // Seřazení a skupinování dat
        let grouped = Dictionary(grouping: fetchedItems) { (poi) -> Date in
            Calendar.current.startOfDay(for: poi.visitedDate)
        }

        // Převod na pole sekcí a seřazení
        self.sections = grouped.map { DaySection(day: $0.key, pois: $0.value) }
            .sorted { $0.day > $1.day }
    }

    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}


struct LastVisitedPlaceItemView: View {

    @State var poi: VisitedPoi
    @State var address: String?

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .foregroundStyle(poi.category.color)
                    .overlay(
                        Circle()
                            .stroke(.text, lineWidth: 1)
                    )

                Image(systemName: poi.category.imageName)
                    .resizable()
                    .foregroundColor(.text)
                    .padding(5)
            }
            .frame(width: 25, height: 25)

            VStack(alignment: .leading) {
                Text(poi.name)
                    .font(.headline)

                if let address {
                    Text(address)
                        .font(.footnote)
                }
                Text("Visited: \(poi.visitedDate, formatter: itemFormatter)")
                    .font(.footnote)
            }

            Spacer()
        }
        .task {
            address = try? await CLGeocoder().getAddress(coordinate: poi.coordinate)
        }
    }

    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    LastVisitedPlacesView()
}
