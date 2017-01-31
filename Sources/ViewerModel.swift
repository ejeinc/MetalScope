//
//  ViewerModel.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/23.
//  Copyright © 2017 eje Inc. All rights reserved.
//

public enum ViewerModel {
    case cardboardJun2014
    case cardboardMay2015
    case custom(parameters: ViewerParametersProtocol)

    public static let `default` = ViewerModel.cardboardMay2015
}

extension ViewerModel: ViewerParametersProtocol {
    private var parameters: ViewerParameters {
        switch self {
        case .cardboardJun2014:
            return ViewerParameters(
                lenses: Lenses(separation: 0.060, offset: 0.035, alignment: .bottom, screenDistance: 0.042),
                distortion: Distortion(k1: 0.441, k2: 0.156),
                maximumFieldOfView: FieldOfView(outer: 40.0, inner: 40.0, upper: 40.0, lower: 40.0)
            )
        case .cardboardMay2015:
            return ViewerParameters(
                lenses: Lenses(separation: 0.064, offset: 0.035, alignment: .bottom, screenDistance: 0.039),
                distortion: Distortion(k1: 0.34, k2: 0.55),
                maximumFieldOfView: FieldOfView(outer: 60.0, inner: 60.0, upper: 60.0, lower: 60.0)
            )
        case .custom(let parameters):
            return ViewerParameters(parameters)
        }
    }

    public var lenses: Lenses {
        return parameters.lenses
    }

    public var distortion: Distortion {
        return parameters.distortion
    }

    public var maximumFieldOfView: FieldOfView {
        return parameters.maximumFieldOfView
    }
}
