//
//  CategoryBitMask.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/20.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit

public struct CategoryBitMask: OptionSet {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

extension CategoryBitMask {
    public static let all = CategoryBitMask(rawValue: .max)
    public static let leftEye = CategoryBitMask(rawValue: 1 << 21)
    public static let rightEye = CategoryBitMask(rawValue: 1 << 22)
}
