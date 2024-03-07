//
//  PlaceImgLoader.swift
//  ChargeNChill
//
//  Created by Filip Růžička on 13.12.2023.
//

import Foundation

import MapKit
import SwiftUI

class PlaceImgLoader: ObservableObject {

    static let imageLoadingQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    @Published var image: UIImage?

    private var id: String
    private var location: CLLocationCoordinate2D
    private var reloadNextTime: Bool = false
    private var imgSize = CGSize(width: 500, height: 500)

    public init(id: String, location: CLLocation) {
        self.id = id
        self.location = location.coordinate
    }

    public func getImage() {
        Self.imageLoadingQueue.addOperation { [weak self] in
            guard let self = self else { return }

            guard
                self.image == nil || self.reloadNextTime else {
                return
            }

            if let cachedImage = self.loadImageFromFileSystem() {
                DispatchQueue.main.async {
                    self.image = cachedImage
                }
            } else {
                self.loadImage()
            }
        }
    }

    private func saveImageToFileSystem(image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else { return }
        guard 
            let filePath = self.getFilePath()
        else {
            return
        }

        do {
            try data.write(to: filePath)
        } catch {
            logger.error("Error saving image: \(error.localizedDescription)")
        }
    }

    private func loadImageFromFileSystem() -> UIImage? {
        guard
            let filePath = getFilePath()?.path
        else {
            return nil
        }
        return UIImage(contentsOfFile: filePath)
    }

    private func getFilePath() -> URL? {
        let fileManager = FileManager.default
        guard let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return directory.appendingPathComponent("\(id).png")
    }

    private func loadImage(attempt: Int = 1) {
        Task {
            do {
                let sceneRequest = MKLookAroundSceneRequest(coordinate: location)
                guard let scene = try await sceneRequest.scene else {
                    logger.error("No scene for location \(self.location.latitude) x \(self.location.longitude)")
                    if attempt < 4 {
                        loadImage(attempt: attempt + 1)
                    } else {
                        loadMapImg()
                    }
                    return
                }

                let options = MKLookAroundSnapshotter.Options()
                options.size = imgSize

                let img = try await MKLookAroundSnapshotter(scene: scene, options: options).snapshot.image

                saveImageToFileSystem(image: img)

                reloadNextTime = false

                DispatchQueue.main.async {
                    self.image = img
                }
            } catch {
                logger.error("Error loading image: \(error.localizedDescription)")
                if attempt < 4 {
                    loadImage(attempt: attempt + 1)
                } else {
                    loadMapImg()
                }
            }
        }
    }


    private func loadMapImg() {
        guard image == nil else { return }
        let options: MKMapSnapshotter.Options = .init()
        options.region = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(
                latitudeDelta: 0.0001,
                longitudeDelta: 0.0001
            )
        )
        options.size = imgSize
        options.mapType = .satelliteFlyover
        options.showsBuildings = true

        let camera = MKMapCamera()
        camera.centerCoordinate = location
        camera.pitch = 45.0
        camera.centerCoordinateDistance = 10
        options.camera = camera

        let snapshotter = MKMapSnapshotter(options: options)

        snapshotter.start { snapshot, error in
            if let snapshot = snapshot {
                self.reloadNextTime = true
                DispatchQueue.main.async {
                    self.image = snapshot.image
                    self.objectWillChange.send()
                }
            } else if let error = error {
                logger.error("Something went wrong \(error.localizedDescription)")
            }
        }
    }
}

