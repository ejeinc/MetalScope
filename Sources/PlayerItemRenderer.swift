//
//  PlayerItemRenderer.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2016/12/13.
//  Copyright © 2016 eje Inc. All rights reserved.
//

#if (arch(arm) || arch(arm64)) && os(iOS)

import Metal
import AVFoundation

public final class PlayerItemRenderer {
    private let textureCache: CVMetalTextureCache

    public let device: MTLDevice

    public let videoOutput: AVPlayerItemVideoOutput

    public var playerItem: AVPlayerItem? {
        willSet {
            if let item = playerItem {
                unbind(item)
            }
        }
        didSet {
            if let item = playerItem {
                bind(item)
            }
        }
    }

    public init(device: MTLDevice, videoOutput: AVPlayerItemVideoOutput) throws {
        self.device = device
        self.videoOutput = videoOutput

        var cacheOutput: CVMetalTextureCache?
        let code = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &cacheOutput)

        guard let cache = cacheOutput else {
            throw CVError(code: code)
        }

        textureCache = cache
    }

    public convenience init(device: MTLDevice) {
        do {
            try self.init(device: device, outputSettings: [:])
        } catch {
            fatalError("Failed to initialize PlayerItemRenderer with default settings")
        }
    }

    public convenience init(device: MTLDevice, outputSettings: [String: Any]) throws {
        var settings: [String: Any] = [
            (kCVPixelBufferMetalCompatibilityKey as String): true,
            (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
        ]

        for (key, value) in outputSettings {
            settings[key] = value
        }

        let videoOutput: AVPlayerItemVideoOutput
        if #available(iOS 10.0, *) {
            videoOutput = AVPlayerItemVideoOutput(outputSettings: settings)
        } else {
            videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: settings)
        }

        try self.init(device: device, videoOutput: videoOutput)
    }

    deinit {
        if let item = playerItem {
            unbind(item)
        }
    }

    private func bind(_ playerItem: AVPlayerItem) {
        guard !playerItem.outputs.contains(videoOutput) else {
            return
        }
        playerItem.add(videoOutput)
    }

    private func unbind(_ playerItem: AVPlayerItem) {
        guard playerItem.outputs.contains(videoOutput) else {
            return
        }
        playerItem.remove(videoOutput)
    }

    public func hasNewPixelBuffer(atItemTime time: CMTime) -> Bool {
        return videoOutput.hasNewPixelBuffer(forItemTime: time)
    }

    public func render(atItemTime time: CMTime, to texture: MTLTexture, commandBuffer: MTLCommandBuffer) throws {
        guard let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else {
            return
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        var cacheOutput: CVMetalTexture?
        let code = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, texture.pixelFormat, texture.width, texture.height, 0, &cacheOutput)

        guard let cvMetalTexture = cacheOutput else {
            throw CVError(code: code)
        }

        guard let sourceTexture = CVMetalTextureGetTexture(cvMetalTexture) else {
            fatalError("Failed to get MTLTexture from CVMetalTexture")
        }

        let sourceOrigin = MTLOriginMake(0, 0, 0)
        let sourceSize = MTLSizeMake(sourceTexture.width, sourceTexture.height, sourceTexture.depth)
        let destinationOrigin = MTLOriginMake(0, 0, 0)

        let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
        blitCommandEncoder?.copy(from: sourceTexture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: sourceOrigin, sourceSize: sourceSize, to: texture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: destinationOrigin)
        blitCommandEncoder?.endEncoding()
    }

    public func hasNewPixelBuffer(atHostTime time: TimeInterval) -> Bool {
        let itemTime = videoOutput.itemTime(forHostTime: time)
        return hasNewPixelBuffer(atItemTime: itemTime)
    }

    public func render(atHostTime time: TimeInterval, to texture: MTLTexture, commandBuffer: MTLCommandBuffer) throws {
        let itemTime = videoOutput.itemTime(forHostTime: time)
        try render(atItemTime: itemTime, to: texture, commandBuffer: commandBuffer)
    }
}

#endif
