//
//  StereoViewController.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/23.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import UIKit
import SceneKit

open class StereoViewController: UIViewController, SceneLoadable {
    #if (arch(arm) || arch(arm64)) && os(iOS)
    open let device: MTLDevice
    #endif

    open var scene: SCNScene? {
        didSet {
            _stereoView?.scene = scene
        }
    }

    open var stereoParameters: StereoParametersProtocol = StereoParameters() {
        didSet {
            _stereoView?.stereoParameters = stereoParameters
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

    open var introductionView: UIView? {
        willSet {
            introductionView?.removeFromSuperview()
        }
        didSet {
            guard isViewLoaded else {
                return
            }
            if let _ = introductionView {
                showIntroductionView()
            } else {
                hideIntroductionView()
            }
        }
    }

    private weak var _stereoView: StereoView?
    private weak var _closeButton: UIButton?
    private weak var _helpButton: UIButton?

    private weak var introdutionContainerView: UIView?
    private var introductionViewUpdateTimer: DispatchSourceTimer?

    #if (arch(arm) || arch(arm64)) && os(iOS)
    public init(device: MTLDevice) {
        self.device = device

        super.init(nibName: nil, bundle: nil)
    }
    #else
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    #endif

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func loadView() {
        #if (arch(arm) || arch(arm64)) && os(iOS)
        let stereoView = StereoView(device: device)
        #else
        let stereoView = StereoView()
        #endif
        stereoView.backgroundColor = .black
        stereoView.scene = scene
        stereoView.stereoParameters = stereoParameters
        stereoView.translatesAutoresizingMaskIntoConstraints = false
        stereoView.isPlaying = false
        _stereoView = stereoView

        let introductionContainerView = UIView(frame: stereoView.bounds)
        introductionContainerView.isHidden = true
        self.introdutionContainerView = introductionContainerView

        let view = UIView(frame: stereoView.bounds)
        view.backgroundColor = .black
        view.addSubview(stereoView)
        view.addSubview(introductionContainerView)
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

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        introdutionContainerView!.bounds = view!.bounds
        introdutionContainerView!.center = CGPoint(x: view!.bounds.midX, y: view!.bounds.midY)
        introductionView?.frame = introdutionContainerView!.bounds
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if animated {
            _stereoView?.alpha = 0
        }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        _stereoView?.isPlaying = true

        if animated {
            UIView.animate(withDuration: 0.2) {
                self._stereoView?.alpha = 1
            }
        }

        if UIDevice.current.orientation != .unknown {
            showIntroductionView(animated: animated)
            startIntroductionViewVisibilityUpdates()
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        _stereoView?.isPlaying = false

        stopIntroductionViewVisibilityUpdates()
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

        view.addSubview(closeButton)

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

        view.addSubview(helpButton)

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

    private func showIntroductionView(animated: Bool = false) {
        precondition(isViewLoaded)

        guard let introductionView = introductionView, let containerView = introdutionContainerView, let stereoView = _stereoView else {
            return
        }

        if introductionView.superview != containerView {
            introductionView.frame = containerView.bounds
            introductionView.autoresizingMask = []
            containerView.addSubview(introductionView)
        }

        if animated {
            if containerView.isHidden {
                containerView.isHidden = false
                containerView.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height)
            }
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                usingSpringWithDamping: 1,
                initialSpringVelocity: 0,
                options: [.beginFromCurrentState],
                animations: {
                    containerView.transform = .identity
                    stereoView.alpha = 0
                },
                completion: nil)
        } else {
            containerView.isHidden = false
            containerView.transform = .identity
            stereoView.alpha = 0
        }
    }

    private func hideIntroductionView(animated: Bool = false) {
        precondition(isViewLoaded)

        guard let containerView = introdutionContainerView, let stereoView = _stereoView else {
            return
        }

        if animated {
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                usingSpringWithDamping: 1,
                initialSpringVelocity: 0,
                options: [.beginFromCurrentState],
                animations: {
                    containerView.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height)
                    stereoView.alpha = 1
                },
                completion: { isFinished in
                    guard isFinished else {
                        return
                    }
                    containerView.isHidden = true
                    containerView.transform = .identity
                })
        } else {
            containerView.isHidden = true
            containerView.transform = .identity
            stereoView.alpha = 1
        }
    }

    private func startIntroductionViewVisibilityUpdates(withInterval interval: TimeInterval = 3, afterDelay delay: TimeInterval = 3) {
        precondition(introductionViewUpdateTimer == nil)

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + delay, repeating: interval)
        timer.setEventHandler { [weak self] in
            guard self?.isViewLoaded == true, let _ = self?.introductionView else {
                return
            }
            switch UIDevice.current.orientation {
            case .landscapeLeft where self?.introdutionContainerView?.isHidden == false:
                self?.hideIntroductionView(animated: true)
            case .landscapeRight where self?.introdutionContainerView?.isHidden == true:
                self?.showIntroductionView(animated: true)
            default:
                break
            }
        }
        timer.resume()

        introductionViewUpdateTimer = timer
    }

    private func stopIntroductionViewVisibilityUpdates() {
        introductionViewUpdateTimer?.cancel()
        introductionViewUpdateTimer = nil
    }
}

extension StereoViewController: ImageLoadable {}

#if (arch(arm) || arch(arm64)) && os(iOS)
extension StereoViewController: VideoLoadable {}
#endif
