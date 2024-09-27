//
//  StereoImagesApp.swift
//  StereoImages
//
//  Created by 凌嘉徽 on 2024/8/10.
//

import SwiftUI

@main
struct StereoImagesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
//            LoadView()
//            SplitImageView()
        }
        WindowGroup(id: "image", for: SpatialImage.self) { binding in
            if let image = binding.wrappedValue {
                StoereoPhotoView(imagePack: .init(
                    id: image.id,
                    left: image.leftImage.bitmap,
                    right: image.righImage.bitmap
                ))
                .padding()
                .glassBackgroundEffect()
            }
        }
        .windowStyle(.plain)
    }
}
