//
//  OrientationIndicator.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/02/01.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit
import UIKit

public protocol OrientationIndicatorDataSource: class {
    var pointOfView: SCNNode? { get }
    var viewportSize: CGSize { get }
}

public protocol OrientationIndicator {
    weak var dataSource: OrientationIndicatorDataSource? { get set }

    func updateOrientation()
}

public final class OrientationIndicatorLayer: CALayer, OrientationIndicator {
    public var fov: Float = .pi / 3 {
        didSet {
            applyFov()
        }
    }

    public var rotation: Float = 0 {
        didSet {
            applyRotation()
        }
    }

    public var color: UIColor = .white {
        didSet {
            applyColor()
        }
    }

    public weak var dataSource: OrientationIndicatorDataSource?

    private let strokeLayer = CAShapeLayer()
    private let fovArcLayer = CAShapeLayer()
    private let deviceLayer = CAShapeLayer()
    private let rotationLayer = CALayer()

    private var strokeWidth: CGFloat = 3

    private var innerFovArcRadius: CGFloat {
        return CGFloat(ceil(fov * 3))
    }

    private var outerFovArcRadius: CGFloat {
        return bounds.height / 2 - strokeWidth / 2
    }

    private var fovArcWidth: CGFloat {
        return outerFovArcRadius - innerFovArcRadius
    }

    public override init() {
        super.init()

        addSublayer(strokeLayer)
        addSublayer(rotationLayer)

        rotationLayer.addSublayer(fovArcLayer)
        rotationLayer.addSublayer(deviceLayer)

        strokeLayer.fillColor = nil
        fovArcLayer.fillColor = nil
        deviceLayer.strokeColor = nil

        strokeLayer.lineWidth = 1

        applyFov()
        applyRotation()
        applyColor()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSublayers() {
        super.layoutSublayers()

        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let sublayers = [
            strokeLayer,
            fovArcLayer,
            deviceLayer,
            rotationLayer
        ]

        for sublayer in sublayers {
            sublayer.position = center
            sublayer.bounds = bounds
        }

        strokeLayer.path = makeStrokePath()
        fovArcLayer.path = makeFovArcPath()
        deviceLayer.path = makeDevicePath()

        fovArcLayer.lineWidth = fovArcWidth
    }

    public func updateOrientation() {
        guard let dataSource = dataSource, let pointOfView = dataSource.pointOfView, let camera = pointOfView.camera else {
            return
        }

        let viewportRatio = Double(dataSource.viewportSize.width / dataSource.viewportSize.height)

        let fovInDegree: Double

        if #available(iOS 11, *) {
            switch camera.projectionDirection {
            case .horizontal:
                fovInDegree = Double(camera.fieldOfView)
            case .vertical:
                fovInDegree = Double(camera.fieldOfView) * viewportRatio
            }
        } else {
            if camera.xFov != 0 && camera.yFov != 0 {
                let fovRatio = camera.xFov / camera.yFov
                if fovRatio > viewportRatio {
                    fovInDegree = camera.xFov
                } else {
                    fovInDegree = camera.yFov * viewportRatio
                }
            } else if camera.xFov != 0 {
                fovInDegree = camera.xFov
            } else if camera.yFov != 0 {
                fovInDegree = camera.yFov * viewportRatio
            } else {
                fovInDegree = 60 * viewportRatio
            }
        }

        fov = Float(fovInDegree) / 180 * .pi

        let v1 = SCNVector3(0, 0, 1)
        let v2 = pointOfView.presentation.convertPosition(v1, to: nil)

        rotation = atan2(v2.z, v2.x) - (.pi / 2)
    }

    private func applyFov() {
        fovArcLayer.strokeEnd = CGFloat(fov) / (.pi * 2)
        fovArcLayer.transform = CATransform3DMakeRotation(CGFloat((.pi + fov) / -2), 0, 0, 1)
    }

    private func applyRotation() {
        rotationLayer.transform = CATransform3DMakeRotation(CGFloat(rotation), 0, 0, 1)
    }

    private func applyColor() {
        strokeLayer.strokeColor = color.withAlphaComponent(0.5).cgColor
        fovArcLayer.strokeColor = color.cgColor
        deviceLayer.fillColor = color.cgColor
    }

    private func makeStrokePath() -> CGPath {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = bounds.height / 2 - strokeWidth / 2

        let path = CGMutablePath()
        path.addRelativeArc(center: center, radius: radius, startAngle: 0, delta: .pi * 2)
        path.closeSubpath()

        return path
    }

    private func makeFovArcPath() -> CGPath {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = innerFovArcRadius + fovArcWidth / 2

        let path = CGMutablePath()
        path.addRelativeArc(center: center, radius: radius, startAngle: 0, delta: .pi * 2)
        path.closeSubpath()

        return path
    }

    private func makeDevicePath() -> CGPath {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let size = CGSize(width: 9, height: 3)
        let rect = CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
        let path = CGPath(roundedRect: rect, cornerWidth: size.height / 2, cornerHeight: size.height / 2, transform: nil)

        return path
    }
}

public final class OrientationIndicatorView: UIView, OrientationIndicator {
    public override class var layerClass: AnyClass {
        return OrientationIndicatorLayer.self
    }

    public var orientationIndicatorLayer: OrientationIndicatorLayer {
        return (layer as! OrientationIndicatorLayer)
    }

    public weak var dataSource: OrientationIndicatorDataSource? {
        get {
            return orientationIndicatorLayer.dataSource
        }
        set(value) {
            orientationIndicatorLayer.dataSource = value
        }
    }

    public override func tintColorDidChange() {
        super.tintColorDidChange()

        orientationIndicatorLayer.color = tintColor
    }

    public func updateOrientation() {
        updateOrientation(animated: false)
    }

    public func updateOrientation(animated: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)

        orientationIndicatorLayer.updateOrientation()

        CATransaction.commit()
    }
}
