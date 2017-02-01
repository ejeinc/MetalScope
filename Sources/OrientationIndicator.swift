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
            updateArcLayer()
        }
    }

    public var rotation: Float = 0 {
        didSet {
            updateArcLayer()
        }
    }

    public var color: UIColor = .white {
        didSet {
            updateColors()
        }
    }

    public weak var dataSource: OrientationIndicatorDataSource?

    private let arrowLayer = CAShapeLayer()
    private let ringLayer = CAShapeLayer()
    private let arcLayer = CAShapeLayer()
    private let dotLayer = CAShapeLayer()

    private let arrowSize = CGSize(width: 6, height: 4)
    private let ringWidth: CGFloat = 2
    private let arcMargin: CGFloat = 2
    private let dotRadius: CGFloat = 2

    private var arcWidth: CGFloat {
        return bounds.height / 2 - arrowSize.height - ringWidth / 2 - arcMargin * 2 - dotRadius
    }

    public override init() {
        super.init()

        addSublayer(arrowLayer)
        addSublayer(ringLayer)
        addSublayer(arcLayer)
        addSublayer(dotLayer)

        ringLayer.lineWidth = 1

        arrowLayer.strokeColor = nil
        ringLayer.fillColor = nil
        arcLayer.fillColor = nil
        dotLayer.strokeColor = nil

        updateColors()
        updateArcLayer()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSublayers() {
        super.layoutSublayers()

        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        arrowLayer.position = center
        ringLayer.position = center
        arcLayer.position = center
        dotLayer.position = center

        arrowLayer.bounds = bounds
        ringLayer.bounds = bounds
        arcLayer.bounds = bounds
        dotLayer.bounds = bounds

        arrowLayer.path = makeArrowPath()
        ringLayer.path = makeRingPath()
        arcLayer.path = makeArcPath()
        dotLayer.path = makeDotPath()

        arcLayer.lineWidth = arcWidth
    }

    public func updateOrientation() {
        guard let dataSource = dataSource, let pointOfView = dataSource.pointOfView, let camera = pointOfView.camera else {
            return
        }

        let viewportRatio = Double(dataSource.viewportSize.width / dataSource.viewportSize.height)

        let fovInDegree: Double
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

        fov = Float(fovInDegree) / 180 * .pi

        let v1 = SCNVector3(0, 0, 1)
        let v2 = pointOfView.presentation.convertPosition(v1, to: nil)
        rotation = atan2(v2.z, v2.x) - (.pi / 2)
    }

    private func updateColors() {
        arrowLayer.fillColor = color.cgColor
        ringLayer.strokeColor = color.cgColor
        arcLayer.strokeColor = color.cgColor
        dotLayer.fillColor = color.cgColor
    }

    private func updateArcLayer() {
        arcLayer.strokeStart = 0
        arcLayer.strokeEnd = CGFloat(fov) / (.pi * 2)
        arcLayer.transform = CATransform3DMakeRotation(CGFloat(rotation - (.pi + fov) / 2), 0, 0, 1)
    }

    private func makeArrowPath() -> CGPath {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: center.x, y: bounds.minY))
        path.addLine(to: CGPoint(x: center.x + arrowSize.width / 2, y: bounds.minY + arrowSize.height))
        path.addLine(to: CGPoint(x: center.x - arrowSize.width / 2, y: bounds.minY + arrowSize.height))
        path.closeSubpath()

        return path
    }

    private func makeRingPath() -> CGPath {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = bounds.height / 2 - arrowSize.height

        let path = CGMutablePath()
        path.addRelativeArc(center: center, radius: radius, startAngle: 0, delta: .pi * 2)
        path.closeSubpath()

        return path
    }

    private func makeArcPath() -> CGPath {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = dotRadius + arcMargin + arcWidth / 2

        let path = CGMutablePath()
        path.addRelativeArc(center: center, radius: radius, startAngle: 0, delta: .pi * 2)
        path.closeSubpath()

        return path
    }

    private func makeDotPath() -> CGPath {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = dotRadius

        let path = CGMutablePath()
        path.addRelativeArc(center: center, radius: radius, startAngle: 0, delta: .pi * 2)
        path.closeSubpath()
        
        return path
    }
}

public final class OrientationIndicatorView: UIView, OrientationIndicator {
    public override class var layerClass: AnyClass {
        return OrientationIndicatorLayer.self
    }

    public weak var dataSource: OrientationIndicatorDataSource? {
        get {
            return (layer as! OrientationIndicatorLayer).dataSource
        }
        set(value) {
            (layer as! OrientationIndicatorLayer).dataSource = value
        }
    }

    public func updateOrientation() {
        updateOrientation(animated: false)
    }

    public func updateOrientation(animated: Bool) {
        CATransaction.lock()
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)

        (layer as! OrientationIndicatorLayer).updateOrientation()

        CATransaction.commit()
        CATransaction.unlock()
    }
}
