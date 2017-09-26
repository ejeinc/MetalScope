//
//  StereoRenderer.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/23.
//  Copyright © 2017 eje Inc. All rights reserved.
//

#if (arch(arm) || arch(arm64)) && os(iOS)

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

    weak var sceneRendererDelegate: SCNSceneRendererDelegate? {
        didSet {
            rendererDelegateProxy.forwardingTarget = sceneRendererDelegate
        }
    }

    private let renderSemaphore = DispatchSemaphore(value: 6)
    private let eyeRenderingConfigurations: [Eye: EyeRenderingConfiguration]
    private let rendererDelegateProxy = RendererDelegateProxy()

    init(outputTexture: MTLTexture) {
        self.outputTexture = outputTexture

        let device = outputTexture.device

        scnRenderer = SCNRenderer(device: device, options: nil)
        scnRenderer.delegate = rendererDelegateProxy

        let eyeTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: outputTexture.pixelFormat,
            width: outputTexture.width / 2,
            height: outputTexture.height,
            mipmapped: true
        )
        eyeTextureDescriptor.usage = .renderTarget

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

    func render(atTime time: TimeInterval) {
        render(atTime: time, commandQueue: scnRenderer.commandQueue!)
    }

    func render(atTime time: TimeInterval, commandQueue: MTLCommandQueue) {
        let semaphore = renderSemaphore

        for (eye, configuration) in eyeRenderingConfigurations {
            semaphore.wait()

            let commandBuffer = commandQueue.makeCommandBuffer()

            rendererDelegateProxy.currentRenderingEye = eye

            let texture = configuration.texture
            let viewport = CGRect(x: 0, y: 0, width: texture.width, height: texture.height)

            let passDescriptor = MTLRenderPassDescriptor()
            passDescriptor.colorAttachments[0].texture = texture
            passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
            passDescriptor.colorAttachments[0].storeAction = .store
            passDescriptor.colorAttachments[0].loadAction = .clear

            scnRenderer.pointOfView = configuration.pointOfView
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

            commandBuffer.addCompletedHandler { _ in
                semaphore.signal()
            }

            commandBuffer.commit()
        }
    }
}

extension MTLCommandBufferStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .committed:
            return "committed"
        case .completed:
            return "completed"
        case .enqueued:
            return "enqueued"
        case .error:
            return "error"
        case .notEnqueued:
            return "notEnqueued"
        case .scheduled:
            return "scheduled"
        }
    }
}

private extension StereoRenderer {
    final class EyeRenderingConfiguration {
        let texture: MTLTexture
        var pointOfView: SCNNode?

        init(texture: MTLTexture) {
            self.texture = texture
        }
    }
}

private extension StereoRenderer {
    final class RendererDelegateProxy: NSObject, SCNSceneRendererDelegate {
        var currentRenderingEye: Eye?

        weak var forwardingTarget: SCNSceneRendererDelegate?

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            guard currentRenderingEye == .left else {
                return
            }
            forwardingTarget?.renderer?(renderer, updateAtTime: time)
        }

        func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
            guard currentRenderingEye == .left else {
                return
            }
            forwardingTarget?.renderer?(renderer, didApplyAnimationsAtTime: time)
        }

        func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
            guard currentRenderingEye == .left else {
                return
            }
            forwardingTarget?.renderer?(renderer, didSimulatePhysicsAtTime: time)
        }

        func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
            guard currentRenderingEye == .left else {
                return
            }
            forwardingTarget?.renderer?(renderer, willRenderScene: scene, atTime: time)
        }

        func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
            guard currentRenderingEye == .right else {
                return
            }
            forwardingTarget?.renderer?(renderer, didRenderScene: scene, atTime: time)
        }
    }
}

#endif
