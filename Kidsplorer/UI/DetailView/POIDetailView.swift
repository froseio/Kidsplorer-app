//
//  POIDetailView.swift
//  Kidsplorer
//
//  Created by Filip Růžička on 15.02.2024.
//

import SwiftUI
import Shared
import CoreLocation
import GooglePlaces
import MapKit
import StoreKit
import SwiftData

struct POIDetailView: View {

    let poi: POIModel

    @State
    var detail: POIDetailModel?

    @State
    private var isLoading = true

    var id: String {
        poi.id
    }

    var body: some View {
        if isLoading {
            loadingView
                .task {
                    await loadDetail()
                }
        }
        else if let detail {
            detailView(detail)
                .toolbarBackground(.hidden, for: .navigationBar)
                .analyticsScreen(name: "Detail view")
        }
        else {
            errorView
                .analyticsScreen(name: "Detail error")
        }
    }

    var errorView: some View {
        VStack {
            Spacer()
            Text("Sorry, something went wrong")
                .font(.headline)
                .padding()
            Button("Try again") {
                isLoading = true
                AnalyticsManager.track(.tryAgainDetail)
            }
            .font(.subheadline)
            .foregroundColor(Color.red)
            .padding()

            Spacer()
        }
    }

    var loadingView: some View {
        ProgressView()
    }

    func detailView(_ detail: POIDetailModel) -> some View {
        PoiDetailSubView(poi: poi, detail: detail)
    }

