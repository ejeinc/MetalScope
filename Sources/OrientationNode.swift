//
//  OrientationNode.swift
//  PanoramaView
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

    public var deviceOrientationProvider: DeviceOrientationProvider? = DefaultDeviceOrientationProvider.shared {
        didSet {
            renewDefaultDeviceOrientationProviderTokenIfNeeded()
        }
    }

    public var interfaceOrientationProvider: InterfaceOrientationProvider? = DefaultInterfaceOrientationProvider.shared

    public override var isPaused: Bool {
        didSet {
            renewDefaultDeviceOrientationProviderTokenIfNeeded()
        }
    }

    private var defaultDeviceOrientationProviderToken: DefaultDeviceOrientationProvider.Token?

    public override init() {
        super.init()

        addChildNode(userRotationNode)
        userRotationNode.addChildNode(referenceRotationNode)
        referenceRotationNode.addChildNode(deviceOrientationNode)
        deviceOrientationNode.addChildNode(interfaceOrientationNode)
        interfaceOrientationNode.addChildNode(pointOfView)

        let camera = SCNCamera()
        camera.xFov = 60
        camera.yFov = 60
        pointOfView.camera = camera

        renewDefaultDeviceOrientationProviderTokenIfNeeded()
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
        guard let rotation = interfaceOrientationProvider?.interfaceOrientation(atTime: time) else {
            return
        }
        interfaceOrientationNode.orientation = rotation.scnQuaternion
    }

    public func resetCenter() {
        let r1 = Rotation(pointOfView.worldTransform).inverted()
        let r2 = Rotation(referenceRotationNode.worldTransform)
        let r3 = r1 * r2
        referenceRotationNode.transform = r3.scnMatrix4

        userRotationNode.transform = SCNMatrix4Identity
    }

    public func resetCenter(animated: Bool, completionHanlder: (() -> Void)? = nil) {
        SCNTransaction.lock()
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.6
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0, 0, 1)
        SCNTransaction.completionBlock = completionHanlder
        SCNTransaction.disableActions = !animated

        resetCenter()
        
        SCNTransaction.commit()
        SCNTransaction.unlock()
    }
    
    private func renewDefaultDeviceOrientationProviderTokenIfNeeded() {
        if !isPaused, let defaultProvider = deviceOrientationProvider as? DefaultDeviceOrientationProvider {
            defaultDeviceOrientationProviderToken = defaultProvider.makeToken()
        } else {
            defaultDeviceOrientationProviderToken = nil
        }
    }
}
