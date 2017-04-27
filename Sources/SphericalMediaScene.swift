//
//  MonoSphericalMediaScene.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/18.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit

public final class MediaSphereNode: SCNNode {
    public var mediaContents: Any? {
        get {
            return geometry?.firstMaterial?.diffuse.contents
        }
        set(value) {
            geometry?.firstMaterial?.diffuse.contents = value
        }
    }

    public init(radius: CGFloat = 10, segmentCount: Int = 96) {
        super.init()

        let sphere = SCNSphere(radius: radius)
        sphere.segmentCount = segmentCount
        sphere.firstMaterial?.isDoubleSided = true
        geometry = sphere

        scale = SCNVector3(x: 1, y: 1, z: -1)
        renderingOrder = .max
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class MonoSphericalMediaScene: SCNScene {
    public lazy var mediaSphereNode: MediaSphereNode = {
        let node = MediaSphereNode()
        self.rootNode.addChildNode(node)
        return node
    }()
}

public class StereoSphericalMediaScene: SCNScene {
    public lazy var leftMediaSphereNode: MediaSphereNode = {
        let node = MediaSphereNode()
        node.categoryBitMask = CategoryBitMask.leftEye.rawValue
        self.rootNode.addChildNode(node)
        return node
    }()

    public lazy var rightMediaSphereNode: MediaSphereNode = {
        let node = MediaSphereNode()
        node.categoryBitMask = CategoryBitMask.rightEye.rawValue
        self.rootNode.addChildNode(node)
        return node
    }()
}
