//
//  Rotation+SceneKit.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/17.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit

extension Rotation {
    public init(_ scnQuaternion: SCNQuaternion) {
        let q = scnQuaternion
        self.init(GLKQuaternionMake(q.x, q.y, q.z, q.w))
    }

    public var scnQuaternion: SCNQuaternion {
        let q = glkQuartenion
        return SCNQuaternion(x: q.x, y: q.y, z: q.z, w: q.w)
    }
}

extension Rotation {
    public init(_ scnMatrix4: SCNMatrix4) {
        let glkMatrix4 = SCNMatrix4ToGLKMatrix4(scnMatrix4)
        let glkMatrix3 = GLKMatrix4GetMatrix3(glkMatrix4)
        self.init(glkMatrix3)
    }

    public var scnMatrix4: SCNMatrix4 {
        let glkMatrix4 = GLKMatrix4MakeWithQuaternion(glkQuartenion)
        let scnMatrix4 = SCNMatrix4FromGLKMatrix4(glkMatrix4)
        return scnMatrix4
    }
}
