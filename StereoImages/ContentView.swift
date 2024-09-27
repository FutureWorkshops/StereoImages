//
//  ContentView.swift
//  StereoImages
//
//  Created by 凌嘉徽 on 2024/8/10.
//

import SwiftUI
import RealityKit
import DoubleEye
import PhotosUI

struct ContentView: View {
    @State
    var leftEyeImage:PhotosPickerItem? = nil
    @State
    var rightEyeImage:PhotosPickerItem? = nil
    @State
    var bothEyeImage:PhotosPickerItem? = nil
    @State
    var imagePack:StereoImagePack? = nil
    @State
    var loading = false
    @Environment(\.openWindow)
    var openWindow
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    VStack {
                        if let _ = leftEyeImage {
                            Label("Left Eye Image Picked", systemImage: "checkmark")
                        }
                        PhotosPicker("Pick Left Eye Image", selection: $leftEyeImage, matching: .images)
                    }
                    .padding()
                    VStack {
                        if let _ = rightEyeImage {
                            Label("Right Eye Image Picked", systemImage: "checkmark")
                        }
                        PhotosPicker("Pick Right Eye Image", selection: $rightEyeImage, matching: .images)
                    }
                    .padding()
                    
                    if leftEyeImage == nil && rightEyeImage == nil {
                        VStack {
                            PhotosPicker("Pick Both Images", selection: $bothEyeImage, matching: .images)
                        }
                    }
                }
                
                if let leftEyeImage,let rightEyeImage {
                    Button("Next", action: {
                        loading = true
                        Task {
                            do {
                                let leftUIImage = try await leftEyeImage.loadTransferable(type: Data.self)!
                                let rightUIImage = try await rightEyeImage.loadTransferable(type: Data.self)!
                                self.imagePack = .init(left: parse(leftUIImage)!, right: parse(rightUIImage)!)
                            } catch {
                                fatalError(error.localizedDescription)
                            }
                            loading = false
                        }
                    })
                    .buttonStyle(.borderedProminent)
                    .disabled(loading)
                    .overlay(alignment: .center) {
                        if loading {
                            ProgressView()
                        }
                    }
                }  else {
                    Text("Please pick images before continue.")
                }
                
            }
            .navigationDestination(item: $imagePack) {
                StoereoPhotoView(imagePack: $0)
            }
            .onChange(of: bothEyeImage) { _, newValue in
                if let newValue {
                    Task { await loadSeparatedEyes(item: newValue) }
                }
            }
        }
    }
    
    func parse(_ data: Data) -> CGImage? {
        return UIImage(data: data)?.cgImage
    }
    
    func loadSeparatedEyes(item: PhotosPickerItem) async {
        guard let images = try? await item.loadSpatialImage() else {
            return
        }
        self.imagePack = .init(
            left: images.leftImage.bitmap,
            right: images.leftImage.bitmap
        )
        bothEyeImage = nil
    }
}

struct StereoImagePack:Identifiable,Hashable {
    var id = UUID()
    var left: CGImage
    var right: CGImage
}

struct StoereoPhotoView: View {
    var imagePack:StereoImagePack
    @State
    var vm = ViewModel()
    var body: some View {
        RealityView { content in
            do {
                let card = try await {
                    var matX = try await ShaderGraphMaterial(named: "/Root/Material",
                                                             from: "Scene.usda",
                                                             in: doubleEyeBundle)
                    
                    let imgLeft = imagePack.left
                    let left =  try await vm.generateMaterial(imgLeft)
                    try matX.setParameter(name: "LeftEye", value: .textureResource(left))
                    
                    let imgRight = imagePack.right
                    let right =  try await vm.generateMaterial(imgRight)
                    try matX.setParameter(name: "RightEye", value: .textureResource(right))
                    
                    
                    //if a image is 1920x1080 the plane size is 0.192x0.108
                    let entity = ModelEntity(mesh: .generatePlane(
                        width: Float(imgLeft.width)/10000,
                        height: Float(imgLeft.height)/10000,
                        cornerRadius: 0.01
                    ))
                    
                    
                    
                    entity.model?.materials = [matX]
                    return entity
                }()
                content.add(card)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        Text("Using physics device to see right eye image.")
            .font(.title)
            .padding()
    }
}

@Observable
class ViewModel {
    func generateMaterial(_ cgImg: CGImage) async throws -> TextureResource {
        let texture = try await TextureResource(
            image: cgImg,
            options: .init(semantic: .hdrColor)
        )
        
        return texture
    }
    enum ViewError:Error,LocalizedError {
        case error1
    }
}


#Preview(windowStyle: .automatic) {
    ContentView()
}
