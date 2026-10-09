//
//  DogClassifier.swift
//  DogClassifier
//
//  Created by yogita agarwal on 09/10/26.
//


import CoreML
import Vision
import UIKit

nonisolated enum ClassificationResult: Sendable {
    case dog([Prediction])   // top 3 breeds
    case noDog
}

nonisolated enum ClassifierError: LocalizedError {
    case modelMissing(String)
    case simulatorNotSupported

    var errorDescription: String? {
        switch self {
        case .modelMissing(let name):
            return "\(name) is not in the app bundle. Check its Target Membership."
        case .simulatorNotSupported:
            return "Core ML models don't work reliably on the Simulator. Please test on a real device."
        }
    }
}

nonisolated enum DogClassifier {

    /// How sure Vision must be that there's a dog (0 to 1). Tune after testing.
    static let dogThreshold: Float = 0.3

    // Your Create ML model, loaded once the first time it's used.
    nonisolated(unsafe) private static let breedModel = Result { try loadModel(named: "DogBreedClassifier") }

    /// Slow: call this off the main thread.
    static func classify(_ image: CGImage,
                         orientation: CGImagePropertyOrientation) throws -> ClassificationResult {
        // Create options dictionary for better Metal/GPU compatibility
        let options: [VNImageOption: Any] = [:]
        let handler = VNImageRequestHandler(cgImage: image, orientation: orientation, options: options)

        // 1. Is there a dog? Vision's built-in classifier, no model file needed.
        let sceneRequest = VNClassifyImageRequest()
        try handler.perform([sceneRequest])
        let scene = sceneRequest.results ?? []
        let hasDog = scene.contains { $0.identifier == "dog" && $0.confidence >= dogThreshold }
        guard hasDog else { return .noDog }

        // 2. Which breed? Your model's top 3 guesses.
        let model = try breedModel.get()
        let breedRequest = VNCoreMLRequest(model: model)
        breedRequest.imageCropAndScaleOption = .centerCrop
        
        try handler.perform([breedRequest])
        let breeds = breedRequest.results as? [VNClassificationObservation] ?? []  // best first
        let top3 = breeds.prefix(3).map {
            Prediction(breed: $0.identifier, confidence: Double($0.confidence))
        }
        return .dog(top3)
    }

    private static func loadModel(named name: String) throws -> VNCoreMLModel {
        // Xcode compiles each .mlmodel into a .mlmodelc folder inside the app.
        guard let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc") else {
            throw ClassifierError.modelMissing(name)
        }
        
        // Configure the model - use all available compute units (CPU, GPU, Neural Engine)
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all  // Use best available: Neural Engine > GPU > CPU
        
        do {
            let mlModel = try MLModel(contentsOf: url, configuration: configuration)
            return try VNCoreMLModel(for: mlModel)
        } catch {
            #if targetEnvironment(simulator)
            // Simulator often has Core ML issues - inform user
            throw ClassifierError.simulatorNotSupported
            #else
            throw error
            #endif
        }
    }
}

// Camera photos are stored sideways with a rotation flag. Vision needs that flag.
nonisolated extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

