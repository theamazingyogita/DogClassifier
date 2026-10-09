//
//  Prediction.swift
//  DogClassifier
//
//  Created by yogita agarwal on 09/10/26.
//

import Foundation

nonisolated struct Prediction: Identifiable, Sendable {
    let id = UUID()
    let breed: String
    let confidence: Double
    
    var displayName: String {
        breed.replacingOccurrences(of: "_", with: " ")
    }
    
    var percentText: String {
        String(format: "%.1f%%", confidence * 100)
    }
}
