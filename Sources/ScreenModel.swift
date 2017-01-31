//
//  ScreenModel.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/23.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import UIKit

public enum ScreenModel {
    case iPhone4
    case iPhone5
    case iPhone6
    case iPhone6Plus
    case custom(parameters: ScreenParametersProtocol)

    public static let iPhone4S = ScreenModel.iPhone4
    public static let iPhone5s = ScreenModel.iPhone5
    public static let iPhone5c = ScreenModel.iPhone5
    public static let iPhoneSE = ScreenModel.iPhone5
    public static let iPhone6s = ScreenModel.iPhone6
    public static let iPhone6sPlus = ScreenModel.iPhone6Plus
    public static let iPhone7 = ScreenModel.iPhone6
    public static let iPhone7Plus = ScreenModel.iPhone6Plus
    public static let iPodTouch = ScreenModel.iPhone5

    public static var `default`: ScreenModel {
        return ScreenModel.current ?? .iPhone5
    }

    public static var current: ScreenModel? {
        return ScreenModel(modelIdentifier: currentModelIdentifier) ?? ScreenModel(screen: .main)
    }

    private static var currentModelIdentifier: String {
        var size: size_t = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine: [CChar] = Array(repeating: 0, count: Int(size))
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }

    private init?(modelIdentifier identifier: String) {
        func match(_ identifier: String, _ prefixes: [String]) -> Bool {
            return prefixes.filter({ identifier.hasPrefix($0) }).count > 0
        }

        if match(identifier, ["iPhone3"]) {
            self = .iPhone4
        } else if match(identifier, ["iPhone4"]) {
            self = .iPhone4S
        } else if match(identifier, ["iPhone5"]) {
            self = .iPhone5
        } else if match(identifier, ["iPhone6"]) {
            self = .iPhone5s
        } else if match(identifier, ["iPhone8,4"]) {
            self = .iPhoneSE
        } else if match(identifier, ["iPhone7,2"]) {
            self = .iPhone6
        } else if match(identifier, ["iPhone8,1"]) {
            self = .iPhone6s
        } else if match(identifier, ["iPhone9,1", "iPhone9,3"]) {
            self = .iPhone7
        } else if match(identifier, ["iPhone7,1"]) {
            self = .iPhone6Plus
        } else if match(identifier, ["iPhone8,2"]) {
            self = .iPhone6sPlus
        } else if match(identifier, ["iPhone9,2", "iPhone9,4"]) {
            self = .iPhone7Plus
        } else if match(identifier, ["iPod7,1"]) {
            self = .iPodTouch
        } else {
            return nil
        }
    }

    private init?(screen: UIScreen) {
        switch screen.fixedCoordinateSpace.bounds.size {
        case CGSize(width: 320, height: 480):
            self = .iPhone4
        case CGSize(width: 320, height: 568):
            self = .iPhone5
        case CGSize(width: 375, height: 667):
            self = .iPhone6
        case CGSize(width: 414, height: 768):
            self = .iPhone6Plus
        default:
            return nil
        }
    }
}

extension ScreenModel: ScreenParametersProtocol {
    private var parameters: ScreenParameters {
        switch self {
        case .iPhone4:
            return ScreenParameters(width: 0.075, height: 0.050, border: 0.0045)
        case .iPhone5:
            return ScreenParameters(width: 0.089, height: 0.050, border: 0.0045)
        case .iPhone6:
            return ScreenParameters(width: 0.104, height: 0.058, border: 0.005)
        case .iPhone6Plus:
            return ScreenParameters(width: 0.112, height: 0.068, border: 0.005)
        case .custom(let parameters):
            return ScreenParameters(parameters)
        }
    }

    public var width: Float {
        return parameters.width
    }

    public var height: Float {
        return parameters.height
    }

    public var border: Float {
        return parameters.border
    }
}
