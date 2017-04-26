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
    var playerLooper: Any? // AVPlayerLopper if available
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

        panoramaView?.load(player, format: .stereoOverUnder)

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
        let introView = UILabel()
        introView.text = "Place your phone into your Cardboard viewer."
        introView.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        introView.textAlignment = .center
        introView.backgroundColor = #colorLiteral(red: 0.2745098039, green: 0.3529411765, blue: 0.3921568627, alpha: 1)

        let stereoViewController = StereoViewController(device: device)
        stereoViewController.introductionView = introView
        stereoViewController.scene = panoramaView?.scene
        stereoViewController.stereoView.tapGestureRecognizer.addTarget(self, action: #selector(togglePlaying))
        present(stereoViewController, animated: true, completion: nil)
    }
}
