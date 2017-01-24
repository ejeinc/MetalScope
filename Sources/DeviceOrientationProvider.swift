//
//  DeviceOrientationProvider.swift
//  PanoramaView
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
        let semaphore = DispatchSemaphore(value: 0)

        let queue = DispatchQueue(label: "com.eje-c.PanoramaView.DeviceOrientationProvider.waitingQueue")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.scheduleRepeating(deadline: .now(), interval: .milliseconds(10))
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
        guard let motion = deviceMotion, abs(motion.timestamp - time) < 1 else {
            return nil
        }

        var rotation = Rotation(motion)

        let interval = time - motion.timestamp

        let rx = motion.rotationRate.x * interval
        let ry = motion.rotationRate.y * interval
        let rz = motion.rotationRate.z * interval

        rotation.rotate(byX: Float(rx))
        rotation.rotate(byY: Float(ry))
        rotation.rotate(byZ: Float(rz))

        let reference = Rotation(x: .pi / 2)

        return reference.inverted() * rotation.normalized()
    }

    public func shouldWaitDeviceOrientation(atTime time: TimeInterval) -> Bool {
        return isDeviceMotionActive && abs((deviceMotion?.timestamp ?? 0) - time) > 1
    }
}

public final class DefaultDeviceOrientationProvider: DeviceOrientationProvider {
    public static let shared = DefaultDeviceOrientationProvider()

    private lazy var motionManager: CMMotionManager = {
        let manager = CMMotionManager()
        manager.deviceMotionUpdateInterval = 1 / 60
        return manager
    }()

    private let tokenCountQueue = DispatchQueue(label: "com.eje-c.PanoramaView.DefaultDeviceOrientationProvider.tokenCountQueue")

    private var tokenCount: Int = 0 {
        didSet {
            guard motionManager.isDeviceMotionAvailable else {
                return
            }
            if tokenCount > 0 {
                if !motionManager.isDeviceMotionActive {
                    motionManager.startDeviceMotionUpdates()
                }
            } else {
                motionManager.stopDeviceMotionUpdates()
            }
        }
    }

    public var isPaused: Bool {
        return tokenCountQueue.sync { !motionManager.isDeviceMotionActive }
    }

    public func makeToken() -> Token {
        tokenCountQueue.async { self.tokenCount += 1 }
        return Token {
            self.tokenCountQueue.async { self.tokenCount -= 1 }
        }
    }

    public func deviceOrientation(atTime time: TimeInterval) -> Rotation? {
        return motionManager.deviceOrientation(atTime: time)
    }

    public func shouldWaitDeviceOrientation(atTime time: TimeInterval) -> Bool {
        return motionManager.shouldWaitDeviceOrientation(atTime: time)
    }
}

extension DefaultDeviceOrientationProvider {
    public final class Token {
        private let invalidation: () -> Void
        
        fileprivate init(_ invalidation: @escaping () -> Void) {
            self.invalidation = invalidation
        }
        
        deinit {
            invalidation()
        }
    }
}
