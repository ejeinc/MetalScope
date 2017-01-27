//
//  StereoScene.swift
//  PanoramaView
//
//  Created by Jun Tanaka on 2017/01/23.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit

internal final class StereoScene: SCNScene {
    var stereoTexture: MTLTexture? {
        didSet {
            attachTextureToMesh()
        }
    }

    var stereoParameters: StereoParametersProtocol? {
        didSet {
            guard let parameters = stereoParameters else {
                return
            }
            updateMesh(with: parameters)
            attachTextureToMesh()
        }
    }

    lazy var pointOfView: SCNNode = {
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 0.5
        camera.zNear = 0

        let node = SCNNode()
        node.camera = camera
        self.rootNode.addChildNode(node)
        return node
    }()

    private lazy var meshNode: SCNNode = {
        let node = SCNNode()
        self.rootNode.addChildNode(node)
        return node
    }()

    private func attachTextureToMesh() {
        meshNode.geometry?.firstMaterial?.diffuse.contents = stereoTexture
    }

    private func updateMesh(with parameters: StereoParametersProtocol, cellSize: Int = 40) {
        let viewer = parameters.viewer
        let screen = parameters.screen

        var lensFrustum = parameters.leftEyeVisibleTanAngles
        var noLensFrustum = parameters.leftEyeNoLensVisibleTanAngles
        var viewport = parameters.leftEyeVisibleScreenRect

        let width = cellSize
        let height = cellSize
        let halfWidth = width / 2
        let halfHeight = height / 2

        let size = 2 * width * height

        var vertices = [SCNVector3](repeating: SCNVector3Zero, count: size)
        var texcoord = [float2](repeating: float2(), count: size)
        var colors = [SCNVector3](repeating: SCNVector3(1, 1, 1), count: size)
        var indices = [Int16](repeating: 0, count: 2 * (width - 1) * (height - 1) * 6)

        func lerpf(_ from: Float, _ to: Float, _ alpha: Float) -> Float {
            return from + alpha * (to - from)
        }

        var vid = 0
        var iid = 0

        for e in 0..<2 {
            for j in 0..<height {
                for i in 0..<width {
                    var u = Float(i) / Float(width - 1)
                    var v = Float(j) / Float(height - 1)
                    var s = u
                    var t = v

                    let x = lerpf(lensFrustum[0], lensFrustum[2], u)
                    let y = lerpf(lensFrustum[3], lensFrustum[1], v)
                    let d = sqrtf(x * x + y * y)
                    let r = viewer.distortion.distortInv(d)
                    let p = x * r / d
                    let q = y * r / d

                    u = (p - noLensFrustum[0]) / (noLensFrustum[2] - noLensFrustum[0])
                    v = (q - noLensFrustum[3]) / (noLensFrustum[1] - noLensFrustum[3])

                    u = (Float(viewport.origin.x) + u * Float(viewport.size.width) - 0.5) * screen.aspectRatio
                    v = Float(viewport.origin.y) + v * Float(viewport.size.height) - 0.5

                    vertices[vid] = SCNVector3(u, v, 0)

                    s = (s + Float(e)) / 2
                    t = 1.0 - t // flip vertically

                    texcoord[vid] = float2(s, t)

                    if i == 0 || j == 0 || i == (width - 1) || j == (height - 1) {
                        colors[vid] = SCNVector3Zero
                    }

                    if i == 0 || j == 0 {
                        // do nothing
                    } else if (i <= halfWidth) == (j <= halfHeight) {
                        indices[iid] = Int16(vid)
                        iid += 1
                        indices[iid] = Int16(vid - width)
                        iid += 1
                        indices[iid] = Int16(vid - width - 1)
                        iid += 1
                        indices[iid] = Int16(vid - width - 1)
                        iid += 1
                        indices[iid] = Int16(vid - 1)
                        iid += 1
                        indices[iid] = Int16(vid)
                        iid += 1
                    } else {
                        indices[iid] = Int16(vid - 1)
                        iid += 1
                        indices[iid] = Int16(vid)
                        iid += 1
                        indices[iid] = Int16(vid - width)
                        iid += 1
                        indices[iid] = Int16(vid - width)
                        iid += 1
                        indices[iid] = Int16(vid - width - 1)
                        iid += 1
                        indices[iid] = Int16(vid - 1)
                        iid += 1
                    }

                    vid += 1
                }
            }

            var w: Float
            w = lensFrustum[2] - lensFrustum[0]
            lensFrustum[0] = -(w + lensFrustum[0])
            lensFrustum[2] = w - lensFrustum[2]
            w = noLensFrustum[2] - noLensFrustum[0]
            noLensFrustum[0] = -(w + noLensFrustum[0])
            noLensFrustum[2] = w - noLensFrustum[2]

            viewport.origin.x = 1.0 - (viewport.origin.x + viewport.size.width)
        }

        let mesh = SCNGeometry(
            sources: [
                SCNGeometrySource(vertices: vertices, count: vertices.count),
                SCNGeometrySource(texcoord: texcoord),
                SCNGeometrySource(colors: colors)
            ],
            elements: [
                SCNGeometryElement(indices: indices, primitiveType: .triangles)
            ]
        )

        let material = SCNMaterial()
        material.isDoubleSided = true
        mesh.materials = [material]

        meshNode.geometry = mesh
    }
}

private extension SCNGeometrySource {
    convenience init(texcoord vectors: [float2]) {
        self.init(
            data: Data(bytes: vectors, count: vectors.count * MemoryLayout<float2>.size),
            semantic: .texcoord,
            vectorCount: vectors.count,
            usesFloatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<float2>.size
        )
    }

    convenience init(colors vectors: [SCNVector3]) {
        self.init(
            data: Data(bytes: vectors, count: vectors.count * MemoryLayout<SCNVector3>.size),
            semantic: .color,
            vectorCount: vectors.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SCNVector3>.size
        )
    }
}
