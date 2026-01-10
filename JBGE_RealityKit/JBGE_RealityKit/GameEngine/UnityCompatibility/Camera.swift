//
//  Camera.swift
//  JBGE_RealityKit
//
//  Created by Tomohiro Kadono on 2026/01/06.
//

import RealityKit

public final class Camera: GameObject {
    // Unity-compatible flags
    public var orthographic: Bool = false {
        didSet { updateProjection() }
    }

    // Perspective parameters
    public var fieldOfView: Float = 60 {
        didSet { updateProjection() }
    }

    // Unity-compatible: Camera.orthographicSize (HALF height)
    public var orthoSize: Float = 55.0 {
        didSet {
            recalcOrthoMetrics()
            updateProjection()
        }
    }
    
    // Screen.width / Screen.height
    public var aspect: Float = 1.7777778 {
        didSet { recalcOrthoMetrics() }
    }
    
    // Unity-compatible pixel per unit
    public var pixelUnit: Float = 1.0 {
        didSet { recalcOrthoMetrics() }
    }

    // Derived orthographic screen size (FULL size, not half)
    public private(set) var orthoScreenWidth: Float = 0
    public private(set) var orthoScreenHeight: Float = 0
    
    private let uiBaseZ: Float = -1.0
    private let uiLayerStep: Float = -0.001

    // Unity-compatible position wrapper
    public var position: Vector3 = .zero {
        didSet {
            self.transform.translation = position.simd
        }
    }

    // Unity-compatible properties
    public var nearClipPlane: Float = 0.01
    public var farClipPlane: Float = 1000.0
    
    public enum ClearFlags {
        case skybox
        case color
        case depthOnly
        case nothing
    }
    public var clearFlags: ClearFlags = .depthOnly
    
    public var backgroundColor: Vector4 = Vector4(0, 0, 0, 1)
    
    public var targetDepth: Float = 0
    
    public var cullingMask: Int = ~0  // All layers by default
    
    public var lookAtTarget: Vector3?

    // MARK: - Initializers

    public override init(_ name: String = "Camera") {
        super.init(name)
        setupCameraComponent()
    }

    required public init() {
        super.init()
        setupCameraComponent()
    }
    
    var forward: SIMD3<Float> {
        let q = self.orientation
        return normalize(q.act(SIMD3<Float>(0, 0, -1)))
    }
    
    // MARK: - Camera setup

    private func recalcOrthoMetrics() {
        // Unity math: full size = orthographicSize * 2 * pixelUnit
        orthoScreenHeight = orthoSize * 2.0 * pixelUnit
        orthoScreenWidth  = orthoScreenHeight * aspect
        reapplyOrthoZOrdering()
    }

    private func setupCameraComponent() {
        var cam = PerspectiveCameraComponent()
        cam.fieldOfViewInDegrees = fieldOfView
        self.transform.translation = SIMD3(0, 0, 1.5)
        self.components.set(cam)
        recalcOrthoMetrics()
    }

    private func updateProjection() {
        if orthographic {
            var cam = OrthographicCameraComponent()
            cam.scale = orthoSize
            self.components.set(cam)
        } else {
            var cam = PerspectiveCameraComponent()
            cam.fieldOfViewInDegrees = fieldOfView
            self.components.set(cam)
        }
    }
    
    private func reapplyOrthoZOrdering() {
        let uiChildren = self.children
            .compactMap { $0 as? GameObject }
            .filter { $0.enabled }
            .sorted { $0.layer < $1.layer }

        for (index, go) in uiChildren.enumerated() {
            let z = uiBaseZ + Float(index) * uiLayerStep
            go.transform.position.z = z
        }
    }
    
    /*
    func Render() {
        if orthographic {
            reapplyOrthoZOrdering()
        }
        for child in self.children {
            guard let go = child as? GameObject else { continue }
            if !go.enabled { continue }
            if orthographic {
                applyOrthoTransform(go)
            } else {
                applyPerspectiveTransform(go)
            }
        }
    }*/
    
    /*
    func Render() {
        // If ortho mode do not render anything
        if orthographic { return }

        // If perspective mode
        for child in self.children {
            guard let go = child as? GameObject else { continue }
            if !go.enabled { continue }
            applyPerspectiveTransform(go)
        }
    }
    */
    /*
    func applyPerspectiveTransform(_ go: GameObject) {
        let p = go.transform.position   // viewport 0..1
        let z = max(0.0001, abs(p.z))
        let halfFov = fieldOfView * .pi / 360.0
        let scale = tan(halfFov) * z

        let worldX = (p.x - 0.5) * aspect * scale
        let worldY = (0.5 - p.y) * scale

        go.transform.position = Vector3(worldX, worldY, -z)
    }
    */
    /*
    func applyOrthoTransform(_ go: GameObject) {
        let p = go.transform.position   // viewport 0..1

        let worldX = (p.x - 0.5) * orthoScreenWidth
        let worldY = (0.5 - p.y) * orthoScreenHeight

        let currentZ = go.transform.position.z
        go.transform.position = Vector3(worldX, worldY, currentZ)
    }
    */
    // MARK: - Unity compatibility

    public func ViewportToWorldPoint(
        x: Float,
        y: Float,
        z: Float
    ) -> Vector3 {

        if orthographic {
            return Vector3(
                (x - 0.5) * orthoScreenWidth,
                (0.5 - y) * orthoScreenHeight,
                -z
            )
        } else {
            return Vector3(
                (x - 0.5) * 2.0,
                (y - 0.5) * 2.0,
                -z
            )
        }
    }
    
    // MARK: - Helpers
    
    public func lookAt(_ target: Vector3) {
        lookAtTarget = target
        // Implementation of lookAt logic would go here, e.g. adjust transform.rotation accordingly.
    }
    
    public var verticalFOV: Float {
        get { fieldOfView }
        set { fieldOfView = newValue }
    }
    
    public var horizontalFOV: Float {
        get {
            let vFovRad = fieldOfView * .pi / 180
            let hFovRad = 2 * atan(tan(vFovRad / 2) * aspect)
            return hFovRad * 180 / .pi
        }
        set {
            let hFovRad = newValue * .pi / 180
            let vFovRad = 2 * atan(tan(hFovRad / 2) / aspect)
            fieldOfView = vFovRad * 180 / .pi
        }
    }    
}
