//
//  LoadView.swift
//  StereoImages
//
//  Created by Igor Ferreira on 27/09/2024.
//

import SwiftUI
import PhotosUI

struct LoadView: View {
    @State var spatialImage: SpatialImage? = nil
    @State var photoPickerItem: PhotosPickerItem? = nil
    
    var body: some View {
        ZStack {
            if let spatialImage {
                imageArray(spatialImage)
            } else {
                imagePicker()
            }
        }.onChange(of: photoPickerItem) { _, newValue in
            loadImages(newValue)
        }
    }
    
    @ViewBuilder
    private func imagePicker() -> some View {
        PhotosPicker("Pick image", selection: $photoPickerItem, matching: .images)
            .padding()
            .glassBackgroundEffect()
    }
    
    @ViewBuilder
    private func imageArray(_ image: SpatialImage) -> some View {
        List {
            Text("Sizes: ")
            Text("Left: \(image.leftImage.bitmap.width) x \(image.leftImage.bitmap.height)")
            Text("Right: \(image.righImage.bitmap.width) x \(image.righImage.bitmap.height)")
            Image(image.leftImage.bitmap, scale: 10, label: Text("Left image"))
            Image(image.righImage.bitmap, scale: 10, label: Text("Right image"))
        }
    }
    
    private func loadImages(_ item: PhotosPickerItem?) { Task {
        guard let item else { return }
        spatialImage = try? await item.loadSpatialImage()
    }}
}

#Preview {
    LoadView()
}