    func loadDetail() async {

        guard let id = poi.gpid else {
            DispatchQueue.main.async {
                isLoading = false
            }
            return
        }

        DispatchQueue.main.async {
            isLoading = true
        }

        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"

        let reqModel = PlacesEndpoint.GetDetailPlace.Request(
            gpid: id,
            isPremium: UserDefaultsManager.shared.isPremium,
            lang: languageCode
        )

        let endpoint = PlacesEndpoint.GetDetailPlace(
            requestModel: reqModel
        )

        let response = try? await CCAPIClient.shared.load(endpoint: endpoint)

        DispatchQueue.main.async {

            isLoading = false

            if let d = response?.detail {
                self.detail = d

                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
    }
}

fileprivate struct PoiDetailSubView: View {

    let poi: POIModel
    let detail: POIDetailModel

    @ObservedObject
    private var imgLoader: PlaceImgLoader

    @EnvironmentObject
    private var globalEnvironment: GlobalEnvironment

    @Environment(\.openURL)
    var openURL

    @State
    var alternativeAddress: String = ""

    @State
    var nearby: [MKMapItem] = []

    @State
    var gphotoMetadata: [GMSPlacePhotoMetadata] = []

    @Environment(\.modelContext)
    private var modelContext

    @Query
    var allFavorites: [FavoritePoi]

    @Query(sort: \VisitedPoi.visitedDate, order: .reverse)
    var checkins: [VisitedPoi]

    init(poi: POIModel, detail: POIDetailModel) {
        self.poi = poi
        self.detail = detail

        self.imgLoader = PlaceImgLoader(
            id: poi.id,
            location: CLLocation(latitude: poi.lat, longitude: poi.lon)
        )
    }

    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                imagesView(gimages: gphotoMetadata)
                    .frame(height: 300)

                mainView
                    .padding(.horizontal)

                summaryView

                HStack {
                    Button(action: {
                        AnalyticsManager.track(.checkin)
                        let checkPoi = VisitedPoi(
                            lat: poi.lat,
                            lon: poi.lon,
                            name: poi.name,
                            category: poi.category,
                            gpid: poi.gpid,
                            visitedDate: Date())
                        modelContext.insert(checkPoi)

                    }, label: {
                        HStack {
                            Spacer()
                            VStack {
                                Text("Check in")
                            }
                            .foregroundColor(.text)
                            Spacer()
                        }
                    })
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.background)
                    }


                    if let fav = allFavorites.first(where: {$0.id == poi.id}) {
                        Button(action: {
                            modelContext.delete(fav)
                            AnalyticsManager.track(.rm_favorite)
                        }, label: {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(Color.red)
                        })
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(.background)
                        }
                    }
                    else {
                        Button(action: {
                            AnalyticsManager.track(.add_favorite)
                            let fp = FavoritePoi(
                                lat: poi.lat,
                                lon: poi.lon,
                                name: poi.name,
                                category: poi.category,
                                gpid: poi.gpid
                            )
                            modelContext.insert(fp)

                        }, label: {
                            Image(systemName: "heart")
                                .foregroundStyle(Color.red)
                        })
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(.background)
                        }
                    }

                }
                .padding()

                if let fav = checkins.first(where: {$0.id == poi.id}) {
                    Text("Last visited \(fav.visitedDate, formatter: itemFormatter)")
                        .font(.footnote)
                        .padding(.horizontal)
                }

                addressView

                contactView

                if let openningHours = detail.openningHours {
                    openningHoursView(openningHours)
                }

                if let comments = detail.comments {
                    commentsView(comments: comments)
                }

                if !nearby.isEmpty {
                    nearbyPois(items: nearby)
                }

                Spacer()
            }
        }
        .task {
            imgLoader.getImage()
            loadPhotos()

            do {
                let addr = try await CLGeocoder().getAddress(coordinate: CLLocationCoordinate2D(latitude: poi.lat, longitude: poi.lon))
                DispatchQueue.main.async {
                    self.alternativeAddress = addr
                }
            }
            catch {
                alternativeAddress = "Unknown address"
            }

            do {
                let nearby = try await searchNearby()
                DispatchQueue.main.async {
                    self.nearby = nearby
                }
            }
            catch {
                logger.error("\(error.localizedDescription)")
            }
        }
    }


    // MARK: - Common views
    @State var imgSelection = 0

    func imagesView(gimages: [GMSPlacePhotoMetadata]) -> some View {
        TabView(selection: $imgSelection) {
            if !UserDefaultsManager.shared.isPremium {
                premiumPlaceholderView()
                    .tag(0)
            }

            ForEach(Array(gimages.enumerated()), id: \.element.description) { (index, photoMetadata) in
                PlacePhotoView(photoMetadata: photoMetadata)
                    .clipped()
                    .tag(index + 1) // Adjust the tag to align with the array index + 1 for premium placeholder
            }

            if let lastImg = imgLoader.image {
                Image(uiImage: lastImg)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                    .tag(gimages.count + 1) // Ensure the tag is unique and follows the images array
            }
            else {
                ProgressView()
                    .tag(gimages.count + 1) // Use the same tag as the last image for consistency
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .clipped()
    }

    private func premiumPlaceholderView() -> some View {
        ZStack {
            if let lastImg = imgLoader.image {
                Image(uiImage: lastImg)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 4)
            }

            Rectangle()
                .foregroundStyle(Color.black)
                .opacity(0.4)

            VStack {
                Text("Get premium")
                    .font(.headline)

                Text("to load more images")
                    .font(.subheadline)
            }
            .foregroundStyle(Color.white)
        }
        .onTapGesture {
            globalEnvironment.showPaywall()
        }
    }

    var mainView: some View {
        HStack {
            Text(poi.name)
                .font(.headline)
                .padding(.vertical)

            Spacer()

            if UserDefaultsManager.shared.isPremium {
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName:
                                index < Int((detail.rating ?? 1) + 1) ? "star.fill" : "star"
                        )
                        .foregroundColor(.yellow)
                    }
                }
                .font(.headline)
            }
        }
    }

    var addressView: some View {
        HStack() {
            VStack(alignment: .leading) {
                HStack {
                    Text("Address")
                        .font(.footnote)
                    Spacer()
                }
                Text(detail.address ?? alternativeAddress)
            }
            Spacer()
            Button(action: {
                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: poi.coordinate))
                mapItem.openInMaps()
                AnalyticsManager.track(.openInMap)
            }, label: {
                Image(systemName: "map")
                    .bold()
                    .foregroundColor(.text)
                    .padding()
                    .background(Color.playgroundBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 5))                
            })

        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .foregroundStyle(Color.background)
        }
        .padding()
    }

    var contactView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let phone = detail.phone, !phone.isEmpty {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Phone")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    Text(phone)
                        .font(.body)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 15).fill(Color.background))
                .onTapGesture {
                    if let urlToOpen = URL(string: "tel://\(phone)") {
                        openURL(urlToOpen)
                    }
                }
            }

            if let url = detail.url, !url.isEmpty {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Web")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    Text(url)
                        .font(.body)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 15).fill(Color.background))
                .onTapGesture {
                    if let urlToOpen = URL(string: url) {
                        openURL(urlToOpen)
                    }
                }
            }

            // TODO: Email
