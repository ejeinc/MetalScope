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
    
    typealias SeekOperationBlock = () -> Void
    
    fileprivate var timeObserverToken: Any?
    fileprivate var isSeeking: Bool = false
    
    lazy var device: MTLDevice = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Failed to create MTLDevice")
        }
        return device
    }()

    weak var panoramaView: PanoramaView?
    fileprivate var slider: UISlider!
    
    var player: AVPlayer?
    var playerLooper: Any? // AVPlayerLooper if available
    var playerObservingToken: Any?

    deinit {
        if let token = playerObservingToken {
            NotificationCenter.default.removeObserver(token)
        }
        
       removePeriodicTimeObserver()
    }

    private func loadPanoramaView() {
        let panoramaView = PanoramaView(frame: view.bounds, device: device)
        panoramaView.setNeedsResetRotation()
        panoramaView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panoramaView)
        
        slider = UISlider(frame: CGRect(x: 30, y: view.bounds.height - 60, width: view.bounds.width - 60, height: 30))
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.isContinuous = true
        slider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(slider)

        // fill parent view
        let constraints: [NSLayoutConstraint] = [
            panoramaView.topAnchor.constraint(equalTo: view.topAnchor),
            panoramaView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            panoramaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panoramaView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            slider.heightAnchor.constraint(equalToConstant: 30.0),
            slider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ]
        NSLayoutConstraint.activate(constraints)

        // double tap to reset rotation
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(resetRotation))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        panoramaView.addGestureRecognizer(doubleTapGestureRecognizer)

        // single tap to toggle play/pause
        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(togglePlaying))
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        panoramaView.addGestureRecognizer(singleTapGestureRecognizer)
        
        slider.addTarget(self, action: #selector(seekVideo), for: .valueChanged)

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
                player.seek(to: CMTime.zero, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            }
        }
        
        addPeriodicTimeObserver()
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

    @objc func togglePlaying() {
        guard let player = player else {
            return
        }

        if player.rate == 0 {
            player.play()
        } else {
            player.pause()
        }
    }
    
    @objc func resetRotation() {
        panoramaView?.setNeedsResetRotation()
    }
    
    @objc func seekVideo(_ slider: UISlider) {
        guard !isSeeking else { return }
        guard let videoDuration = self.player?.currentItem?.duration else {
            return
        }
        isSeeking = true
        removePeriodicTimeObserver()
        let tolerance = CMTime.zero
        let time = CMTime(seconds: videoDuration.seconds * Double(slider.value), preferredTimescale: videoDuration.timescale)
        player?.seek(to: time, toleranceBefore: tolerance, toleranceAfter: tolerance, completionHandler: { [weak self] (finished) in
            self?.addPeriodicTimeObserver()
            self?.isSeeking = false
            print("seek result: \(finished)")
        })
    }
}

fileprivate extension ViewController {
    
    func addPeriodicTimeObserver() {
        // Invoke callback every half second
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        // Queue on which to invoke the callback
        let mainQueue = DispatchQueue.main
        // Add time observer
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue) { [weak self] time in
            self?.updateSlider()
        }
    }
    
    func removePeriodicTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
    func updateSlider() {
        guard let videoDuration = self.player?.currentItem?.duration.seconds else {
            return
        }
        
        let currentPlayOffset = self.player!.currentTime().seconds
        slider.value = Float(currentPlayOffset / videoDuration)
    }
}
