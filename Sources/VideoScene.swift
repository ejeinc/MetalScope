//
//  VideoScene.swift
//  PanoramaView
//
//  Created by Jun Tanaka on 2017/01/19.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit
import AVFoundation

public protocol VideoSceneProtocol: class {
    var player: AVPlayer? { get set }

    func renderVideo(atTime time: TimeInterval, renderer: SCNSceneRenderer)
}

public final class MonoSphericalVideoScene: MonoSphericalMediaScene, VideoSceneProtocol {
    private let playerRenderer: PlayerRenderer

    private var playerTexture: MTLTexture? {
        didSet {
            mediaSphereNode.mediaContents = playerTexture
        }
    }

    public var player: AVPlayer? {
        get {
            return playerRenderer.player
        }
        set(value) {
            playerRenderer.player = value
        }
    }

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
