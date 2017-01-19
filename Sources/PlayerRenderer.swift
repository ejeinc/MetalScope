//
//  PlayerRenderer.swift
//  Panoramic
//
//  Created by Jun Tanaka on 2017/01/17.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import Metal
import AVFoundation

public final class PlayerRenderer {
	private let currentItemObserver: KeyValueObserver

	public var player: AVPlayer? {
		willSet {
			player?.removeObserver(currentItemObserver, forKeyPath: "currentItem")
			itemRenderer.playerItem = nil
		}
		didSet {
			itemRenderer.playerItem = player?.currentItem
			player?.addObserver(currentItemObserver, forKeyPath: "currentItem", options: [.new], context: nil)
		}
	}

	public let itemRenderer: PlayerItemRenderer

	public init(itemRenderer: PlayerItemRenderer) {
		self.itemRenderer = itemRenderer

		currentItemObserver = KeyValueObserver { change in
			itemRenderer.playerItem = change?[.newKey] as? AVPlayerItem
		}
	}

	public convenience init(device: MTLDevice, outputSettings: [String: Any]? = nil) throws {
		let itemRenderer = try PlayerItemRenderer(device: device, outputSettings: outputSettings)
		self.init(itemRenderer: itemRenderer)
	}

	deinit {
		player = nil
	}

	public func render(atItemTime time: CMTime, to texture: MTLTexture, commandBuffer: MTLCommandBuffer) throws {
		try itemRenderer.render(atItemTime: time, to: texture, commandBuffer: commandBuffer)
	}

	public func render(atHostTime time: TimeInterval, to texture: MTLTexture, commandBuffer: MTLCommandBuffer) throws {
		try itemRenderer.render(atHostTime: time, to: texture, commandBuffer: commandBuffer)
	}
}

private extension PlayerRenderer {
	final class KeyValueObserver: NSObject {
		private let action: ([NSKeyValueChangeKey: Any]?) -> Void

		init(_ action: @escaping ([NSKeyValueChangeKey: Any]?) -> Void) {
			self.action = action
		}

		override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
			action(change)
		}
	}
}
