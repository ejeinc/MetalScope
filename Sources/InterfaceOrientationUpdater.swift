//
//  InterfaceOrientationUpdater.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/31.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit
import UIKit

internal final class InterfaceOrientationUpdater {
    let orientationNode: OrientationNode

    private var isTransitioning = false
    private var deviceOrientationDidChangeNotificationObserver: NSObjectProtocol?

    init(orientationNode: OrientationNode) {
        self.orientationNode = orientationNode
    }

    deinit {
        stopAutomaticInterfaceOrientationUpdates()
    }

    func updateInterfaceOrientation() {
        orientationNode.updateInterfaceOrientation()
    }

    func updateInterfaceOrientation(with transitionCoordinator: UIViewControllerTransitionCoordinator) {
        isTransitioning = true

        transitionCoordinator.animate(alongsideTransition: { context in
            SCNTransaction.lock()
            SCNTransaction.begin()
            SCNTransaction.animationDuration = context.transitionDuration
            SCNTransaction.animationTimingFunction = context.completionCurve.caMediaTimingFunction
            SCNTransaction.disableActions = !context.isAnimated

            self.updateInterfaceOrientation()

            SCNTransaction.commit()
            SCNTransaction.unlock()
        }, completion: { _ in
            self.isTransitioning = false
        })
    }

    func startAutomaticInterfaceOrientationUpdates() {
        guard deviceOrientationDidChangeNotificationObserver == nil else {
            return
        }

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        let observer = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            guard UIDevice.current.orientation.isValidInterfaceOrientation, self?.isTransitioning == false else {
                return
            }
            self?.updateInterfaceOrientation()
        }

        deviceOrientationDidChangeNotificationObserver = observer
    }

    func stopAutomaticInterfaceOrientationUpdates() {
        guard let observer = deviceOrientationDidChangeNotificationObserver else {
            return
        }

        UIDevice.current.endGeneratingDeviceOrientationNotifications()

        NotificationCenter.default.removeObserver(observer)

        deviceOrientationDidChangeNotificationObserver = nil
    }
}

private extension UIView.AnimationCurve {
    var caMediaTimingFunction: CAMediaTimingFunction {
        let name: String

        switch self {
        case .easeIn:
            name = convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.easeIn)
        case .easeOut:
            name = convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.easeOut)
        case .easeInOut:
            name = convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.easeInEaseOut)
        case .linear:
            name = convertFromCAMediaTimingFunctionName(CAMediaTimingFunctionName.linear)
        }
        
        return CAMediaTimingFunction(name: convertToCAMediaTimingFunctionName(name))
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromCAMediaTimingFunctionName(_ input: CAMediaTimingFunctionName) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToCAMediaTimingFunctionName(_ input: String) -> CAMediaTimingFunctionName {
	return CAMediaTimingFunctionName(rawValue: input)
}
