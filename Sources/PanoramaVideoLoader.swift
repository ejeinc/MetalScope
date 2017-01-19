//
//  PanoramaVideoLoader.swift
//  Panoramic
//
//  Created by Jun Tanaka on 2017/01/20.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit
import AVFoundation

public protocol PanoramaVideoLoader: PanoramaMediaLoader {
	var device: MTLDevice { get }
}

extension PanoramaVideoLoader {
	public func loadVideo(player: AVPlayer, format: SphericalMediaFormat = .mono) throws {
		let scene: VideoSceneProtocol

		switch format {
		case .mono:
			scene = try MonoSphericalVideoScene(device: device)
		default:
			fatalError("Unsupported format")
		}

		scene.player = player

		self.scene = (scene as? SCNScene)
	}
}
