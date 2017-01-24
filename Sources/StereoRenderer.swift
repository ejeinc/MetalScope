//
//  StereoRenderer.swift
//  Axel
//
//  Created by Jun Tanaka on 2017/01/23.
//  Copyright © 2017 eje Inc. All rights reserved.
//

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
    private let eyeTextures: [Eye: MTLTexture]
    private var pointOfViews: [Eye: SCNNode] = [:]

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

        eyeTextures = [
            .left: device.makeTexture(descriptor: eyeTextureDescriptor),
            .right: device.makeTexture(descriptor: eyeTextureDescriptor)
        ]
    }

    func pointOfView(for eye: Eye) -> SCNNode? {
        return pointOfViews[eye]
    }

    func setPointOfView(_ pointOfView: SCNNode?, for eye: Eye) {
        pointOfViews[eye] = pointOfView
    }

    func render(atTime time: TimeInterval) {
        let semaphore = renderSemaphore

        semaphore.wait()

        guard let commandQueue = scnRenderer.commandQueue else {
            fatalError("Invalid SCNRenderer context")
        }

        let commandBuffer = commandQueue.makeCommandBuffer()

        for (eye, eyeTexture) in eyeTextures {
            let viewport = CGRect(x: 0, y: 0, width: eyeTexture.width, height: eyeTexture.height)

            let passDescriptor = MTLRenderPassDescriptor()
            passDescriptor.colorAttachments[0].texture = eyeTexture
            passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
            passDescriptor.colorAttachments[0].storeAction = .store
            passDescriptor.colorAttachments[0].loadAction = .clear

            scnRenderer.pointOfView = pointOfView(for: eye)
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
                from: eyeTexture,
                sourceSlice: 0,
                sourceLevel: 0,
                sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                sourceSize: MTLSize(width: eyeTexture.width, height: eyeTexture.height, depth: eyeTexture.depth),
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
