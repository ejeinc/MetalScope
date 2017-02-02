//
//  StereoViewController.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/23.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import UIKit
import SceneKit

open class StereoViewController: UIViewController, MediaSceneLoader {
    open let device: MTLDevice

    open var scene: SCNScene? {
        didSet {
            _stereoView?.scene = scene
        }
    }

    open var stereoView: StereoView {
        if !isViewLoaded {
            loadView()
        }
        guard let view = _stereoView else {
            fatalError("Unexpected context to load stereoView")
        }
        return view
    }

    open var showsCloseButton: Bool = true {
        didSet {
            _closeButton?.isHidden = !showsCloseButton
        }
    }

    open var closeButton: UIButton {
        if _closeButton == nil {
            loadCloseButton()
        }
        guard let button = _closeButton else {
            fatalError("Unexpected context to load closeButton")
        }
        return button
    }

    open var closeButtonHandler: ((_ sender: UIButton) -> Void)?

    open var showsHelpButton: Bool = false {
        didSet {
            _helpButton?.isHidden = !showsHelpButton
        }
    }

    open var helpButton: UIButton {
        if _helpButton == nil {
            loadHelpButton()
        }
        guard let button = _helpButton else {
            fatalError("Unexpected context to load helpButton")
        }
        return button
    }

    open var helpButtonHandler: ((_ sender: UIButton) -> Void)?

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

    open override func loadView() {
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

    open override var prefersStatusBarHidden: Bool {
        return true
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
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
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 11, left: 11, bottom: 0, right: 0)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        _closeButton = closeButton

        view.insertSubview(closeButton, aboveSubview: stereoView)

        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 88),
            closeButton.heightAnchor.constraint(equalToConstant: 88),
            closeButton.topAnchor.constraint(equalTo: view.topAnchor),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])

        closeButton.addTarget(self, action: #selector(handleTapOnCloseButton(_:)), for: .touchUpInside)
    }

    @objc private func handleTapOnCloseButton(_ sender: UIButton) {
        if let handler = closeButtonHandler {
            handler(sender)
        } else if sender.allTargets.count == 1 {
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
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
        helpButton.contentEdgeInsets = UIEdgeInsets(top: 11, left: 0, bottom: 0, right: 11)
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        _helpButton = helpButton

        view.insertSubview(helpButton, aboveSubview: stereoView)

        NSLayoutConstraint.activate([
            helpButton.widthAnchor.constraint(equalToConstant: 88),
            helpButton.heightAnchor.constraint(equalToConstant: 88),
            helpButton.topAnchor.constraint(equalTo: view.topAnchor),
            helpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        helpButton.addTarget(self, action: #selector(handleTapOnHelpButton(_:)), for: .touchUpInside)
    }

    @objc private func handleTapOnHelpButton(_ sender: UIButton) {
        if let handler = helpButtonHandler {
            handler(sender)
        } else if sender.allTargets.count == 1 {
            let url = URL(string: "https://support.google.com/cardboard/answer/6383058")!
            UIApplication.shared.openURL(url)
        }
    }
}
