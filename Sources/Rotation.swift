//
//  Rotation.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/17.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import GLKit

public struct Rotation {
    public var matrix: GLKMatrix3

    public init(matrix: GLKMatrix3 = GLKMatrix3Identity) {
        self.matrix = matrix
    }
}

extension Rotation {
    public static let identity = Rotation()
}

extension Rotation {
    public init(_ glkMatrix3: GLKMatrix3) {
        self.init(matrix: glkMatrix3)
    }

    public var glkMatrix3: GLKMatrix3 {
        get {
            return matrix
        }
        set(value) {
            matrix = value
        }
    }
}

extension Rotation {
    public init(_ glkQuaternion: GLKQuaternion) {
        self.init(GLKMatrix3MakeWithQuaternion(glkQuaternion))
    }

    public var glkQuartenion: GLKQuaternion {
        get {
            return GLKQuaternionMakeWithMatrix3(glkMatrix3)
        }
        set(value) {
            glkMatrix3 = GLKMatrix3MakeWithQuaternion(value)
        }
    }
}

extension Rotation {
    public init(radians: Float, aroundVector vector: GLKVector3) {
        self.init(GLKMatrix3MakeRotation(radians, vector.x, vector.y, vector.z))
    }

    public init(x: Float) {
        self.init(GLKMatrix3MakeXRotation(x))
    }

    public init(y: Float) {
        self.init(GLKMatrix3MakeYRotation(y))
    }

    public init(z: Float) {
        self.init(GLKMatrix3MakeZRotation(z))
    }
}

extension Rotation {
    public mutating func rotate(byRadians radians: Float, aroundAxis axis: GLKVector3) {
        glkMatrix3 = GLKMatrix3RotateWithVector3(glkMatrix3, radians, axis)
    }

    public mutating func rotate(byX radians: Float) {
        glkMatrix3 = GLKMatrix3RotateX(glkMatrix3, radians)
    }

    public mutating func rotate(byY radians: Float) {
        glkMatrix3 = GLKMatrix3RotateY(glkMatrix3, radians)
    }

    public mutating func rotate(byZ radians: Float) {
        glkMatrix3 = GLKMatrix3RotateZ(glkMatrix3, radians)
    }

    public mutating func invert() {
        glkQuartenion = GLKQuaternionInvert(glkQuartenion)
    }

    public mutating func normalize() {
        glkQuartenion = GLKQuaternionNormalize(glkQuartenion)
    }
}

extension Rotation {
    public func rotated(byRadians radians: Float, aroundAxis axis: GLKVector3) -> Rotation {
        var r = self
        r.rotate(byRadians: radians, aroundAxis: axis)
        return r
    }

    public func rotated(byX x: Float) -> Rotation {
        var r = self
        r.rotate(byX: x)
        return r
    }

    public func rotated(byY y: Float) -> Rotation {
        var r = self
        r.rotate(byY: y)
        return r
    }

    public func rotated(byZ z: Float) -> Rotation {
        var r = self
        r.rotate(byZ: z)
        return r
    }

    public func inverted() -> Rotation {
        var r = self
        r.invert()
        return r
    }

    public func normalized() -> Rotation {
        var r = self
        r.normalize()
        return r
    }
}

public func * (lhs: Rotation, rhs: Rotation) -> Rotation {
    return Rotation(GLKMatrix3Multiply(lhs.glkMatrix3, rhs.glkMatrix3))
}

public func * (lhs: Rotation, rhs: GLKVector3) -> GLKVector3 {
    return GLKMatrix3MultiplyVector3(lhs.glkMatrix3, rhs)
}
