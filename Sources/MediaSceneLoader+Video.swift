//
//  MediaSceneLoader+Video.swift
//  PanoramaView
//
//  Created by Jun Tanaka on 2017/01/20.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit
import AVFoundation

extension MediaSceneLoader {
    public func loadVideo(player: AVPlayer, format: MediaFormat) throws {
        let scene: VideoSceneProtocol

        switch format {
        case .mono:
            scene = try MonoSphericalVideoScene(device: device)
        case .stereoOverUnder:
            scene = try StereoSphericalVideoScene(device: device)
        }

        scene.player = player

        self.scene = (scene as? SCNScene)
    }
}
