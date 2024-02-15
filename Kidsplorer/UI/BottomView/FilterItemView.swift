//
//  FilterItemView.swift
//  ChargeNChill
//
//  Created by Filip Růžička on 24.08.2023.
//

import SwiftUI
import Shared

extension POICategory {
    var enabled: Bool {
        UserDefaultsManager.shared.enabledCategories.contains(rawValue)
    }

    func select() {
        if enabled {
            UserDefaultsManager.shared.enabledCategories.remove(rawValue)
        }
        else {
            UserDefaultsManager.shared.enabledCategories.insert(rawValue)
        }
    }
}

struct FilterItemView: View {

    class ViewModel: ObservableObject, Identifiable {
        fileprivate var backgroundColor: Color
        fileprivate var image: String
        fileprivate var title: String?
        fileprivate var category: POICategory
        public var id: String

        var enabled: Bool {
            category.enabled
        }

        init(category: POICategory) {
            self.category = category

            self.id = category.rawValue
            self.backgroundColor = category.color
            self.image = category.imageName
            self.title = category.title
        }

        func canSelect() -> Bool {
            let isPremium = UserDefaultsManager.shared.isPremium
            let enabledCategoriesCount = UserDefaultsManager.shared.enabledCategories.count

            if !isPremium && !enabled && enabledCategoriesCount >= 2 {
                return false
            }

            return true
        }

        func select() {
            category.select()
            objectWillChange.send()
        }
    }

    @ObservedObject var viewModel: ViewModel
    @EnvironmentObject var globalEnvironment: GlobalEnvironment

    var body: some View {
        Button(action: {
            if viewModel.canSelect() {
                viewModel.select()
            }
            else {
                globalEnvironment.showPaywall()
            }

        }) {
            ZStack {
                viewModel.enabled ? viewModel.backgroundColor : Color.gray.opacity(0.6)
                VStack {
//                    Spacer()
                    Image(systemName: viewModel.image)
                        .foregroundStyle(Color.text)
                    if let title = viewModel.title {
                        Text(LocalizedStringKey(title))
                            .font(.footnote)
                            .foregroundStyle(Color.text)
                    }
//                    Spacer()
                }
            }
            .cornerRadius(5)
        }
    }
}
