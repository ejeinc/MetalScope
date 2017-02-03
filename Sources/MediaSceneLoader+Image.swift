//
//  MediaSceneLoader+Image.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/20.
//  Copyright © 2017 eje Inc. All rights reserved.
//

#if (arch(i386) || arch(x86_64)) && os(iOS)
    // Not available on iOS Simulator
#else

import SceneKit

extension MediaSceneLoader {
    public func load(_ image: UIImage, format: MediaFormat) {
        let scene: ImageSceneProtocol

        switch format {
        case .mono:
            scene = MonoSphericalImageScene()
        case .stereoOverUnder:
            scene = StereoSphericalImageScene()
        }

        scene.image = image

        self.scene = (scene as? SCNScene)
    }
}

#endif
