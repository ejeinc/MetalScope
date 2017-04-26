//
//  VideoLoadable.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/04/24.
//  Copyright © 2017 eje Inc. All rights reserved.
//

#if (arch(arm) || arch(arm64)) && os(iOS)

import SceneKit
import AVFoundation

public protocol VideoLoadable {
    var device: MTLDevice { get }

    func load(_ player: AVPlayer, format: MediaFormat)
}

extension VideoLoadable where Self: SceneLoadable {
    public func load(_ player: AVPlayer, format: MediaFormat) {
        VideoSceneLoader(target: self).load(player, format: format)
    }
}

public struct VideoSceneLoader<Target: SceneLoadable>: VideoLoadable {
    public let target: Target
    public let device: MTLDevice

    public init(target: Target, device: MTLDevice) {
        self.target = target
        self.device = device
    }

    public func load(_ player: AVPlayer, format: MediaFormat) {
        let scene: VideoScene

        switch format {
        case .mono:
            scene = MonoSphericalVideoScene(device: device)
        case .stereoOverUnder:
            scene = StereoSphericalVideoScene(device: device)
        }

        scene.player = player

        target.scene = (scene as? SCNScene)
    }
}

extension VideoSceneLoader where Target: VideoLoadable {
    public init(target: Target) {
        self.init(target: target, device: target.device)
    }
}

#endif
