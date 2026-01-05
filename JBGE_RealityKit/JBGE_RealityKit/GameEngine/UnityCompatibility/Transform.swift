//
//  Transform.swift
//  JBGE_RealityKit
//
//  Created by Tomohiro Kadono on 2026/01/04.
//

import RealityKit
import simd

public final class Transform {
    private unowned let owner: GameObject

    internal init(owner: GameObject) {
        self.owner = owner
    }

    public func SetParent(_ parent: Transform?) {
        if let parent {
            owner.setParent(parent.owner)
        } else {
            owner.setParent(nil)
        }
    }

    public func SetPosition(_ x: Float, _ y: Float, _ z: Float, ppu: Float) {
        // Unity-compatible: treat SetPosition as localPosition in UI/2D context
        self.localPosition = Vector3(x / ppu, y / ppu, z / ppu)
    }

    public func SetScale(_ x: Float, _ y: Float, _ z: Float) {
        self.localScale = Vector3(x, y, z)
    }

    public func SetRotation(_ x: Float, _ y: Float, _ z: Float) {
        SetLocalRotation(x, y, z)
    }
    
    public var localPosition: Vector3 {
        get {
            let p = owner.position
            return Vector3(p.x, p.y, p.z)
        }
        set {
            owner.position = newValue.simd
        }
    }
    
    public var localScale: Vector3 {
        get {
            let s = owner.scale
            return Vector3(s.x, s.y, s.z)
        }
        set {
            owner.scale = newValue.simd
        }
    }
    
    public var localRotation: simd_quatf {
        get {
            owner.orientation
        }
        set {
            owner.orientation = newValue
        }
    }
    
    public func SetLocalRotation(_ x: Float, _ y: Float, _ z: Float) {
        let radians = Vector3(
            x * .pi / 180,
            y * .pi / 180,
            z * .pi / 180
        )

        let qx = simd_quatf(angle: radians.x, axis: SIMD3(1, 0, 0))
        let qy = simd_quatf(angle: radians.y, axis: SIMD3(0, 1, 0))
        let qz = simd_quatf(angle: radians.z, axis: SIMD3(0, 0, 1))

        owner.orientation = qz * qx * qy
    }
}
