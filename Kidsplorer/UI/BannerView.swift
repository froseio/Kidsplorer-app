//
//  BannerView.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 15.02.2024.
//

import SwiftUI
import RevenueCatUI
import FirebaseAnalytics


struct BannerView: View {

    @State var subtitle: String
    @State var presented = false

    @EnvironmentObject
    private var globalEnvironment: GlobalEnvironment


    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Get premium")
                //                    .foregroundColor(.white)
                    .font(.headline)
                Text(subtitle)
                //                    .foregroundColor(.white)
                    .font(.subheadline)
            }
            .padding()
            Spacer()

            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundColor(.text)
                .padding(.trailing)
        }
        .onTapGesture {
            AnalyticsManager.track(.bannerTap)
            presented = true
        }
        .sheet(
            isPresented: self.$presented,
            content: {
                PaywallView()
                    .onRestoreCompleted({ customerInfo in
                        presented = false
                        globalEnvironment.checkCustomerInfo(customerInfo)
                    })
                    .onPurchaseCompleted({ customerInfo in
                        presented = false
                        globalEnvironment.checkCustomerInfo(customerInfo)
                    })
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                self.presented = false
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                    .analyticsScreen(name: "PaywallView_banner")
            })
        .background(Color.background)
    }
}
