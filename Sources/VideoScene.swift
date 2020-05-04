//
//  VideoScene.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/19.
//  Copyright © 2017 eje Inc. All rights reserved.
//

#if (arch(arm) || arch(arm64)) && os(iOS)

import SceneKit
import AVFoundation

public protocol VideoScene: class {
    var renderer: PlayerRenderer { get }

    init(renderer: PlayerRenderer)
}

extension VideoScene {
    public var player: AVPlayer? {
        get {
            return renderer.player
        }
        set(value) {
            renderer.player = value
        }
    }

    public init(device: MTLDevice) {
        let renderer = PlayerRenderer(device: device)
        self.init(renderer: renderer)
    }

    public init(device: MTLDevice, outputSettings: [String: Any]) throws {
        let renderer = try PlayerRenderer(device: device, outputSettings: outputSettings)
        self.init(renderer: renderer)
    }

    fileprivate var preferredPixelFormat: MTLPixelFormat {
        if #available(iOS 10, *) {
            return .bgra8Unorm_srgb
        } else {
            return .bgra8Unorm
        }
    }
}

public final class MonoSphericalVideoScene: MonoSphericalMediaScene, VideoScene {
    private var playerTexture: MTLTexture? {
        didSet {
            mediaSphereNode.mediaContents = playerTexture
        }
    }

    private lazy var renderLoop: RenderLoop = {
        return RenderLoop { [weak self] time in
            self?.renderVideo(atTime: time)
        }
    }()

    private let commandQueue: MTLCommandQueue

    public let renderer: PlayerRenderer

    public override var isPaused: Bool {
        didSet {
            if isPaused {
                renderLoop.pause()
            } else {
                renderLoop.resume()
            }
        }
    }

    public init(renderer: PlayerRenderer) {
        self.renderer = renderer
        commandQueue = renderer.device.makeCommandQueue() as! MTLCommandQueue
        super.init()
        renderLoop.resume()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateTextureIfNeeded() {
        guard let videoSize = renderer.itemRenderer.playerItem?.presentationSize, videoSize != .zero else {
            return
        }

        let width = Int(videoSize.width)
        let height = Int(videoSize.height)

        if let texture = playerTexture, texture.width == width, texture.height == height {
            return
        }

        let device = renderer.device
        let pixelFormat = preferredPixelFormat

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: true)
        playerTexture = device.makeTexture(descriptor: descriptor)
    }

    public func renderVideo(atTime time: TimeInterval, commandQueue: MTLCommandQueue? = nil) {
        guard renderer.hasNewPixelBuffer(atHostTime: time) else {
            return
        }

        updateTextureIfNeeded()

        guard let texture = playerTexture else {
            return
        }

        do {
            let commandBuffer = (commandQueue ?? self.commandQueue).makeCommandBuffer()
            try renderer.render(atHostTime: time, to: texture, commandBuffer: commandBuffer as! MTLCommandBuffer)
            commandBuffer?.commit()
        } catch let error as CVError {
            debugPrint("[MonoSphericalVideoScene] failed to render video with error: \(error)")
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

public final class StereoSphericalVideoScene: StereoSphericalMediaScene, VideoScene {
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

    private lazy var renderLoop: RenderLoop = {
        return RenderLoop { [weak self] time in
            self?.renderVideo(atTime: time)
        }
    }()

    private let commandQueue: MTLCommandQueue

    public let renderer: PlayerRenderer

    public override var isPaused: Bool {
        didSet {
            if isPaused {
                renderLoop.pause()
            } else {
                renderLoop.resume()
            }
        }
    }

    public init(renderer: PlayerRenderer) {
        self.renderer = renderer
        commandQueue = renderer.device.makeCommandQueue() as! MTLCommandQueue
        super.init()
        renderLoop.resume()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateTexturesIfNeeded() {
        guard let videoSize = renderer.itemRenderer.playerItem?.presentationSize, videoSize != .zero else {
            return
        }

        let width = Int(videoSize.width)
        let height = Int(videoSize.height)

        if let texture = playerTexture, texture.width == width, texture.height == height {
            return
        }

        let device = renderer.device
        let pixelFormat = preferredPixelFormat

        let playerTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: true)
        playerTexture = device.makeTexture(descriptor: playerTextureDescriptor)

        let sphereTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height / 2, mipmapped: true)
        leftSphereTexture = device.makeTexture(descriptor: sphereTextureDescriptor)
        rightSphereTexture = device.makeTexture(descriptor: sphereTextureDescriptor)
    }

    public func renderVideo(atTime time: TimeInterval, commandQueue: MTLCommandQueue? = nil) {
        guard renderer.hasNewPixelBuffer(atHostTime: time) else {
            return
        }

        updateTexturesIfNeeded()

        guard let playerTexture = playerTexture else {
            return
        }

        let commandBuffer = (commandQueue ?? self.commandQueue).makeCommandBuffer()

        do {
            try renderer.render(atHostTime: time, to: playerTexture, commandBuffer: commandBuffer!)

            func copyPlayerTexture(region: MTLRegion, to sphereTexture: MTLTexture) {
                let blitCommandEncoder = commandBuffer?.makeBlitCommandEncoder()
                blitCommandEncoder?.copy(
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
                blitCommandEncoder?.endEncoding()
            }

            let halfHeight = playerTexture.height / 2

            if let leftTexture = leftSphereTexture {
                let leftSphereRegion = MTLRegionMake2D(0, 0, playerTexture.width, halfHeight)
                copyPlayerTexture(region: leftSphereRegion, to: leftTexture)
            }

            if let rightTexture = rightSphereTexture {
                let rightSphereRegion = MTLRegionMake2D(0, halfHeight, playerTexture.width, halfHeight)
                copyPlayerTexture(region: rightSphereRegion, to: rightTexture)
            }

            commandBuffer?.commit()
        } catch let error as CVError {
            debugPrint("[StereoSphericalVideoScene] failed to render video with error: \(error)")
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

#endif
