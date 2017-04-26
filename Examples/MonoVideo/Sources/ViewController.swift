//
//  ViewController.swift
//  MonoVideo
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

    var player: AVPlayer?
    var playerLooper: Any? // AVPlayerLooper if available
    var playerObservingToken: Any?

    deinit {
        if let token = playerObservingToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

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

        // single tap to toggle play/pause
        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(togglePlaying))
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        panoramaView.addGestureRecognizer(singleTapGestureRecognizer)

        self.panoramaView = panoramaView
    }

    private func loadVideo() {
        let url = Bundle.main.url(forResource: "Sample", withExtension: "mp4")!
        let playerItem = AVPlayerItem(url: url)
        let player = AVQueuePlayer(playerItem: playerItem)

        panoramaView?.load(player, format: .mono)

        self.player = player

        // loop
        if #available(iOS 10, *) {
            playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        } else {
            player.actionAtItemEnd = .none
            playerObservingToken = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: nil) { _ in
                player.seek(to: kCMTimeZero, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            }
        }

        player.play()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loadPanoramaView()
        loadVideo()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

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
}
