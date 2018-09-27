//
//  DeviceOrientationProvider.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/17.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import CoreMotion

public protocol DeviceOrientationProvider {
    func deviceOrientation(atTime time: TimeInterval) -> Rotation?
    func shouldWaitDeviceOrientation(atTime time: TimeInterval) -> Bool
}

extension DeviceOrientationProvider {
    public func waitDeviceOrientation(atTime time: TimeInterval) {
        let _ = waitDeviceOrientation(atTime: time, timeout: .distantFuture)
    }

    public func waitDeviceOrientation(atTime time: TimeInterval, timeout: DispatchTime) -> DispatchTimeoutResult {
        guard deviceOrientation(atTime: time) == nil else {
            return .success
        }

        let semaphore = DispatchSemaphore(value: 0)

        let queue = DispatchQueue(label: "com.eje-c.MetalScope.DeviceOrientationProvider.waitingQueue")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(10))
        timer.setEventHandler {
            guard let _ = self.deviceOrientation(atTime: time) else {
                return
            }
            semaphore.signal()
        }
        timer.resume()
        defer { timer.cancel() }

        return semaphore.wait(timeout: timeout)
    }
}

extension CMMotionManager: DeviceOrientationProvider {
    public func deviceOrientation(atTime time: TimeInterval) -> Rotation? {
        guard let motion = deviceMotion else {
            return nil
        }

        let timeInterval = time - motion.timestamp

        guard timeInterval < 1 else {
            return nil
        }

        var rotation = Rotation(motion)

        if timeInterval > 0 {
            let rx = motion.rotationRate.x * timeInterval
            let ry = motion.rotationRate.y * timeInterval
            let rz = motion.rotationRate.z * timeInterval

            rotation.rotate(byX: Float(rx))
            rotation.rotate(byY: Float(ry))
            rotation.rotate(byZ: Float(rz))
        }

        let reference = Rotation(x: .pi / 2)

        return reference.inverted() * rotation.normalized()
    }

    public func shouldWaitDeviceOrientation(atTime time: TimeInterval) -> Bool {
        return isDeviceMotionActive && time - (deviceMotion?.timestamp ?? 0) > 1
    }
}

internal final class DefaultDeviceOrientationProvider: DeviceOrientationProvider {
    private static let motionManager = CMMotionManager()

    private static let instanceCountQueue = DispatchQueue(label: "com.eje-c.MetalScope.DefaultDeviceOrientationProvider.instanceCountQueue")

    private static var instanceCount: Int = 0 {
        didSet {
            let manager = motionManager

            guard manager.isDeviceMotionAvailable else {
                return
            }

            if instanceCount > 0, !manager.isDeviceMotionActive {
                manager.deviceMotionUpdateInterval = 1 / 60
                manager.startDeviceMotionUpdates()
            } else if instanceCount == 0, manager.isDeviceMotionActive {
                manager.stopDeviceMotionUpdates()
            }
        }
    }

    private static func incrementInstanceCount() {
        instanceCountQueue.async { instanceCount += 1 }
    }

    private static func decrementInstanceCount() {
        instanceCountQueue.async { instanceCount -= 1 }
    }

    init() {
        DefaultDeviceOrientationProvider.incrementInstanceCount()
    }

    deinit {
        DefaultDeviceOrientationProvider.decrementInstanceCount()
    }

    func deviceOrientation(atTime time: TimeInterval) -> Rotation? {
        return DefaultDeviceOrientationProvider.motionManager.deviceOrientation(atTime: time)
    }

    func shouldWaitDeviceOrientation(atTime time: TimeInterval) -> Bool {
        return DefaultDeviceOrientationProvider.motionManager.shouldWaitDeviceOrientation(atTime: time)
    }
}
