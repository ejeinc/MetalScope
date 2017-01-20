//
//  PanoramaView+InterfaceOrientation.swift
//  Axel
//
//  Created by Jun Tanaka on 2017/01/18.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit
import UIKit

extension PanoramaView {
	public func updateInterfaceOrientation() {
		let time = ProcessInfo.processInfo.systemUptime
		cameraNode.updateInterfaceOrientation(atTime: time)
	}

	public func updateInterfaceOrientation(with transitionCoordinator: UIViewControllerTransitionCoordinator) {
		transitionCoordinator.animate(alongsideTransition: { context in
			SCNTransaction.lock()
			SCNTransaction.begin()
			SCNTransaction.animationDuration = context.transitionDuration
			SCNTransaction.animationTimingFunction = context.completionCurve.caMediaTimingFunction
			SCNTransaction.disableActions = !context.isAnimated

			self.updateInterfaceOrientation()

			SCNTransaction.commit()
			SCNTransaction.unlock()
		}, completion: nil)
	}
}

private extension UIViewAnimationCurve {
	var caMediaTimingFunction: CAMediaTimingFunction {
		let name: String

		switch self {
		case .easeIn:
			name = kCAMediaTimingFunctionEaseIn
		case .easeOut:
			name = kCAMediaTimingFunctionEaseOut
		case .easeInOut:
			name = kCAMediaTimingFunctionEaseInEaseOut
		case .linear:
			name = kCAMediaTimingFunctionLinear
		}

		return CAMediaTimingFunction(name: name)
	}
}
