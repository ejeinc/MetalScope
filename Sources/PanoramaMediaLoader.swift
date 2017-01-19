//
//  PanoramaMediaLoader.swift
//  Panoramic
//
//  Created by Jun Tanaka on 2017/01/20.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit

public protocol PanoramaMediaLoader: class {
	var scene: SCNScene? { get set }
}

extension PanoramaMediaLoader {
	public func loadPhoto(image: UIImage, format: SphericalMediaFormat = .mono) {
		let scene: PhotoSceneProtocol

		switch format {
		case .mono:
			scene = MonoSphericalPhotoScene()
		default:
			fatalError("Unsupported format")
		}

		scene.image = image

		self.scene = (scene as? SCNScene)
	}
}
