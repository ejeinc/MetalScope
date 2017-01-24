//
//  MediaSceneLoader+Photo.swift
//  Axel
//
//  Created by Jun Tanaka on 2017/01/20.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit

extension MediaSceneLoader {
    public func loadPhoto(image: UIImage, format: SphericalMediaFormat = .mono) {
        let scene: PhotoSceneProtocol

        switch format {
        case .mono:
            scene = MonoSphericalPhotoScene()
        default:
            scene = StereoSphericalPhotoScene()
        }

        scene.image = image
        
        self.scene = (scene as? SCNScene)
    }
}
