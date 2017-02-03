//
//  MediaSceneLoader.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/20.
//  Copyright © 2017 eje Inc. All rights reserved.
//

#if (arch(i386) || arch(x86_64)) && os(iOS)
    // Not available on iOS Simulator
#else

import SceneKit

public protocol MediaSceneLoader: class {
    var device: MTLDevice { get }
    var scene: SCNScene? { get set }
}

#endif
