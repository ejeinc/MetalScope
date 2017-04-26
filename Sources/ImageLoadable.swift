//
//  ImageLoadable.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/04/24.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit
import UIKit

public protocol ImageLoadable {
    func load(_ image: UIImage, format: MediaFormat)
}

extension ImageLoadable where Self: SceneLoadable {
    public func load(_ image: UIImage, format: MediaFormat) {
        ImageSceneLoader(target: self).load(image, format: format)
    }
}

public struct ImageSceneLoader<Target: SceneLoadable>: ImageLoadable {
    public let target: Target

    public init(target: Target) {
        self.target = target
    }

    public func load(_ image: UIImage, format: MediaFormat) {
        let scene: ImageScene

        switch format {
        case .mono:
            scene = MonoSphericalImageScene()
        case .stereoOverUnder:
            scene = StereoSphericalImageScene()
        }

        scene.image = image

        target.scene = (scene as? SCNScene)
    }
}
