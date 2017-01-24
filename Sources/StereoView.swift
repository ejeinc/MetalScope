//
//  StereoView.swift
//  PanoramaView
//
//  Created by Jun Tanaka on 2017/01/23.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import UIKit
import SceneKit

public final class StereoView: UIView, MediaSceneLoader {
    public var device: MTLDevice {
        return stereoTexture.device
    }

    public var scene: SCNScene? {
        get {
            return stereoRenderer.scene
        }
        set(value) {
            orientationNode.removeFromParentNode()
            value?.rootNode.addChildNode(orientationNode)
            stereoRenderer.scene = value
        }
    }

    public lazy var orientationNode: OrientationNode = {
        let node = OrientationNode()
        node.pointOfView.addChildNode(self.stereoCameraNode)
        node.interfaceOrientationProvider = UIInterfaceOrientation.landscapeRight
        node.updateInterfaceOrientation()
        return node
    }()

    public lazy var stereoCameraNode: StereoCameraNode = {
        let node = StereoCameraNode(stereoParameters: self.stereoParameters)
        node.position = SCNVector3(0, 0.1, -0.08)
        return node
    }()

    public let stereoTexture: MTLTexture

    public var stereoParameters: StereoParametersProtocol = defaultStereoParameters {
        didSet {
            stereoCameraNode.stereoParameters = stereoParameters
            stereoScene.stereoParameters = stereoParameters
        }
    }

    public lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer()
        self.addGestureRecognizer(recognizer)
        return recognizer
    }()

    lazy var scnView: SCNView = {
        let view = SCNView(frame: self.bounds, options: [
            SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.metal.rawValue,
            SCNView.Option.preferredDevice.rawValue: self.device
        ])
        view.backgroundColor = .black
        view.isUserInteractionEnabled = false
        view.delegate = self
        view.scene = self.stereoScene
        view.pointOfView = self.stereoScene.pointOfView
        view.isPlaying = true
        self.addSubview(view)
        return view
    }()

    fileprivate lazy var stereoRenderer: StereoRenderer = {
        let renderer = StereoRenderer(outputTexture: self.stereoTexture)
        renderer.setPointOfView(self.stereoCameraNode.pointOfView(for: .left), for: .left)
        renderer.setPointOfView(self.stereoCameraNode.pointOfView(for: .right), for: .right)
        return renderer
    }()

    fileprivate lazy var stereoScene: StereoScene = {
        let scene = StereoScene()
        scene.stereoParameters = self.stereoParameters
        scene.stereoTexture = self.stereoTexture
        return scene
    }()

    private static let defaultStereoParameters = StereoParameters(screen: ScreenModel.default, viewer: ViewerModel.default)

    public init(stereoTexture: MTLTexture) {
        self.stereoTexture = stereoTexture

        super.init(frame: UIScreen.main.landscapeBounds)
    }

    public convenience init(device: MTLDevice, maximumTextureSize: CGSize? = nil) {
        let nativeScreenSize = UIScreen.main.nativeLandscapeBounds.size
        var textureSize = nativeScreenSize

        if let maxSize = maximumTextureSize {
            let nRatio = nativeScreenSize.width / nativeScreenSize.height
            let mRatio = maxSize.width / maxSize.height
            if nRatio >= mRatio && nativeScreenSize.width > maxSize.width {
                textureSize.width = maxSize.width
                textureSize.height = round(maxSize.width / nRatio)
            } else if nRatio <= mRatio && nativeScreenSize.height > maxSize.height {
                textureSize.width = round(maxSize.height * nRatio)
                textureSize.height = maxSize.height
            }
        }

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm_srgb,
            width: Int(textureSize.width),
            height: Int(textureSize.height),
            mipmapped: false
        )
        let texture = device.makeTexture(descriptor: textureDescriptor)

        self.init(stereoTexture: texture)

        let sceneScale = textureSize.width / (bounds.width * UIScreen.main.scale)
        scnView.transform = CGAffineTransform(scaleX: sceneScale, y: sceneScale)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        scene = nil
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        scnView.frame = bounds
    }
}

extension StereoView {
    public var sceneRenderer: SCNSceneRenderer {
        return stereoRenderer.scnRenderer
    }

    public func sceneRendererDelegate(for eye: Eye) -> SCNSceneRendererDelegate? {
        return stereoRenderer.sceneRendererDelegate(for: eye)
    }

    public func setSceneRendererDelegate(_ delegate: SCNSceneRendererDelegate, for eye: Eye) {
        stereoRenderer.setSceneRendererDelegate(delegate, for: eye)
    }

    public var isPlaying: Bool {
        get {
            return scnView.isPlaying
        }
        set(value) {
            scnView.isPlaying = value
        }
    }

    public func snapshot() -> UIImage {
        return scnView.snapshot()
    }

    @IBAction public func resetCenter(_ sender: Any) {
        orientationNode.resetCenter(animated: true)
    }
}

extension StereoView: SCNSceneRendererDelegate {
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let provider = orientationNode.deviceOrientationProvider, provider.shouldWaitDeviceOrientation(atTime: time) {
            provider.waitDeviceOrientation(atTime: time)
        }

        SCNTransaction.lock()
        SCNTransaction.begin()
        SCNTransaction.disableActions = true

        orientationNode.updateDeviceOrientation(atTime: time)

        SCNTransaction.commit()
        SCNTransaction.unlock()
    }

    public func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if let scene = scene as? VideoSceneProtocol {
            scene.renderVideo(atTime: time, renderer: renderer)
        }

        stereoRenderer.render(atTime: time)
    }
}

private extension UIScreen {
    var landscapeBounds: CGRect {
        return CGRect(x: 0, y: 0, width: fixedCoordinateSpace.bounds.height, height: fixedCoordinateSpace.bounds.width)
    }
    
    var nativeLandscapeBounds: CGRect {
        return CGRect(x: 0, y: 0, width: nativeBounds.height, height: nativeBounds.width)
    }
}
