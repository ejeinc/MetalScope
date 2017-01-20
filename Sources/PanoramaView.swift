//
//  PanoramaView.swift
//  Panoramic
//
//  Created by Jun Tanaka on 2017/01/17.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import UIKit
import SceneKit
import CoreMotion

public final class PanoramaView: UIView, MediaSceneLoader {
	public let device: MTLDevice

	public var scene: SCNScene? {
		get {
			return scnView.scene
		}
		set(value) {
			cameraNode.removeFromParentNode()
			value?.rootNode.addChildNode(cameraNode)
			scnView.scene = value
		}
	}

	public weak var sceneRendererDelegate: SCNSceneRendererDelegate?

	public lazy var cameraNode = CameraNode()

	lazy var scnView: SCNView = {
		let view = SCNView(frame: self.bounds, options: [
			SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.metal.rawValue,
			SCNView.Option.preferredDevice.rawValue: self.device
		])
		view.backgroundColor = .black
		view.isUserInteractionEnabled = false
		view.antialiasingMode = .multisampling2X
		view.delegate = self
		view.pointOfView = self.cameraNode.pointOfView
		view.isPlaying = true
		self.addSubview(view)
		return view
	}()

	lazy var panGestureManager: PanGestureManager = {
		let helper = PanGestureManager(rotationNode: self.cameraNode.userRotationNode)
		helper.minimumVerticalRotationAngle = -60 / 180 * .pi
		helper.maximumVerticalRotationAngle = 60 / 180 * .pi
		return helper
	}()

	public init(frame: CGRect, device: MTLDevice) {
		self.device = device

		super.init(frame: frame)

		addGestureRecognizer(self.panGestureManager.gestureRecognizer)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func layoutSubviews() {
		super.layoutSubviews()

		scnView.frame = bounds
	}

	public override func willMove(toWindow newWindow: UIWindow?) {
		guard let provider = cameraNode.deviceOrientationProvider as? DefaultDeviceOrientationProvider else {
			return
		}

		if window != nil && newWindow == nil {
			provider.decrementActiveViewCount()
		} else if window == nil && newWindow != nil {
			provider.incrementActiveViewCount()
		}
	}
}

extension PanoramaView {
	public var sceneRenderer: SCNSceneRenderer {
		return scnView
	}

	public var antialiasingMode: SCNAntialiasingMode {
		get {
			return scnView.antialiasingMode
		}
		set(value) {
			scnView.antialiasingMode = value
		}
	}

	public func snapshot() -> UIImage {
		return scnView.snapshot()
	}

	public var panGestureRecognizer: UIPanGestureRecognizer {
		return panGestureManager.gestureRecognizer
	}

	@IBAction public func resetCenter(_ sender: Any) {
		cameraNode.resetCenter(animated: true)
	}
}

extension PanoramaView: SCNSceneRendererDelegate {
	public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		if let scene = renderer.scene as? VideoSceneProtocol {
			scene.renderVideo(atTime: time, renderer: renderer)
		}

		SCNTransaction.lock()
		SCNTransaction.begin()
		SCNTransaction.animationDuration = 1 / 15

		cameraNode.updateDeviceOrientation(atTime: time)

		SCNTransaction.commit()
		SCNTransaction.unlock()

		sceneRendererDelegate?.renderer?(renderer, updateAtTime: time)
	}

	public func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
		sceneRendererDelegate?.renderer?(renderer, didApplyAnimationsAtTime: time)
	}

	public func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
		sceneRendererDelegate?.renderer?(renderer, didSimulatePhysicsAtTime: time)
	}

	public func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
		sceneRendererDelegate?.renderer?(renderer, willRenderScene: scene, atTime: time)
	}

	public func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
		sceneRendererDelegate?.renderer?(renderer, didRenderScene: scene, atTime: time)
	}
}
