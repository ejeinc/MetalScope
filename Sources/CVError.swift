//
//  CVError.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2016/12/13.
//  Copyright © 2016 eje Inc. All rights reserved.
//

import CoreVideo

public enum CVError: Int32, Error {
    // Common
    case error = -6660
    case invalidArgument = -6661
    case allocationFailed = -6662
    case unsupported = -6663

    // CVDisplayLink
    case invalidDisplay = -6670
    case displayLinkAlreadyRunning = -6671
    case displayLinkNotRunning = -6672
    case displayLinkCallbacksNotSet = -6673

    // CVPixelBuffer
    case invalidPixelFormat = -6680
    case invalidSize = -6681
    case invalidPixelBufferAttributes = -6682
    case pixelBufferNotOpenGLCompatible = -6683
    case pixelBufferNotMetalCompatible = -6684

    // CVPixelBufferPool
    case wouldExceedAllocationThreshold = -6689
    case poolAllocationFailed = -6690
    case invalidPoolAttributes = -6691
    case retry = -6692
}

extension CVError {
    public init(code: CVReturn) {
        if let error = CVError(rawValue: code) {
            self = error
        } else if code == kCVReturnSuccess {
            fatalError("Passed kCVReturnSuccess to CVError(code:).")
        } else {
            fatalError("Passed unknown CVReturn value to CVError(code:).")
        }
    }

    public var code: CVReturn {
        return rawValue
    }
}

extension CVError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .error:
            return "An otherwise undefined error occurred."
        case .invalidArgument:
            return "Invalid function parameter. For example, out of range or the wrong type."
        case .allocationFailed:
            return "Memory allocation for a buffer or buffer pool failed."
        case .unsupported:
            return "Unsupported."

        case .invalidDisplay:
            return "The display specified when creating a display link is invalid."
        case .displayLinkAlreadyRunning:
            return "The specified display link is already running."
        case .displayLinkNotRunning:
            return "The specified display link is not running."
        case .displayLinkCallbacksNotSet:
            return "No callback registered for the specified display link. You must set either the output callback or both the render and display callbacks."

        case .invalidPixelFormat:
            return "The buffer does not support the specified pixel format."
        case .invalidSize:
            return "The buffer cannot support the requested buffer size (usually too big)."
        case .invalidPixelBufferAttributes:
            return "A buffer cannot be created with the specified attributes."
        case .pixelBufferNotOpenGLCompatible:
            return "The pixel buffer is not compatible with OpenGL due to an unsupported buffer size, pixel format, or attribute."
        case .pixelBufferNotMetalCompatible:
            return "The pixel buffer is not compatible with Metal due to an unsupported buffer size, pixel format, or attribute."

        case .wouldExceedAllocationThreshold:
            return "Allocation for a pixel buffer failed because the threshold value set for the `kCVPixelBufferPoolAllocationThresholdKey` key in the `CVPixelBufferPoolCreatePixelBufferWithAuxAttributes` function would be surpassed."
        case .poolAllocationFailed:
            return "Allocation for a buffer pool failed, most likely due to a lack of resources. Check to make sure your parameters are in range."
        case .invalidPoolAttributes:
            return "A buffer pool cannot be created with the specified attributes."
        case .retry:
            return "A scan hasn't completely traversed the CVBufferPool due to a concurrent operation."
        }
    }
}

extension CVError: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "CVError(code: \(code), description: \"\(description)\")"
    }
}
