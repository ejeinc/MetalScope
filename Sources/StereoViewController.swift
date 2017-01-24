//
//  StereoViewController.swift
//  PanoramaView
//
//  Created by Jun Tanaka on 2017/01/23.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import UIKit
import SceneKit

public class StereoViewController: UIViewController {
    public let device: MTLDevice

    public var scene: SCNScene? {
        didSet {
            _stereoView?.scene = scene
        }
    }

    public var stereoView: StereoView {
        if !isViewLoaded {
            loadView()
        }
        guard let view = _stereoView else {
            fatalError("Unexpected context to load stereoView")
        }
        return view
    }

    public var showsCloseButton: Bool = true {
        didSet {
            _closeButton?.isHidden = !showsCloseButton
        }
    }

    public var closeButton: UIButton {
        if _closeButton == nil {
            loadCloseButton()
        }
        guard let button = _closeButton else {
            fatalError("Unexpected context to load closeButton")
        }
        return button
    }

    public var showsHelpButton: Bool = true {
        didSet {
            _helpButton?.isHidden = !showsHelpButton
        }
    }

    public var helpButton: UIButton {
        if _helpButton == nil {
            loadHelpButton()
        }
        guard let button = _helpButton else {
            fatalError("Unexpected context to load helpButton")
        }
        return button
    }

    private weak var _stereoView: StereoView?
    private weak var _closeButton: UIButton?
    private weak var _helpButton: UIButton?

    public init(device: MTLDevice) {
        self.device = device

        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        let stereoView = StereoView(device: device)
        stereoView.scene = scene
        stereoView.translatesAutoresizingMaskIntoConstraints = false
        _stereoView = stereoView

        let view = UIView(frame: stereoView.bounds)
        view.addSubview(stereoView)
        self.view = view

        NSLayoutConstraint.activate([
            stereoView.topAnchor.constraint(equalTo: view.topAnchor),
            stereoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stereoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stereoView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        if showsCloseButton {
            loadCloseButton()
        }

        if showsHelpButton {
            loadHelpButton()
        }
    }

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }

    private func loadCloseButton() {
        if !isViewLoaded {
            loadView()
        }

        let icon = UIImage(named: "icon-close", in: Bundle(for: StereoViewController.self), compatibleWith: nil)

        let closeButton = UIButton(type: .system)
        closeButton.setImage(icon, for: .normal)
        closeButton.isHidden = !showsCloseButton
        closeButton.contentVerticalAlignment = .top
        closeButton.contentHorizontalAlignment = .left
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 19, left: 19, bottom: 0, right: 0)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        _closeButton = closeButton

        view.insertSubview(closeButton, aboveSubview: stereoView)

        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 88),
            closeButton.heightAnchor.constraint(equalToConstant: 88),
            closeButton.topAnchor.constraint(equalTo: view.topAnchor),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }

    private func loadHelpButton() {
        if !isViewLoaded {
            loadView()
        }

        let icon = UIImage(named: "icon-help", in: Bundle(for: StereoViewController.self), compatibleWith: nil)
        
        let helpButton = UIButton(type: .system)
        helpButton.setImage(icon, for: .normal)
        helpButton.isHidden = !showsHelpButton
        helpButton.contentVerticalAlignment = .top
        helpButton.contentHorizontalAlignment = .right
        helpButton.contentEdgeInsets = UIEdgeInsets(top: 19, left: 0, bottom: 0, right: 19)
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        _helpButton = helpButton
        
        view.insertSubview(helpButton, aboveSubview: stereoView)
        
        NSLayoutConstraint.activate([
            helpButton.widthAnchor.constraint(equalToConstant: 88),
            helpButton.heightAnchor.constraint(equalToConstant: 88),
            helpButton.topAnchor.constraint(equalTo: view.topAnchor),
            helpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}