//
//  HEICTransferable.swift
//  StereoImages
//
//  Created by Igor Ferreira on 27/09/2024.
//

import SwiftUI
import PhotosUI
import ImageIO

struct ImageContent: Hashable {
    let bitmap: CGImage
    let properties: CFDictionary?
}

struct SpatialImage: Hashable, Codable, Identifiable, Transferable {
    enum LoadingError: LocalizedError {
        case imageLoadingFailed
        
        var errorDescription: String? {
            "Failed to load image"
        }
    }
    enum CodingKeys: String, CodingKey {
        case id
        case data
    }
    
    let id: UUID
    let leftImage: ImageContent
    let righImage: ImageContent
    
    var hashValue: Int { id.hashValue }
    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let data = try container.decode(Data.self, forKey: .data)
        let images = try data.loadLeftRightImages()
        
        self.id = id
        self.leftImage = images.left
        self.righImage = images.right
    }
    
    func encode(to encoder: any Encoder) throws {
        let data = try write()
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(data, forKey: .data)
    }
    
    init(id: UUID, leftImage: ImageContent, rightImage: ImageContent) {
        self.id = id
        self.leftImage = leftImage
        self.righImage = rightImage
    }
    
    init (leftImage: ImageContent, rightImage: ImageContent) {
        self.id = UUID()
        self.leftImage = leftImage
        self.righImage = rightImage
    }
    
    init(_ data: Data) throws {
        let images = try data.loadLeftRightImages()
        id = UUID()
        leftImage = images.left
        righImage = images.right
    }

    func write() throws -> Data {
        let fileManager = FileManager.default
        let temporaryDirectory = fileManager.temporaryDirectory.path
        let sourceURL = URL(fileURLWithPath: temporaryDirectory)
            .appendingPathComponent("\(id).heic")
        guard let destination = CGImageDestinationCreateWithURL(
            sourceURL as CFURL,
            UTType.heic.identifier as CFString,
            2,
            [kCGImagePropertyPrimaryImage: 0] as CFDictionary
        ) else {
            throw LoadingError.imageLoadingFailed
        }
        CGImageDestinationAddImage(destination, leftImage.bitmap, leftImage.properties)
        CGImageDestinationAddImage(destination, righImage.bitmap, righImage.properties)
        guard CGImageDestinationFinalize(destination) else {
            throw LoadingError.imageLoadingFailed
        }
        return try Data(contentsOf: sourceURL)
    }
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .heic) { item in
            try item.write()
        } importing: { data in
            try SpatialImage(data)
        }
    }
}

extension Data {
    func loadLeftRightImages() throws -> (left: ImageContent, right: ImageContent) {
        guard let source = CGImageSourceCreateWithData(self as CFData, nil),
              let leftImage = CGImageSourceCreateImageAtIndex(source, 0, nil),
              let rightImage = CGImageSourceCreateImageAtIndex(source, 1, nil) else {
            throw URLError(URLError.cannotDecodeContentData)
        }
        return (
            .init(bitmap: leftImage, properties: CGImageSourceCopyPropertiesAtIndex(source, 0, nil)),
            .init(bitmap: rightImage, properties: CGImageSourceCopyPropertiesAtIndex(source, 1, nil))
        )
    }
}

extension PhotosPickerItem {
    func loadSpatialImage() async throws -> SpatialImage? {
        return try await withCheckedThrowingContinuation { continuation in
            loadTransferable(type: SpatialImage.self) { result in
                switch result {
                    case .failure(let error): continuation.resume(throwing: error)
                    case .success(let image): continuation.resume(returning: image)
                }
            }
        }
    }
}
