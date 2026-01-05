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

    // Pseudo-orthographic size (used when orthographic == true)
    public var orthoSize: Float = 1.0 {
        didSet { updateProjection() }
    }

    // Unity-compatible position wrapper
    public var position: Vector3 = .zero {
        didSet {
            self.transform.translation = position.simd
        }
    }

    // MARK: - Initializers

    public override init(_ name: String = "Camera") {
        super.init(name)
        setupCameraComponent()
    }

    required public init() {
        super.init()
        setupCameraComponent()
    }

    // MARK: - Camera setup

    private func setupCameraComponent() {
        var cam = PerspectiveCameraComponent()
        cam.fieldOfViewInDegrees = fieldOfView
        self.components.set(cam)
    }

    private func updateProjection() {
        // RealityKit does not support true orthographic cameras,
        // so orthographic is implemented as a pseudo-projection.
        var cam = PerspectiveCameraComponent()
        if orthographic {
            // Extremely small FOV to approximate ortho
            cam.fieldOfViewInDegrees = 1.0
        } else {
            cam.fieldOfViewInDegrees = fieldOfView
        }
        self.components.set(cam)
    }

    // MARK: - Unity compatibility

    public func ViewportToWorldPoint(
        x: Float,
        y: Float,
        z: Float
    ) -> Vector3 {

        if orthographic {
            return Vector3(
                (x - 0.5) * orthoSize,
                (y - 0.5) * orthoSize,
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
}
