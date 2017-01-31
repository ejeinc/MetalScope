//
//  MetalScope+PanGesture.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/18.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass
import SceneKit

extension PanoramaView {
    private final class PanGestureRecognizer: UIPanGestureRecognizer {
        fileprivate var earlyTouchEventHandler: (() -> Void)?

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesBegan(touches, with: event)

            if state == .possible {
                earlyTouchEventHandler?()
            }
        }
    }

    internal final class PanGestureManager: NSObject, UIGestureRecognizerDelegate {
        let rotationNode: SCNNode

        var allowsVerticalRotation = true
        var minimumVerticalRotationAngle: Float?
        var maximumVerticalRotationAngle: Float?

        var allowsHorizontalRotation = true
        var minimumHorizontalRotationAngle: Float?
        var maximumHorizontalRotationAngle: Float?

        lazy var gestureRecognizer: UIPanGestureRecognizer = {
            let recognizer = PanGestureRecognizer()
            recognizer.addTarget(self, action: #selector(handlePanGesture(_:)))
            recognizer.earlyTouchEventHandler = { [weak self] in
                self?.resetReferenceAngles()
            }
            return recognizer
        }()

        private var referenceAngles: SCNVector3?

        init(rotationNode: SCNNode) {
            self.rotationNode = rotationNode
        }

        func handlePanGesture(_ sender: UIPanGestureRecognizer) {
            guard let view = sender.view else {
                return
            }

            switch sender.state {
            case .changed:
                var angles = SCNVector3Zero
                let viewSize = max(view.bounds.width, view.bounds.height)
                let translation = sender.translation(in: view)

                if allowsVerticalRotation, let ref = referenceAngles?.x {
                    var angle = ref + Float(translation.y / viewSize) * (.pi / 2)
                    if let minimum = minimumVerticalRotationAngle {
                        angle = max(angle, minimum)
                    }
                    if let maximum = maximumVerticalRotationAngle {
                        angle = min(angle, maximum)
                    }
                    angles.x = angle
                }

                if allowsHorizontalRotation, let ref = referenceAngles?.y {
                    var angle = ref + Float(translation.x / viewSize) * (.pi / 2)
                    if let minimum = minimumHorizontalRotationAngle {
                        angle = max(angle, minimum)
                    }
                    if let maximum = maximumHorizontalRotationAngle {
                        angle = min(angle, maximum)
                    }
                    angles.y = angle
                }

                rotationNode.eulerAngles = normalize(angles)

            case .ended:
                var angles = rotationNode.eulerAngles
                let velocity = sender.velocity(in: view)
                let viewSize = max(view.bounds.width, view.bounds.height)

                if allowsVerticalRotation {
                    var angle = angles.x
                    angle += Float(velocity.y / viewSize) / .pi
                    if let minimum = minimumVerticalRotationAngle {
                        angle = max(angle, minimum)
                    }
                    if let maximum = maximumVerticalRotationAngle {
                        angle = min(angle, maximum)
                    }
                    angles.x = angle
                }

                if allowsHorizontalRotation {
                    var angle = angles.y
                    angle += Float(velocity.x / viewSize) / .pi
                    if let minimum = minimumHorizontalRotationAngle {
                        angle = max(angle, minimum)
                    }
                    if let maximum = maximumHorizontalRotationAngle {
                        angle = min(angle, maximum)
                    }
                    angles.y = angle
                }

                SCNTransaction.lock()
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(controlPoints: 0.165, 0.84, 0.44, 1)

                rotationNode.eulerAngles = angles

                SCNTransaction.commit()
                SCNTransaction.unlock()

            default:
                break
            }
        }

        private func resetReferenceAngles() {
            let angles = normalize(rotationNode.presentation.eulerAngles)
            rotationNode.eulerAngles = angles // stop animation
            referenceAngles = angles
        }

        private func normalize(_ angle: Float) -> Float {
            if angle > .pi {
                return angle - (.pi * 2) * ceil(abs(angle) / (.pi * 2))
            } else if angle < -.pi {
                return angle + (.pi * 2) * ceil(abs(angle) / (.pi * 2))
            } else {
                return angle
            }
        }

        private func normalize(_ angles: SCNVector3) -> SCNVector3 {
            return SCNVector3(
                x: normalize(angles.x),
                y: normalize(angles.y),
                z: normalize(angles.z)
            )
        }
    }
}

