//
//  StereoRenderer.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/23.
//  Copyright © 2017 eje Inc. All rights reserved.
//

#if (arch(i386) || arch(x86_64)) && os(iOS)
    // Not available on iOS Simulator
#else

import SceneKit
import Metal

internal final class StereoRenderer {
    let outputTexture: MTLTexture

    var scene: SCNScene? {
        get {
            return scnRenderer.scene
        }
        set(value) {
            scnRenderer.scene = value
        }
    }

    let scnRenderer: SCNRenderer

    private let renderSemaphore = DispatchSemaphore(value: 3)
    private let eyeRenderingConfigurations: [Eye: EyeRenderingConfiguration]

    init(outputTexture: MTLTexture) {
        self.outputTexture = outputTexture

        let device = outputTexture.device

        scnRenderer = SCNRenderer(device: device, options: nil)

        let eyeTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: outputTexture.pixelFormat,
            width: outputTexture.width / 2,
            height: outputTexture.height,
            mipmapped: false
        )

        eyeRenderingConfigurations = [
            .left: EyeRenderingConfiguration(texture: device.makeTexture(descriptor: eyeTextureDescriptor)),
            .right: EyeRenderingConfiguration(texture: device.makeTexture(descriptor: eyeTextureDescriptor))
        ]
    }

    func pointOfView(for eye: Eye) -> SCNNode? {
        return eyeRenderingConfigurations[eye]?.pointOfView
    }

    func setPointOfView(_ pointOfView: SCNNode?, for eye: Eye) {
        eyeRenderingConfigurations[eye]?.pointOfView = pointOfView
    }

    func sceneRendererDelegate(for eye: Eye) -> SCNSceneRendererDelegate? {
        return eyeRenderingConfigurations[eye]?.delegate
    }

    func setSceneRendererDelegate(_ delegate: SCNSceneRendererDelegate, for eye: Eye) {
        eyeRenderingConfigurations[eye]?.delegate = delegate
    }

    func render(atTime time: TimeInterval) {
        let semaphore = renderSemaphore

        semaphore.wait()

        guard let commandQueue = scnRenderer.commandQueue else {
            fatalError("Invalid SCNRenderer context")
        }

        let commandBuffer = commandQueue.makeCommandBuffer()

        for (eye, configuration) in eyeRenderingConfigurations {
            let texture = configuration.texture
            let viewport = CGRect(x: 0, y: 0, width: texture.width, height: texture.height)

            let passDescriptor = MTLRenderPassDescriptor()
            passDescriptor.colorAttachments[0].texture = texture
            passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
            passDescriptor.colorAttachments[0].storeAction = .store
            passDescriptor.colorAttachments[0].loadAction = .clear

            scnRenderer.pointOfView = configuration.pointOfView
            scnRenderer.delegate = configuration.delegate
            scnRenderer.render(atTime: time, viewport: viewport, commandBuffer: commandBuffer, passDescriptor: passDescriptor)

            let destinationOrigin: MTLOrigin
            switch eye {
            case .left:
                destinationOrigin = MTLOrigin(x: 0, y: 0, z: 0)
            case .right:
                destinationOrigin = MTLOrigin(x: outputTexture.width / 2, y: 0, z: 0)
            }

            let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
            blitCommandEncoder.copy(
                from: texture,
                sourceSlice: 0,
                sourceLevel: 0,
                sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                sourceSize: MTLSize(width: texture.width, height: texture.height, depth: texture.depth),
                to: outputTexture,
                destinationSlice: 0,
                destinationLevel: 0,
                destinationOrigin: destinationOrigin
            )
            blitCommandEncoder.endEncoding()
        }

        commandBuffer.addCompletedHandler { _ in
            semaphore.signal()
        }

        commandBuffer.commit()
    }
}

private extension StereoRenderer {
    final class EyeRenderingConfiguration {
        let texture: MTLTexture
        var pointOfView: SCNNode?
        weak var delegate: SCNSceneRendererDelegate?

        init(texture: MTLTexture) {
            self.texture = texture
        }
    }
}

#endif
