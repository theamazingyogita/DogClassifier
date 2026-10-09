//
//  ContentView.swift
//  DogClassifier
//
//  Created by yogita agarwal on 09/10/26.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var model = ClassifierViewModel()
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                photo

                if model.isWorking { ProgressView() }
                Text(model.status)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                ForEach(model.predictions) { prediction in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(prediction.displayName.capitalized)
                            Spacer()
                            Text(prediction.percentText).monospacedDigit()
                        }
                        ProgressView(value: prediction.confidence)
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("Library", systemImage: "photo")
                    }
                    .buttonStyle(.borderedProminent)

                    Button { showCamera = true } label: {
                        Label("Camera", systemImage: "camera")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                }
                .disabled(model.isWorking)
            }
            .padding()
            .navigationTitle("Dog Breed")
            .onChange(of: pickerItem) { _, item in
                Task { await model.load(item) }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    Task { await model.classify(image) }
                }
                .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder private var photo: some View {
        if let image = model.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            Image(systemName: "dog")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
                .frame(height: 300)
        }
    }
}

#Preview { ContentView() }
