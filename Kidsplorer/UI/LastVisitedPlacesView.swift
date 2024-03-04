//
//  LastVisitedPlacesView.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 29.02.2024.
//

import SwiftUI
import SwiftData

struct LastVisitedPlacesView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query
    var visitedPoi: [VisitedPoi]


    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    LastVisitedPlacesView()
}
