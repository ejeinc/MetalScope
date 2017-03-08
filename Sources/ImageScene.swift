//
//  ImageScene.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/19.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit
import UIKit

public protocol ImageScene: class {
    var image: UIImage? { get set }
}

public final class MonoSphericalImageScene: MonoSphericalMediaScene, ImageScene {
    public var image: UIImage? {
        didSet {
            mediaSphereNode.mediaContents = image
        }
    }
}

public final class StereoSphericalImageScene: StereoSphericalMediaScene, ImageScene {
    public var image: UIImage? {
        didSet {
            var leftImage: UIImage?
            var rightImage: UIImage?

            if let image = image {
                let imageSize = CGSize(width: image.size.width, height: image.size.height / 2)

                UIGraphicsBeginImageContextWithOptions(imageSize, true, image.scale)
                image.draw(at: .zero)
                leftImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()

                UIGraphicsBeginImageContextWithOptions(imageSize, true, image.scale)
                image.draw(at: CGPoint(x: 0, y: -imageSize.height))
                rightImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }

            leftMediaSphereNode.mediaContents = leftImage?.cgImage
            rightMediaSphereNode.mediaContents = rightImage?.cgImage
        }
    }
}
