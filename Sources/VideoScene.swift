//
//  VideoScene.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/19.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit
import AVFoundation

public protocol VideoSceneProtocol: class {
    var playerRenderer: PlayerRenderer { get }

    func renderVideo(atTime time: TimeInterval, renderer: SCNSceneRenderer)
}

extension VideoSceneProtocol {
    public var player: AVPlayer? {
        get {
            return playerRenderer.player
        }
        set(value) {
            playerRenderer.player = value
        }
    }
}

public final class MonoSphericalVideoScene: MonoSphericalMediaScene, VideoSceneProtocol {
    private var playerTexture: MTLTexture? {
        didSet {
            mediaSphereNode.mediaContents = playerTexture
        }
    }

    public let playerRenderer: PlayerRenderer

    public init(playerRenderer: PlayerRenderer) {
        self.playerRenderer = playerRenderer
        super.init()
    }

    public convenience init(device: MTLDevice, outputSettings: [String: Any]? = nil) throws {
        let renderer = try PlayerRenderer(device: device, outputSettings: outputSettings)
        self.init(playerRenderer: renderer)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateTextureIfNeeded() {
        guard let videoSize = playerRenderer.itemRenderer.playerItem?.presentationSize, videoSize != .zero else {
            return
        }

        let width = Int(videoSize.width)
        let height = Int(videoSize.height)

        if let texture = playerTexture, texture.width == width, texture.height == height {
            return
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: width, height: height, mipmapped: true)
        playerTexture = playerRenderer.itemRenderer.device.makeTexture(descriptor: descriptor)
    }

    public func renderVideo(atTime time: TimeInterval, renderer: SCNSceneRenderer) {
        guard playerRenderer.hasNewPixelBuffer(atHostTime: time) else {
            return
        }

        updateTextureIfNeeded()

        guard let texture = playerTexture, let commandQueue = renderer.commandQueue else {
            return
        }

        do {
            let commandBuffer = commandQueue.makeCommandBuffer()
            try playerRenderer.render(atHostTime: time, to: texture, commandBuffer: commandBuffer)
            commandBuffer.commit()
        } catch let error as CVError {
            debugPrint("[MonoSphericalVideoScene] failed to render video with error: \(error)")
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

public final class StereoSphericalVideoScene: StereoSphericalMediaScene, VideoSceneProtocol {
    private var playerTexture: MTLTexture?

    private var leftSphereTexture: MTLTexture? {
        didSet {
            leftMediaSphereNode.mediaContents = leftSphereTexture
        }
    }

    private var rightSphereTexture: MTLTexture? {
        didSet {
            rightMediaSphereNode.mediaContents = rightSphereTexture
        }
    }

    public let playerRenderer: PlayerRenderer

    public init(playerRenderer: PlayerRenderer) {
        self.playerRenderer = playerRenderer
        super.init()
    }

    public convenience init(device: MTLDevice, outputSettings: [String: Any]? = nil) throws {
        let renderer = try PlayerRenderer(device: device, outputSettings: outputSettings)
        self.init(playerRenderer: renderer)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateTexturesIfNeeded() {
        guard let videoSize = playerRenderer.itemRenderer.playerItem?.presentationSize, videoSize != .zero else {
            return
        }

        let width = Int(videoSize.width)
        let height = Int(videoSize.height)

        if let texture = playerTexture, texture.width == width, texture.height == height {
            return
        }

        let device = playerRenderer.device

        let playerTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: width, height: height, mipmapped: true)
        playerTexture = device.makeTexture(descriptor: playerTextureDescriptor)

        let sphereTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: width, height: height / 2, mipmapped: true)
        leftSphereTexture = device.makeTexture(descriptor: sphereTextureDescriptor)
        rightSphereTexture = device.makeTexture(descriptor: sphereTextureDescriptor)
    }

    public func renderVideo(atTime time: TimeInterval, renderer: SCNSceneRenderer) {
        guard playerRenderer.hasNewPixelBuffer(atHostTime: time) else {
            return
        }

        updateTexturesIfNeeded()

        guard
            let playerTexture = playerTexture,
            let leftSphereTexture = leftSphereTexture,
            let rightSphereTexture = rightSphereTexture,
            let commandQueue = renderer.commandQueue else {
            return
        }

        do {
            let commandBuffer = commandQueue.makeCommandBuffer()

            try playerRenderer.render(atHostTime: time, to: playerTexture, commandBuffer: commandBuffer)

            func copyPlayerTexture(region: MTLRegion, to sphereTexture: MTLTexture) {
                let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
                blitCommandEncoder.copy(
                    from: playerTexture,
                    sourceSlice: 0,
                    sourceLevel: 0,
                    sourceOrigin: region.origin,
                    sourceSize: region.size,
                    to: sphereTexture,
                    destinationSlice: 0,
                    destinationLevel: 0,
                    destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
                )
                blitCommandEncoder.endEncoding()
            }

            let halfHeight = playerTexture.height / 2

            let leftSphereRegion = MTLRegionMake2D(0, 0, playerTexture.width, halfHeight)
            copyPlayerTexture(region: leftSphereRegion, to: leftSphereTexture)

            let rightSphereRegion = MTLRegionMake2D(0, halfHeight, playerTexture.width, halfHeight)
            copyPlayerTexture(region: rightSphereRegion, to: rightSphereTexture)

            commandBuffer.commit()
        } catch let error as CVError {
            debugPrint("[StereoSphericalVideoScene] failed to render video with error: \(error)")
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
