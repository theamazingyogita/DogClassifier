//
//  ClassifierViewModel.swift
//  DogClassifier
//
//  Created by yogita agarwal on 09/10/26.
//

import SwiftUI
import PhotosUI
import CoreGraphics
import ImageIO
import CoreML
import Vision
import UIKit

@MainActor
@Observable
final class ClassifierViewModel {
    var image: UIImage?
    var predictions: [Prediction] = []
    var status = "Pick or take a photo of a dog."
    var isWorking = false

    func load(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            status = "Couldn't load that photo."
            return
        }
        await classify(image)
    }

    func classify(_ image: UIImage) async {
        self.image = image
        predictions = []
        guard let cgImage = image.cgImage else {
            status = "Unsupported image format."
            return
        }
        let orientation = image.imageOrientation.toCGImagePropertyOrientation()

        isWorking = true
        status = "Looking for a dog…"
        defer { isWorking = false }

        do {
            // Heavy ML work runs off the main thread so the UI stays smooth.
            let result = try await Task.detached(priority: .userInitiated) {
                try DogClassifier.classify(cgImage, orientation: orientation)
            }.value

            switch result {
            case .dog(let top3):
                predictions = top3
                status = "Top 3 breeds"
            case .noDog:
                status = "No dog found. Try a closer photo with the dog in the centre."
            }
        } catch {
            status = error.localizedDescription
        }
    }
}

// Helper extension to convert UIImage.Orientation to CGImagePropertyOrientation
private extension UIImage.Orientation {
    func toCGImagePropertyOrientation() -> CGImagePropertyOrientation {
        switch self {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
