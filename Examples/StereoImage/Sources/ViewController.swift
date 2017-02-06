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
        panoramaView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panoramaView)

        let constraints: [NSLayoutConstraint] = [
            panoramaView.topAnchor.constraint(equalTo: view.topAnchor),
            panoramaView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            panoramaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panoramaView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        NSLayoutConstraint.activate(constraints)

        let tapGestureRecognizer = UITapGestureRecognizer(target: panoramaView, action: #selector(PanoramaView.resetCenter))
        tapGestureRecognizer.numberOfTapsRequired = 2
        panoramaView.addGestureRecognizer(tapGestureRecognizer)

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

    override func viewWillAppear(_ animated: Bool) {
        panoramaView?.isPlaying = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        panoramaView?.isPlaying = false
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        panoramaView?.updateInterfaceOrientation(with: coordinator)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func presentStereoView() {
        let stereoViewController = StereoViewController(device: device)
        stereoViewController.scene = panoramaView?.scene
        present(stereoViewController, animated: true, completion: nil)
    }
}
