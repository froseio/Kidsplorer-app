//
//  OnboardingView.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 19.02.2024.
//

import SwiftUI
import RevenueCatUI
import Shared

struct OnboardingView: View {

    @EnvironmentObject
    var globalEnvironment: GlobalEnvironment

    @State
    var itemSelection = 0

    private let onboardingItems = 3

    var body: some View {
        ZStack(alignment: .top) {


            Rectangle()
                .foregroundColor(Color.playground)
                .ignoresSafeArea()
                .opacity(0.3)

            Image(.playgroundBackground)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()
                .opacity(0.1)

            if itemSelection < onboardingItems {
                VStack {
                    TabView(selection: $itemSelection) {

                        IntroView1()
                            .padding(.top)
                            .tag(0)

                        IntroView2 {
                            itemSelection += 1
                        }
                        .padding(.top)
                        .tag(1)

                        IntroView3()
                            .padding(.top)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))

                    HStack {
                        Button("Skip") {
                            itemSelection = onboardingItems
                            AnalyticsManager.track(.skipIntro)
                        }
                        .foregroundColor(.text)
                        .padding()

                        Button {
                            itemSelection += 1
                            AnalyticsManager.track(.nextIntro)

                        } label: {
                            HStack {
                                Spacer()
                                Text("Next")
                                    .foregroundColor(.background)
                                    .bold()
                                Spacer()
                            }
                            .padding()
                            .background(Color.text)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .padding()
                        }

                    }
                }
            }
            else {
                ZStack(alignment: .topTrailing) {
                    PaywallView()
                        .onPurchaseCompleted { ci in
                            globalEnvironment.checkCustomerInfo(ci)
                            globalEnvironment.displayIntro = false
                            UserDefaultsManager.shared.introWasPresented = true
                            AnalyticsManager.track(.buyFromintro)
                        }
                        .onRestoreCompleted { ci in
                            globalEnvironment.checkCustomerInfo(ci)
                            globalEnvironment.displayIntro = false
                            UserDefaultsManager.shared.introWasPresented = true
                            AnalyticsManager.track(.restoreFromintro)
                        }
                        .analyticsScreen(name: "PaywallView_onboarding")
                        .ignoresSafeArea()

                    Button("Skip") {
                        AnalyticsManager.track(.skipIntroPaywall)
                        globalEnvironment.displayIntro = false
                        UserDefaultsManager.shared.introWasPresented = true
                    }
                    .foregroundColor(Color.black)
                    .padding()
                }
            }
        }
    }


    func hideIntro() {
        UserDefaultsManager.shared.introWasPresented = true
        globalEnvironment.displayIntro = false
    }
}

fileprivate struct IntroView1: View {

    var body: some View {
        VStack {
            Text("Filter by categories")
                .font(.title)
                .bold()
                .padding()

            Text("Pick categories you want to see")
                .font(.caption)
                .padding()

            Spacer()

            VStack(alignment: .leading) {
                ForEach(POICategory.allCases, id: \.rawValue) { c in
                    HStack {
                        ZStack {
                            Color(c.color)
                            Image(systemName: c.imageName)
                                .scaledToFit()
                                .foregroundColor(Color.text)
                                .padding(5)
                        }
                        .clipShape(Circle())
                        .frame(width: 30, height: 30)

                        VStack(alignment: .leading) {
                            Text(c.title)
                                .bold()
                            Text(c.desc)
                                .font(.footnote)
                        }
                    }
                    Spacer()
                }
            }

            Spacer()
        }
        .padding()
    }
}

fileprivate struct IntroView2: View {

    var next: ()->()

    var body: some View {
        VStack {

            Text("Location")
                .font(.title)
                .bold()
                .padding()
            Text("Enable handling location to show places near you")
                .font(.subheadline)

            Spacer()

            Button(action: {
                _ = LocationManager.shared
                next()
            }, label: {
                Text("Enable")
                    .foregroundStyle(Color.background)
                    .padding()
                    .background(Color.text)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding()
            })

            Text("or try search to find location where you travel")
                .font(.footnote)

            Spacer()
        }
    }
}


fileprivate struct IntroView3: View {

    let features = ["Photos", "Reviews", "Opening hour", "Place contact", "Nearby places to rest, eat or explore"]
    let colors = POICategory.allCases.map({ $0.color })

    var body: some View {
        VStack {

            Text("On detail you can find")
                .font(.title)
                .bold()
                .padding()

            Spacer()

            ForEach(Array(features.enumerated()), id: \.element) { index, feature in
                VStack {
                    HStack {
                        if index % 2 == 0 {
                            Text(feature)
                                .padding()
                                .background(colors[index])
                                .cornerRadius(20)
                                .padding(.leading, CGFloat.random(in: 0...50))
                            Spacer()
                        } else {
                            Spacer()
                            Text(feature)
                                .padding()
                                .background(colors[index])
                                .cornerRadius(20)
                                .padding(.trailing, CGFloat.random(in: 0...50))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
            }

            Spacer()
        }
    }
}



#Preview {
    OnboardingView()
}
