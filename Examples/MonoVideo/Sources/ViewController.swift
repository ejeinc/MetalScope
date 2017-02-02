//
//  ViewController.swift
//  MonoSphericalVideo
//
//  Created by Jun Tanaka on 2017/01/20.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import UIKit
import Metal
import MetalScope
import AVFoundation

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

        NSLayoutConstraint.activate([
            panoramaView.topAnchor.constraint(equalTo: view.topAnchor),
            panoramaView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            panoramaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panoramaView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let tapGestureRecognizer = UITapGestureRecognizer(target: panoramaView, action: #selector(PanoramaView.resetCenter(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 2
        panoramaView.addGestureRecognizer(tapGestureRecognizer)

        do {
            let url = Bundle.main.url(forResource: "test", withExtension: "mp4")!
            let player = AVPlayer(url: url)
            try panoramaView.load(player, format: .mono)
            player.play()
        } catch {
            fatalError(error.localizedDescription)
        }

        self.panoramaView = panoramaView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loadPanoramaView()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        panoramaView?.updateInterfaceOrientation(with: coordinator)
    }
}
