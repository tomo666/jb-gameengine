//
//  GameObject.swift
//  JBGE_RealityKit
//
//  Created by Tomohiro Kadono on 2026/01/04.
//

import RealityKit
import simd

open class GameObject : Entity {
    public var enabled: Bool = true {
        didSet { self.isEnabled = enabled }
    }
    
    public var layer: Int = 0

    // Unity互換: RectTransform.sizeDelta 相当
    // UI用途の論理サイズ（ワールドスケールとは独立）
    public var localSize: Vector2 = Vector2(0, 0)

    // Unity互換Transform
    public lazy var transform: Transform = Transform(owner: self)

    public init(_ name: String) {
        super.init()
        // Keep GameObject's own name in sync with the internal entity for debugging/identification
        self.name = name
    }

    required public init() {
        super.init()
    }

    /// Unity互換: 親からこのオブジェクトを削除する
    public func Destroy() {
        self.removeFromParent()
    }

    /// Unity互換: 他のGameObjectのlocalSizeをコピーする
    /// 主に Controller → ThisObject へのサイズ同期用途
    public func SetSizeFrom(_ other: GameObject) {
        self.localSize = other.localSize
    }
}
