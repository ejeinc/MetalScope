//
//  Rotation+CoreMotion.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/17.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import GLKit
import CoreMotion

extension Rotation {
    public init(_ cmQuaternion: CMQuaternion) {
        self.init(GLKQuaternionMake(
            Float(cmQuaternion.x),
            Float(cmQuaternion.y),
            Float(cmQuaternion.z),
            Float(cmQuaternion.w)
        ))
    }

    public init(_ cmAttitude: CMAttitude) {
        self.init(cmAttitude.quaternion)
    }

    public init(_ cmDeviceMotion: CMDeviceMotion) {
        self.init(cmDeviceMotion.attitude)
    }
}
