//
//  ViewController.swift
//  StereoSphericalPhoto
//
//  Created by Jun Tanaka on 2017/01/20.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import UIKit
import Metal
import Axel

final class ViewController: UIViewController {
	weak var panoramaView: PanoramaView?

	override func viewDidLoad() {
		super.viewDidLoad()

		guard let device = MTLCreateSystemDefaultDevice() else {
			fatalError("Failed to create MTLDevice")
		}

		let panoramaView = PanoramaView(frame: view.bounds, device: device)
		view.addSubview(panoramaView)

		let tapGestureRecognizer = UITapGestureRecognizer(target: panoramaView, action: #selector(PanoramaView.resetCenter(_:)))
		tapGestureRecognizer.numberOfTapsRequired = 2
		panoramaView.addGestureRecognizer(tapGestureRecognizer)

		self.panoramaView = panoramaView

		panoramaView.loadPhoto(image: #imageLiteral(resourceName: "stereo"), format: .stereoOverUnder)
	}

	override func viewDidLayoutSubviews() {
		panoramaView?.frame = view.bounds
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		panoramaView?.updateInterfaceOrientation(with: coordinator)
	}
}
