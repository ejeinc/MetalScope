//
//  DeviceOrientationProvider.swift
//  Panoramic
//
//  Created by Jun Tanaka on 2017/01/17.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import CoreMotion

public protocol DeviceOrientationProvider {
	func deviceOrientation(atTime time: TimeInterval) -> Rotation?
}

extension CMMotionManager: DeviceOrientationProvider {
	public func deviceOrientation(atTime time: TimeInterval) -> Rotation? {
		guard let motion = deviceMotion else {
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
}

public final class DefaultDeviceOrientationProvider: DeviceOrientationProvider {
	public static let shared = DefaultDeviceOrientationProvider()

	private lazy var motionManager: CMMotionManager = {
		let manager = CMMotionManager()
		manager.deviceMotionUpdateInterval = 1 / 60
		return manager
	}()

	private let activeViewCountQueue = DispatchQueue(label: "com.eje-c.Panoramic.DefaultMotionManager.activeViewCountQueue")

	private var _activeViewCount: Int = 0 {
		didSet {
			guard motionManager.isDeviceMotionAvailable else {
				return
			}

			if _activeViewCount > 0 {
				if !motionManager.isDeviceMotionActive {
					motionManager.startDeviceMotionUpdates()
				}
			} else {
				motionManager.stopDeviceMotionUpdates()
			}
		}
	}

	var activeViewCount: Int {
		return activeViewCountQueue.sync { _activeViewCount }
	}

	func incrementActiveViewCount() {
		return activeViewCountQueue.async { [weak self] in
			self?._activeViewCount += 1
		}
	}

	func decrementActiveViewCount() {
		return activeViewCountQueue.async { [weak self] in
			self?._activeViewCount -= 1
		}
	}

	public func deviceOrientation(atTime time: TimeInterval) -> Rotation? {
		return motionManager.deviceOrientation(atTime: time)
	}
}
