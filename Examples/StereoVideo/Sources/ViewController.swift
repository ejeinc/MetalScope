//
//  ViewController.swift
//  StereoVideo
//
//  Created by Jun Tanaka on 2017/02/06.
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

    var player: AVPlayer?

    private func loadPanoramaView() {
        let panoramaView = PanoramaView(frame: view.bounds, device: device)
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

        // double tap to reset center
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: panoramaView, action: #selector(PanoramaView.resetCenter))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        panoramaView.addGestureRecognizer(doubleTapGestureRecognizer)

        // single tap to toggle play/pause
        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(togglePlaying))
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        panoramaView.addGestureRecognizer(singleTapGestureRecognizer)

        self.panoramaView = panoramaView
    }

    private func loadVideo() {
        let url = Bundle.main.url(forResource: "Sample", withExtension: "mp4")!
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)

        panoramaView?.load(player, format: .stereoOverUnder)

        self.player = player

        // loop
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: nil) { _ in
            player.seek(to: kCMTimeZero, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            player.play()
        }
        player.play()
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
        loadVideo()
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

    func togglePlaying() {
        guard let player = player else {
            return
        }

        if player.rate == 0 {
            player.play()
        } else {
            player.pause()
        }
    }

    func presentStereoView() {
        let stereoViewController = StereoViewController(device: device)
        stereoViewController.scene = panoramaView?.scene
        stereoViewController.stereoView.tapGestureRecognizer.addTarget(self, action: #selector(togglePlaying))
        present(stereoViewController, animated: true, completion: nil)
    }
}
