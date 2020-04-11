//
//  PlayerRenderLoop.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/02/03.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import QuartzCore

public final class RenderLoop {
    public let queue: DispatchQueue

    public var isPaused: Bool {
        return displayLink.isPaused
    }

    private let action: (TimeInterval) -> Void

    private lazy var displayLink: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        link.add(to: .main, forMode: .common)
        link.isPaused = true
        return link
    }()

    public init(queue: DispatchQueue = DispatchQueue(label: "com.eje-c.MetalScope.RenderLoop.queue"), action: @escaping (_ targetTime: TimeInterval) -> Void) {
        self.queue = queue
        self.action = action
    }

    public func pause() {
        displayLink.isPaused = true
    }

    public func resume() {
        displayLink.isPaused = false
    }

    @objc private func handleDisplayLink(_ sender: CADisplayLink) {
        let time: TimeInterval
        if #available(iOS 10, *) {
            time = sender.targetTimestamp
        } else {
            time = sender.timestamp + sender.duration
        }
        queue.async { [weak self] in
            self?.action(time)
        }
    }
}
