//
//  InterfaceOrientationProvider.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/17.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import UIKit

public protocol InterfaceOrientationProvider {
    func interfaceOrientation(atTime time: TimeInterval) -> UIInterfaceOrientation
}

extension UIInterfaceOrientation: InterfaceOrientationProvider {
    public func interfaceOrientation(atTime time: TimeInterval) -> UIInterfaceOrientation {
        return self
    }
}

extension UIApplication: InterfaceOrientationProvider {
    public func interfaceOrientation(atTime time: TimeInterval) -> UIInterfaceOrientation {
        return statusBarOrientation.interfaceOrientation(atTime: time)
    }
}

internal final class DefaultInterfaceOrientationProvider: InterfaceOrientationProvider {
    func interfaceOrientation(atTime time: TimeInterval) -> UIInterfaceOrientation {
        return UIApplication.shared.interfaceOrientation(atTime: time)
    }
}
