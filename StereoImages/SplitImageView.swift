//
//  SplitImageView.swift
//  StereoImages
//
//  Created by Igor Ferreira on 27/09/2024.
//

import SwiftUI
import PhotosUI

struct SplitImageView: View {
    
    class ImageSaver: NSObject {
        func writeToPhotoAlbum(image: UIImage) {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
        }

        @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
            print("Save finished!")
        }
    }
    
    @State var photoItem: PhotosPickerItem?
    
    var body: some View {
        PhotosPicker("Select image to split", selection: $photoItem, matching: .images)
            .padding()
            .glassBackgroundEffect()
            .onChange(of: photoItem) { _, item in
                Task { await splitImage(item: item) }
            }
    }
    
    private func splitImage(item: PhotosPickerItem?) async {
        guard let item, let image = try? await item.loadSpatialImage() else { return }
        
        let leftImage = UIImage(cgImage: image.leftImage.bitmap)
        let rightImage = UIImage(cgImage: image.righImage.bitmap)
        
        let imageSaver = ImageSaver()
        imageSaver.writeToPhotoAlbum(image: leftImage)
        imageSaver.writeToPhotoAlbum(image: rightImage)
    }
}
