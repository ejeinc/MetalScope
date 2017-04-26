//
//  ViewController.swift
//  StereoImage
//
//  Created by Jun Tanaka on 2017/01/20.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import UIKit
import Metal
import MetalScope

final class ViewController: UIViewController {
    lazy var device: MTLDevice = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Failed to create MTLDevice")
        }
        return device
    }()

    weak var panoramaView: PanoramaView?

    private func loadPanoramaView() {
        let panoramaView = PanoramaView(frame: view.bounds, device: device)
        panoramaView.setNeedsResetRotation()
        panoramaView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panoramaView)

        // fill parent view
        let constraints: [NSLayoutConstraint] = [
            panoramaView.topAnchor.constraint(equalTo: view.topAnchor),
            panoramaView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            panoramaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panoramaView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        NSLayoutConstraint.activate(constraints)

        // double tap to reset rotation
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: panoramaView, action: #selector(PanoramaView.setNeedsResetRotation(_:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        panoramaView.addGestureRecognizer(doubleTapGestureRecognizer)

        self.panoramaView = panoramaView

        panoramaView.load(#imageLiteral(resourceName: "Sample"), format: .stereoOverUnder)
    }

    private func loadStereoButton() {
        let button = UIButton(type: .system)
        button.setTitle("Stereo", for: .normal)
        button.addTarget(self, action: #selector(presentStereoView), for: .touchUpInside)
        button.contentHorizontalAlignment = .right
        button.contentVerticalAlignment = .bottom
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)

        // place to bottom-right corner
        let constraints: [NSLayoutConstraint] = [
            button.widthAnchor.constraint(equalToConstant: 96),
            button.heightAnchor.constraint(equalToConstant: 64),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loadPanoramaView()
        loadStereoButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        panoramaView?.isPlaying = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        panoramaView?.isPlaying = false
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        panoramaView?.updateInterfaceOrientation(with: coordinator)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func presentStereoView() {
        let introView = UILabel()
        introView.text = "Place your phone into your Cardboard viewer."
        introView.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        introView.textAlignment = .center
        introView.backgroundColor = #colorLiteral(red: 0.2745098039, green: 0.3529411765, blue: 0.3921568627, alpha: 1)

        let stereoViewController = StereoViewController(device: device)
        stereoViewController.introductionView = introView
        stereoViewController.scene = panoramaView?.scene
        present(stereoViewController, animated: true, completion: nil)
    }
}
