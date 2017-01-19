//
//  MonoSphericalMediaScene.swift
//  Panoramic
//
//  Created by Jun Tanaka on 2017/01/18.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit

public enum SphericalMediaFormat {
	case mono
	case stereoOverUnder
}

public class MonoSphericalMediaScene: SCNScene {
	public lazy var mediaSphereNode: SCNNode = {
		let node = self.makeSphereNode()
		self.rootNode.addChildNode(node)
		return node
	}()

	public func makeSphereNode() -> SCNNode {
		let sphere = SCNSphere(radius: 10)
		sphere.segmentCount = 96
		sphere.firstMaterial?.isDoubleSided = true

		let node = SCNNode(geometry: sphere)
		node.scale = SCNVector3(x: 1, y: 1, z: -1)
		return node
	}
}
