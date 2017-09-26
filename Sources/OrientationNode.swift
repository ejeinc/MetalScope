//
//  OrientationNode.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/19.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit

public final class OrientationNode: SCNNode {
    let userRotationNode = SCNNode()
    let referenceRotationNode = SCNNode()
    let deviceOrientationNode = SCNNode()
    let interfaceOrientationNode = SCNNode()

    public let pointOfView = SCNNode()

    public var fieldOfView: CGFloat = 60 {
        didSet {
            self.updateCamera()
        }
    }

    public var deviceOrientationProvider: DeviceOrientationProvider? = DefaultDeviceOrientationProvider()

    public var interfaceOrientationProvider: InterfaceOrientationProvider? = DefaultInterfaceOrientationProvider()

    public override init() {
        super.init()

        addChildNode(userRotationNode)
        userRotationNode.addChildNode(referenceRotationNode)
        referenceRotationNode.addChildNode(deviceOrientationNode)
        deviceOrientationNode.addChildNode(interfaceOrientationNode)
        interfaceOrientationNode.addChildNode(pointOfView)

        let camera = SCNCamera()
        camera.zNear = 0.3
        pointOfView.camera = camera

        self.updateCamera()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateDeviceOrientation(atTime time: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        guard let rotation = deviceOrientationProvider?.deviceOrientation(atTime: time) else {
            return
        }
        deviceOrientationNode.orientation = rotation.scnQuaternion
    }

    public func updateInterfaceOrientation(atTime time: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        guard let interfaceOrientation = interfaceOrientationProvider?.interfaceOrientation(atTime: time) else {
            return
        }

        var rotation = Rotation()

        switch interfaceOrientation {
        case .portraitUpsideDown:
            rotation.rotate(byZ: .pi)
        case .landscapeLeft:
            rotation.rotate(byZ: .pi / 2)
        case .landscapeRight:
            rotation.rotate(byZ: .pi / -2)
        default:
            break
        }

        interfaceOrientationNode.orientation = rotation.scnQuaternion

        if #available(iOS 11, *) {
            let cameraProjectionDirection: SCNCameraProjectionDirection

            switch interfaceOrientation {
            case .landscapeLeft, .landscapeRight:
                cameraProjectionDirection = .vertical
            default:
                cameraProjectionDirection = .horizontal
            }

            pointOfView.camera?.projectionDirection = cameraProjectionDirection
        }
    }

    public func resetRotation() {
        let r1 = Rotation(pointOfView.presentation.worldTransform).inverted()
        let r2 = Rotation(referenceRotationNode.presentation.worldTransform)
        let r3 = r1 * r2
        referenceRotationNode.transform = r3.scnMatrix4

        userRotationNode.transform = SCNMatrix4Identity
    }

    public func resetRotation(animated: Bool, completionHanlder: (() -> Void)? = nil) {
        SCNTransaction.lock()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.6
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0, 0, 1)
        SCNTransaction.completionBlock = completionHanlder
        SCNTransaction.disableActions = !animated

        resetRotation()

        SCNTransaction.commit()
        SCNTransaction.unlock()
    }

    /// Requests reset of rotation in the next rendering frame.
    ///
    /// - Parameter animated: Pass true to animate the transition.
    public func setNeedsResetRotation(animated: Bool) {
        let action = SCNAction.run { node in
            (node as! OrientationNode).resetRotation(animated: animated)
        }
        runAction(action, forKey: "setNeedsResetRotation")
    }

    private func updateCamera() {
        guard let camera = self.pointOfView.camera else {
            return
        }

        if #available(iOS 11, *) {
            camera.fieldOfView = fieldOfView
        } else {
            camera.xFov = Double(fieldOfView)
            camera.yFov = Double(fieldOfView)
        }
    }
}
