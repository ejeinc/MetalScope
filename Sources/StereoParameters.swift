//
//  StereoParameters.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/23.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit

public protocol StereoParametersProtocol {
    var screen: ScreenParametersProtocol { get }
    var viewer: ViewerParametersProtocol { get }
}

public struct StereoParameters: StereoParametersProtocol {
    public var screen: ScreenParametersProtocol
    public var viewer: ViewerParametersProtocol
}

extension StereoParameters {
    public init(screenModel: ScreenModel = .default, viewerModel: ViewerModel = .default) {
        screen = screenModel
        viewer = viewerModel
    }
}

extension StereoParametersProtocol {
    func cameraProjectionTransform(for eye: Eye, nearZ: Float, farZ: Float, aspectRatio: Float = 1) -> SCNMatrix4 {
        var projection = distortedProjection(for: eye)
        projection.m11 /= aspectRatio
        projection.m33 = (nearZ + farZ) / (nearZ - farZ)
        projection.m43 = 2 * nearZ * farZ / (nearZ - farZ)
        return projection
    }

    func distortedProjection(for eye: Eye) -> SCNMatrix4 {
        let baseProjection = projectionFromFrustum(leftEyeVisibleTanAngles)
        let convertedProjection = convertLeftEyeProjection(baseProjection, for: eye)
        return convertedProjection
    }

    func undistortedProjection(for eye: Eye) -> SCNMatrix4 {
        let baseProjection = projectionFromFrustum(leftEyeNoLensVisibleTanAngles)
        let convertedProjection = convertLeftEyeProjection(baseProjection, for: eye)
        return convertedProjection
    }

    func convertLeftEyeProjection(_ leftEyeProjection: SCNMatrix4, for eye: Eye) -> SCNMatrix4 {
        var projection = leftEyeProjection

        switch eye {
        case .right:
            projection.m31 *= -1
        default:
            break
        }

        return projection
    }

    func projectionFromFrustum(_ frustum: float4) -> SCNMatrix4 {
        return projectionFromFrustum(frustum[0], frustum[1], frustum[2], frustum[3])
    }

    func projectionFromFrustum(_ left: Float, _ top: Float, _ right: Float, _ bottom: Float) -> SCNMatrix4 {
        return SCNMatrix4FromGLKMatrix4(GLKMatrix4MakeFrustum(left, right, bottom, top, 1, 1000))
    }

    func viewport(for eye: Eye, inBounds bounds: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)) -> CGRect {
        let rect = leftEyeVisibleScreenRect

        var viewport = bounds
        viewport.size.width *= rect.size.width
        viewport.origin.x = rect.origin.x + viewport.origin.x * rect.size.width
        viewport.size.height *= rect.size.height
        viewport.origin.y = rect.origin.y + viewport.origin.y * rect.size.height

        switch eye {
        case .right:
            viewport.origin.x = bounds.maxX - viewport.maxX
        default:
            break
        }

        return viewport
    }

    func recommendedStereoTextureSize(forScreenSize screenSize: CGSize) -> CGSize {
        let screenBounds = CGRect(origin: .zero, size: screenSize)
        let leftEyeViewport = viewport(for: .left, inBounds: screenBounds)
        let rightEyeViewport = viewport(for: .right, inBounds: screenBounds)

        return CGSize(
            width: leftEyeViewport.width + rightEyeViewport.width,
            height: max(leftEyeViewport.height, rightEyeViewport.height)
        )
    }

    var verticalLensOffsetFromScreenCenter: Float {
        return (viewer.lenses.offset - screen.border - screen.height / 2) * Float(viewer.lenses.alignment.rawValue)
    }
}

extension StereoParametersProtocol {
    /// Most of the code in this section was originally ported from Google's Cardboard SDK for Unity
    /// https://github.com/googlevr/gvr-unity-sdk/blob/v0.6/Cardboard/Scripts/CardboardProfile.cs

    var leftEyeVisibleTanAngles: float4 {
        let fov = viewer.maximumFieldOfView

        let fovOuter = fov.outer * .pi / 180
        let fovUpper = fov.upper * .pi / 180
        let fovInner = fov.inner * .pi / 180
        let fovLower = fov.lower * .pi / 180

        let fovLeft = tan(-fovOuter)
        let fovTop = tan(fovUpper)
        let fovRight = tan(fovInner)
        let fovBottom = tan(-fovLower)

        let halfWidth = screen.width / 4
        let halfHeight = screen.height / 2

        let centerX = viewer.lenses.separation / 2 - halfWidth
        let centerY = verticalLensOffsetFromScreenCenter * -1
        let centerZ = viewer.lenses.screenDistance

        let screenLeft = viewer.distortion.distort((centerX - halfWidth) / centerZ)
        let screenTop = viewer.distortion.distort((centerY + halfHeight) / centerZ)
        let screenRight = viewer.distortion.distort((centerX + halfWidth) / centerZ)
        let screenBottom = viewer.distortion.distort((centerY - halfHeight) / centerZ)

        let result = float4(
            max(fovLeft, screenLeft),
            min(fovTop, screenTop),
            min(fovRight, screenRight),
            max(fovBottom, screenBottom)
        )

        return result
    }

    var leftEyeNoLensVisibleTanAngles: float4 {
        let fov = viewer.maximumFieldOfView

        let fovOuter = fov.outer * .pi / 180
        let fovUpper = fov.upper * .pi / 180
        let fovInner = fov.inner * .pi / 180
        let fovLower = fov.lower * .pi / 180

        let fovLeft = viewer.distortion.distortInv(tan(-fovOuter))
        let fovTop = viewer.distortion.distortInv(tan(fovUpper))
        let fovRight = viewer.distortion.distortInv(tan(fovInner))
        let fovBottom = viewer.distortion.distortInv(tan(-fovLower))

        let halfWidth = screen.width / 4
        let halfHeight = screen.height / 2

        let centerX = viewer.lenses.separation / 2 - halfWidth
        let centerY = verticalLensOffsetFromScreenCenter * -1
        let centerZ = viewer.lenses.screenDistance

        let screenLeft = (centerX - halfWidth) / centerZ
        let screenTop = (centerY + halfHeight) / centerZ
        let screenRight = (centerX + halfWidth) / centerZ
        let screenBottom = (centerY - halfHeight) / centerZ

        let result = float4(
            max(fovLeft, screenLeft),
            min(fovTop, screenTop),
            min(fovRight, screenRight),
            max(fovBottom, screenBottom)
        )

        return result
    }

    var leftEyeVisibleScreenRect: CGRect {
        let undistortedFrustum = leftEyeNoLensVisibleTanAngles
        let dist = viewer.lenses.screenDistance

        let eyeX = (screen.width - viewer.lenses.separation) / 2
        let eyeY = verticalLensOffsetFromScreenCenter + screen.height / 2

        let left = (undistortedFrustum[0] * dist + eyeX) / screen.width
        let top = (undistortedFrustum[1] * dist + eyeY) / screen.height
        let right = (undistortedFrustum[2] * dist + eyeX) / screen.width
        let bottom = (undistortedFrustum[3] * dist + eyeY) / screen.height

        let result = CGRect(
            x: CGFloat(left),
            y: CGFloat(bottom),
            width: CGFloat(right - left),
            height: CGFloat(top - bottom)
        )

        return result
    }
}
