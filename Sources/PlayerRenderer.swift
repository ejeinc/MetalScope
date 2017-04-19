//
//  PlayerRenderer.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/17.
//  Copyright © 2017 eje Inc. All rights reserved.
//

#if (arch(arm) || arch(arm64)) && os(iOS)

import Metal
import AVFoundation

public final class PlayerRenderer {
    private let currentItemObserver: KeyValueObserver

    public var player: AVPlayer? {
        willSet {
            if let player = player {
                unbind(player)
            }
        }
        didSet {
            if let player = player {
                bind(player)
            }
        }
    }

    public var device: MTLDevice {
        return itemRenderer.device
    }

    public let itemRenderer: PlayerItemRenderer

    public init(itemRenderer: PlayerItemRenderer) {
        self.itemRenderer = itemRenderer

        currentItemObserver = KeyValueObserver { change in
            itemRenderer.playerItem = change?[.newKey] as? AVPlayerItem
        }
    }

    public convenience init(device: MTLDevice) {
        let itemRenderer = PlayerItemRenderer(device: device)
        self.init(itemRenderer: itemRenderer)
    }

    public convenience init(device: MTLDevice, outputSettings: [String: Any]) throws {
        let itemRenderer = try PlayerItemRenderer(device: device, outputSettings: outputSettings)
        self.init(itemRenderer: itemRenderer)
    }

    deinit {
        if let player = player {
            unbind(player)
        }
    }

    private func bind(_ player: AVPlayer) {
        itemRenderer.playerItem = player.currentItem
        player.addObserver(currentItemObserver, forKeyPath: "currentItem", options: [.new], context: nil)
    }

    private func unbind(_ player: AVPlayer) {
        player.removeObserver(currentItemObserver, forKeyPath: "currentItem")
        itemRenderer.playerItem = nil
    }

    public func hasNewPixelBuffer(atItemTime time: CMTime) -> Bool {
        return itemRenderer.hasNewPixelBuffer(atItemTime: time)
    }

    public func render(atItemTime time: CMTime, to texture: MTLTexture, commandBuffer: MTLCommandBuffer) throws {
        try itemRenderer.render(atItemTime: time, to: texture, commandBuffer: commandBuffer)
    }

    public func hasNewPixelBuffer(atHostTime time: TimeInterval) -> Bool {
        return itemRenderer.hasNewPixelBuffer(atHostTime: time)
    }

    public func render(atHostTime time: TimeInterval, to texture: MTLTexture, commandBuffer: MTLCommandBuffer) throws {
        try itemRenderer.render(atHostTime: time, to: texture, commandBuffer: commandBuffer)
    }
}

#endif
