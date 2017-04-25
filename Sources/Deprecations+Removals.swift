//
//  Deprecations+Removals.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/04/24.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit

extension PanoramaView {
    @available(*, deprecated, message: "Use `setNeedsResetRotation` instead")
    public func resetCenter() {
        setNeedsResetRotation(animated: true)
    }
}

extension StereoView {
    @available(*, deprecated, message: "Use `setNeedsResetRotation` instead")
    public func resetCenter() {
        setNeedsResetRotation()
    }

    @available(*, unavailable, message: "Use `sceneRendererDelegate` instead")
    public func sceneRendererDelegate(for eye: Eye) -> SCNSceneRendererDelegate? {
        fatalError("Use sceneRendererDelegate property instead")
    }

    @available(*, unavailable, message: "Use `sceneRendererDelegate` instead")
    public func setSceneRendererDelegate(_ delegate: SCNSceneRendererDelegate, for eye: Eye) {
        fatalError("Use sceneRendererDelegate property instead")
    }
}

extension OrientationNode {
    @available(*, renamed: "OrientationNode.resetRotation")
    public func resetCenter() {
        resetRotation()
    }

    @available(*, renamed: "OrientationNode.resetRotation")
    public func resetCenter(animated: Bool, completionHanlder: (() -> Void)? = nil) {
        resetRotation(animated: animated, completionHanlder: completionHanlder)
    }
}

@available(*, unavailable, message: "This protocol has been removed. Use `SceneLoadable`, `ImageLoadable` and `VideoLoadable` instead")
public protocol MediaSceneLoader: class {}
