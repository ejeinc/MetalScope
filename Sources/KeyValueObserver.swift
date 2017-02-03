//
//  KeyValueObserver.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/02/03.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import Foundation

internal final class KeyValueObserver: NSObject {
    private let action: ([NSKeyValueChangeKey: Any]?) -> Void

    init(_ action: @escaping ([NSKeyValueChangeKey: Any]?) -> Void) {
        self.action = action
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        action(change)
    }
}
