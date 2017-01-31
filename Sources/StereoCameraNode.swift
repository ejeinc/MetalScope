//
//  StereoCameraNode.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/23.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit

public final class StereoCameraNode: SCNNode {
    public var stereoParameters: StereoParametersProtocol {
        didSet {
            updatePointOfViews()
        }
    }

    public var nearZ: Float = 0.1 {
        didSet {
            updatePointOfViews()
        }
    }

    public var farZ: Float = 1000 {
        didSet {
            updatePointOfViews()
        }
    }

    private let pointOfViews: [Eye: SCNNode] = [
        .left: SCNNode(),
        .right: SCNNode()
    ]

    public init(stereoParameters: StereoParametersProtocol) {
        self.stereoParameters = stereoParameters

        super.init()

        for (eye, node) in pointOfViews {
            let camera = SCNCamera()
            switch eye {
            case .left:
                camera.categoryBitMask = CategoryBitMask.all.subtracting(.rightEye).rawValue
            case .right:
                camera.categoryBitMask = CategoryBitMask.all.subtracting(.leftEye).rawValue
            }
            node.camera = camera
            self.addChildNode(node)
        }

        updatePointOfViews()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func pointOfView(for eye: Eye) -> SCNNode {
        return pointOfViews[eye]!
    }

    private func updatePointOfViews() {
        let separation = stereoParameters.viewer.lenses.separation

        for (eye, node) in pointOfViews {
            var position = SCNVector3Zero

            switch eye {
            case .left:
                position.x = separation / -2
            case .right:
                position.x = separation / 2
            }

            node.position = position
            node.camera?.projectionTransform = stereoParameters.cameraProjectionTransform(for: eye, nearZ: nearZ, farZ: farZ)
        }
    }
}
