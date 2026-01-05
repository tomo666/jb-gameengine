//
//  Vector4.swift
//  JBGE_RealityKit
//
//  Created by Tomohiro Kadono on 2026/01/05.
//

import Foundation
import simd

public struct Vector4 {

    public var x: Float
    public var y: Float
    public var z: Float
    public var w: Float
    
    public init(_ x: Float, _ y: Float, _ z: Float, _ w: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    public static let zero = Vector4(0, 0, 0, 0)
    public static let one  = Vector4(1, 1, 1, 1)

    internal var simd: SIMD4<Float> {
        SIMD4<Float>(x, y, z, w)
    }

    internal init(simd: SIMD4<Float>) {
        self.x = simd.x
        self.y = simd.y
        self.z = simd.z
        self.w = simd.w
    }
}