//            if let email = detail.email, !email.isEmpty { // Předpokládám, že existuje vlastnost 'email' v modelu 'POIDetailModel'
//                VStack(alignment: .leading) {
//                    Text("E-mail")
//                        .font(.footnote)
//                        .foregroundColor(.secondary)
//                    Text(email)
//                        .font(.body)
//                }
//                .padding()
//                .background(RoundedRectangle(cornerRadius: 15).fill(Color.background))
//            }
        }
        .padding(.horizontal)
    }


    func openningHoursView(_ openningHours: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Openning hours")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
            }
            Text(openningHours)
                .font(.body)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.background)
        }
        .padding(.horizontal)
    }


    // MARK: - Premium views

    var summaryView: some View {
        // TODO: parking options
        
        VStack {
            Divider()

            HStack {
                if let isOpen = detail.isOpen {
                    if isOpen {
                        Text("Open")
                            .foregroundStyle(Color.green)
                            .bold()
                    }
                    else {
                        Text("Closed")
                            .foregroundStyle(Color.red)
                            .bold()
                    }

                    Divider()
                }

                if let restroom = detail.restroom, restroom {
                    Image(systemName: "toilet")
                }

                if let dogFriendly = detail.dogFriendly, dogFriendly {
                    Image(systemName: "dog")
                }

                if let priceLevel = detail.priceLevel {
                    Divider()

                    ForEach(0..<Int(priceLevel + 1), id: \.self) { _ in
                        Text("$")
                    }
                }

                if let paymentOptions = detail.paymentOptions {
                    Divider()

                    ForEach(paymentOptions, id: \.self) { p in
                        Image(systemName: p)
                    }
                }

                Spacer()
            }
            .padding(.horizontal)

            if !UserDefaultsManager.shared.isPremium {
                BannerView(subtitle: "to load all detailed informations, photos and reviews about this place.")
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding()
            }

            Divider()
        }
    }

    func commentsView(comments: [String]) -> some View {

        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(comments.filter({ !$0.isEmpty }).enumerated()), id: \.element) { index, comment in
                if index % 2 == 0 { // Sudé indexy
                    ChatBubble(direction: .left) {
                        Text(comment)
                            .padding()
                            .foregroundColor(.text)
                            .background(poi.category.color)
                    }
                }
                else {
                    ChatBubble(direction: .right) {
                        Text(comment)
                            .padding()
                            .foregroundColor(.text)
                            .background(poi.category.color)
                    }
                }
            }
        }
        .padding(.horizontal)
    }


    @ViewBuilder
    func nearbyPois(items: [MKMapItem]) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Nearby")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
            }
            ForEach(UserDefaultsManager.shared.isPremium ? items : Array(items.prefix(3))) { i in
                if let name = i.placemark.name {
                    HStack {
                        Text(name)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding(5)
                    .onTapGesture {
                        i.openInMaps()
                    }
                }
            }

            if !UserDefaultsManager.shared.isPremium {
                Text("Become premium to load more nearest places")
                    .font(.footnote)
                    .onTapGesture {
                        globalEnvironment.showPaywall()
                    }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.background)
        }
        .padding(.horizontal)
    }

    
    // MARK: - Non premium views

    var nonpremiumView: some View {
        EmptyView()
    }


    // MARK: - Helper func

    func searchNearby() async throws -> [MKMapItem] {
        let poiRequest: MKLocalPointsOfInterestRequest = MKLocalPointsOfInterestRequest(
            center: CLLocationCoordinate2D(
                latitude: poi.lat,
                longitude: poi.lon),
            radius: 1_000
        )
        poiRequest.pointOfInterestFilter = .init(including: [
            .amusementPark,
            .aquarium,
            .bakery,
            .beach,
            .cafe,
            .library,
            .museum,
            .zoo,
            .restaurant,
            .theater
        ])


        let localSearch = MKLocalSearch(request: poiRequest)
        let response = try await localSearch.start()

        return response.mapItems
    }

    func loadPhotos() {
        guard let placeId = poi.gpid else {
            return
        }

        GMSPlacesClient
            .shared()
            .fetchPlace(
                fromPlaceID: placeId,
                placeFields: [.photos],
                sessionToken: nil)
        { place, err in
            if let photos = place?.photos {
                self.gphotoMetadata = photos
            }
        }
    }


}

