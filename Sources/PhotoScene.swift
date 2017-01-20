//
//  PhotoScene.swift
//  Axel
//
//  Created by Jun Tanaka on 2017/01/19.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit
import UIKit

public protocol PhotoSceneProtocol: class {
	var image: UIImage? { get set }
}

public final class MonoSphericalPhotoScene: MonoSphericalMediaScene, PhotoSceneProtocol {
	public var image: UIImage? {
		didSet {
			mediaSphereNode.mediaContents = image
		}
	}
}
