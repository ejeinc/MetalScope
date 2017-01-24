//
//  ViewController.swift
//  StereoSphericalPhoto
//
//  Created by Jun Tanaka on 2017/01/20.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import UIKit
import Metal
import PanoramaView

final class ViewController: UIViewController {
    lazy var device: MTLDevice = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Failed to create MTLDevice")
        }
        return device
    }()

    weak var panoramaView: PanoramaView?
    weak var cardboardButton: UIButton?

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

        panoramaView.loadPhoto(image: #imageLiteral(resourceName: "stereo"), format: .stereoOverUnder)
        
        self.panoramaView = panoramaView
    }

    private func loadCardboardButton() {
        let cardboardButton = UIButton(type: .system)
        cardboardButton.setImage(UIImage(named: "icon-cardboard", in: Bundle(for: PanoramaView.self), compatibleWith: nil), for: .normal)
        cardboardButton.addTarget(self, action: #selector(presentStereoView), for: .touchUpInside)
        cardboardButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardboardButton)

        NSLayoutConstraint.activate([
            cardboardButton.widthAnchor.constraint(equalToConstant: 64),
            cardboardButton.heightAnchor.constraint(equalToConstant: 64),
            cardboardButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cardboardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        self.cardboardButton = cardboardButton
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loadPanoramaView()
        loadCardboardButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        panoramaView?.isPlaying = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        panoramaView?.isPlaying = false
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        panoramaView?.updateInterfaceOrientation(with: coordinator)
    }

    func presentStereoView() {
        let stereoViewController = StereoViewController(device: device)
        stereoViewController.scene = panoramaView?.scene
        
        present(stereoViewController, animated: true) {
            stereoViewController.closeButton.addTarget(self, action: #selector(self.dismissStereoView), for: .touchUpInside)
        }
    }
    
    func dismissStereoView() {
        dismiss(animated: true, completion: nil)
    }
}