fileprivate struct PlacePhotoView: View {
    
    var photoMetadata: GMSPlacePhotoMetadata

    @State
    private var image: UIImage? = nil

    var body: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipped()
        }
        else {
            ProgressView()
                .onAppear(perform: loadImage)
        }
    }

    private func loadImage() {
        guard image == nil else {
            return
        }

        GMSPlacesClient.shared().loadPlacePhoto(photoMetadata, callback: { (photo, error) -> Void in
            if let error = error {
                logger.error("Error loading photo metadata: \(error.localizedDescription)")
                return
            } else {
                self.image = photo
            }
        })
    }
}

struct ChatBubble<Content>: View where Content: View {
    let direction: ChatBubbleShape.Direction
    let content: () -> Content
    init(direction: ChatBubbleShape.Direction, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.direction = direction
    }

    var body: some View {
        HStack {
            if direction == .right {
                Spacer()
            }
            content().clipShape(ChatBubbleShape(direction: direction))
            if direction == .left {
                Spacer()
            }
        }.padding([(direction == .left) ? .leading : .trailing, .top, .bottom], 20)
            .padding((direction == .right) ? .leading : .trailing, 50)
    }
}

struct ChatBubbleShape: Shape {
    enum Direction {
        case left
        case right
    }

    let direction: Direction

    func path(in rect: CGRect) -> Path {
        return (direction == .left) ? getLeftBubblePath(in: rect) : getRightBubblePath(in: rect)
    }

    private func getLeftBubblePath(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let path = Path { p in
            p.move(to: CGPoint(x: 25, y: height))
            p.addLine(to: CGPoint(x: width - 20, y: height))
            p.addCurve(to: CGPoint(x: width, y: height - 20),
                       control1: CGPoint(x: width - 8, y: height),
                       control2: CGPoint(x: width, y: height - 8))
            p.addLine(to: CGPoint(x: width, y: 20))
            p.addCurve(to: CGPoint(x: width - 20, y: 0),
                       control1: CGPoint(x: width, y: 8),
                       control2: CGPoint(x: width - 8, y: 0))
            p.addLine(to: CGPoint(x: 21, y: 0))
            p.addCurve(to: CGPoint(x: 4, y: 20),
                       control1: CGPoint(x: 12, y: 0),
                       control2: CGPoint(x: 4, y: 8))
            p.addLine(to: CGPoint(x: 4, y: height - 11))
            p.addCurve(to: CGPoint(x: 0, y: height),
                       control1: CGPoint(x: 4, y: height - 1),
                       control2: CGPoint(x: 0, y: height))
            p.addLine(to: CGPoint(x: -0.05, y: height - 0.01))
            p.addCurve(to: CGPoint(x: 11.0, y: height - 4.0),
                       control1: CGPoint(x: 4.0, y: height + 0.5),
                       control2: CGPoint(x: 8, y: height - 1))
            p.addCurve(to: CGPoint(x: 25, y: height),
                       control1: CGPoint(x: 16, y: height),
                       control2: CGPoint(x: 20, y: height))

        }
        return path
    }

    private func getRightBubblePath(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let path = Path { p in
            p.move(to: CGPoint(x: 25, y: height))
            p.addLine(to: CGPoint(x:  20, y: height))
            p.addCurve(to: CGPoint(x: 0, y: height - 20),
                       control1: CGPoint(x: 8, y: height),
                       control2: CGPoint(x: 0, y: height - 8))
            p.addLine(to: CGPoint(x: 0, y: 20))
            p.addCurve(to: CGPoint(x: 20, y: 0),
                       control1: CGPoint(x: 0, y: 8),
                       control2: CGPoint(x: 8, y: 0))
            p.addLine(to: CGPoint(x: width - 21, y: 0))
            p.addCurve(to: CGPoint(x: width - 4, y: 20),
                       control1: CGPoint(x: width - 12, y: 0),
                       control2: CGPoint(x: width - 4, y: 8))
            p.addLine(to: CGPoint(x: width - 4, y: height - 11))
            p.addCurve(to: CGPoint(x: width, y: height),
                       control1: CGPoint(x: width - 4, y: height - 1),
                       control2: CGPoint(x: width, y: height))
            p.addLine(to: CGPoint(x: width + 0.05, y: height - 0.01))
            p.addCurve(to: CGPoint(x: width - 11, y: height - 4),
                       control1: CGPoint(x: width - 4, y: height + 0.5),
                       control2: CGPoint(x: width - 8, y: height - 1))
            p.addCurve(to: CGPoint(x: width - 25, y: height),
                       control1: CGPoint(x: width - 16, y: height),
                       control2: CGPoint(x: width - 20, y: height))

        }
        return path
    }
}
