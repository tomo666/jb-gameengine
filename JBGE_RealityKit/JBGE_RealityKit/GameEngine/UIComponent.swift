//
//  UIComponent.swift
//  JBGE_RealityKit
//
//  Created by Tomohiro Kadono on 2026/01/04.
//

import Foundation
import RealityKit
internal import AppKit

open class UIComponent {
    // NOTE: RealityKit's effective viewport height does not match the theoretical
    // perspective frustum due to SwiftUI + RealityView layout and safe margins.
    // This value was empirically calibrated to match full visible screen height
    // across common resolutions (640x480 .. 1920x1080).
    public let UIWorldUnitPerLogicalUnit: Float = 0.866

    public var ID: Int = Int.random(in: 0..<Int.max)
    public unowned let GE: GameEngine

    public lazy var ThisObject: GameObject = GameObject("")
    public var Controller: GameObject?
    public var SortOrder: Int = 0 // Sort order of this layer

    /// <summary>The scaled width of the UICamera's viewport width</summary>
    public var ScaleScreenWidth: Float = 0.0
    /// <summary>The scaled height of the UICamera's viewport height</summary>
    public var ScaleScreenHeight: Float = 0.0

    public var BaseScale: Vector3 = Vector3(1, 1, 1)
    public var Position: Vector3 = Vector3(0.5, 0.5, 0)
    public var Scale: Vector3 = Vector3(1, 1, 1)
    public var Rotation: Vector3 = Vector3(0, 0, 0) // degrees
    public var PositionPivot: Vector2 = Vector2(0.5, 0.5)
    public var ScalePivot: Vector2 = Vector2(0.5, 0.5)
    public var RotationPivot: Vector2 = Vector2(0.5, 0.5)
    
    public var IsVisible: Bool {
        get { ThisObject.isEnabled }
        set { ThisObject.isEnabled = newValue }
    }
    // Stores the accumulated frame count of this object (based on the game's main FPS)
    public var Frames: Int = 0
    // The maximum frame count that this object will accumulate
    // (Once the frame count reaches this max value, frame count will reset to 0)
    public var MaxFrames: Int = 0
    
    public init(
        _ GE: GameEngine,
        _ objectName: String? = nil,
        _ parentObj: UIComponent? = nil,
        _ isControllerRequired: Bool = true,
        _ isCreatePlaneForThisObject: Bool = false
    ) {
        self.GE = GE
        let name = objectName ?? String("UIComponent")
        self.ID = Int.random(in: 0..<Int.max)

        // --- Unity-compatible UI camera viewport sizing ---
        // Matches Unity: orthographicSize * 2 = viewport height in world units
        let pixelUnit: Float = 1.0
        
        // Full viewport size in world units
        ScaleScreenHeight = GE.UICamera.orthoSize * pixelUnit
        ScaleScreenWidth = ScaleScreenHeight * GE.UICamera.aspect
        
        // Create an empty UIPlane and set it in the hierarchy, if told to do so
        if isCreatePlaneForThisObject {
            self.ThisObject = CreateUIPlane(name, Vector4(Float.random(in: 0..<1), Float.random(in: 0..<1), Float.random(in: 0..<1), 0.7))
        } else {
            // Otherwise, just create an empty GameObject
            self.ThisObject = GameObject(name)
            self.ThisObject.layer = 5
        }

        if isControllerRequired {
            // Create a container to encapsulate this object so we can control the pivots
            let controller = GameObject("UIComponentController")
            self.Controller = controller

            // If we don't have any parent object specified, then this container will be directly the child of the UICamera
            controller.transform.SetParent(parentObj == nil ? GE.MainGameObject.transform : parentObj?.ThisObject.transform)
            ThisObject.transform.SetParent(controller.transform)

            // Unity: Controller positioned at center of viewport
            controller.transform.localPosition = Vector3(0, 0, 0)

            // Controller logical size equals viewport size
            controller.localSize = Vector2(ScaleScreenWidth, ScaleScreenHeight)
        } else {
            // If we don't have any parent object specified, then this container will be directly the child of the UICamera
            ThisObject.transform.SetParent(parentObj?.ThisObject.transform)
        }

        // Unity: UI element defaults to full viewport size
        ThisObject.localSize = Vector2(ScaleScreenWidth, ScaleScreenHeight)
    }

    open func Update() {
        Frames = GE.FrameCount % GE.TargetFrameRate
        if Frames >= MaxFrames {
            Frames = 0
        }
    }
    
    /// Unity-like reset (local).
    public func ResetTransform() {
        let target = (Controller ?? ThisObject)
        target.transform.localPosition = Vector3(0, 0, 0)
        target.transform.SetLocalRotation(0, 0, 0)
        target.transform.localScale = Vector3(1, 1, 1)
    }

    
    public func SetName(_ name: String) {
        let go = Controller ?? ThisObject
        go.name = name
    }

    public func GetName() -> String {
        let go = Controller ?? ThisObject
        return go.name
    }

    /// <summary>
    /// Unity-compatible destroy.
    /// Detaches and releases RealityKit entities.
    /// </summary>
    open func Destroy() {
        // Destroy child first (Unity-style safety)
        if let controller = Controller {
            controller.transform.SetParent(nil)
            controller.Destroy()
            Controller = nil
        }

        ThisObject.transform.SetParent(nil)
        ThisObject.Destroy()
        // Note: RealityKit entities are released automatically when no longer referenced
    }
    
    /// <summary>
    /// Unity-compatible UI plane factory (RealityKit implementation).
    /// </summary>
    open func CreateUIPlane(
        _ objectName: String,
        _ bgColor: Vector4? = Vector4.one
    ) -> GameObject {
        let go = GameObject(objectName)
        
        // NOTE:
        // RealityKit's effective viewport height does not match the theoretical
        // perspective frustum due to SwiftUI + RealityView layout and safe margins.
        // This value was empirically calibrated to match full visible screen height
        // across common resolutions (640x480 .. 1920x1080).
        let height = UIWorldUnitPerLogicalUnit
        let width  = height * GE.UICamera.aspect
        
        let vertices: [SIMD3<Float>] = [
            SIMD3(-width, -height, 0),
            SIMD3( width, -height, 0),
            SIMD3( width,  height, 0),
            SIMD3(-width,  height, 0)
        ]

        let indices: [UInt32] = [
            0, 1, 2,
            0, 2, 3
        ]

        var meshDesc = MeshDescriptor()
        meshDesc.positions = MeshBuffer(vertices)
        meshDesc.primitives = .triangles(indices)

        let mesh = try! MeshResource.generate(from: [meshDesc])
        
        // --- Material (simple unlit color, Unity placeholder equivalent) ---
        var material = UnlitMaterial()
        if let c = bgColor {
            material.color = .init(tint: .init(red: CGFloat(c.x), green: CGFloat(c.y), blue: CGFloat(c.z), alpha: 1.0))
        }

        let model = ModelEntity(mesh: mesh, materials: [material])
        model.name = "\(objectName)_Model"
        
        // Apply alpha if set
        model.components.set(OpacityComponent(opacity: Float(bgColor?.w ?? 1.0)))

        // Attach model under GameObject’s entity
        model.transform = .identity
        go.addChild(model)

        // --- Debug outline (UI frame) ---
        
        // lineStrip は RealityKit の MeshDescriptor では使えないので、4本の細い板ポリで枠を作る
        let borderZ: Float = 0.001
        let thickness: Float = 0.02  // 好きに調整。大きすぎるとUIに被る

        let halfW = width
        let halfH = height
        let t = thickness

        // 外側矩形 (outer) と 内側矩形 (inner)
        let outerL = -halfW
        let outerR =  halfW
        let outerB = -halfH
        let outerT =  halfH

        let innerL = outerL + t
        let innerR = outerR - t
        let innerB = outerB + t
        let innerT = outerT - t

        // 4本の枠ポリ: Top, Bottom, Left, Right をそれぞれ quad (2 triangles) で作る
        // 各quadは (a,b,c,d) の4頂点で、trianglesは (0,1,2) (0,2,3)
        func addQuad(_ verts: inout [SIMD3<Float>],
                     _ indices: inout [UInt32],
                     _ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>, _ d: SIMD3<Float>) {
            let base = UInt32(verts.count)
            verts.append(contentsOf: [a,b,c,d])
            indices.append(contentsOf: [
                base + 0, base + 1, base + 2,
                base + 0, base + 2, base + 3
            ])
        }

        var borderVerts: [SIMD3<Float>] = []
        var borderIndices: [UInt32] = []

        // Top strip
        addQuad(&borderVerts, &borderIndices,
                SIMD3(outerL, innerT, borderZ),
                SIMD3(outerR, innerT, borderZ),
                SIMD3(outerR, outerT, borderZ),
                SIMD3(outerL, outerT, borderZ))

        // Bottom strip
        addQuad(&borderVerts, &borderIndices,
                SIMD3(outerL, outerB, borderZ),
                SIMD3(outerR, outerB, borderZ),
                SIMD3(outerR, innerB, borderZ),
                SIMD3(outerL, innerB, borderZ))

        // Left strip
        addQuad(&borderVerts, &borderIndices,
                SIMD3(outerL, innerB, borderZ),
                SIMD3(innerL, innerB, borderZ),
                SIMD3(innerL, innerT, borderZ),
                SIMD3(outerL, innerT, borderZ))

        // Right strip
        addQuad(&borderVerts, &borderIndices,
                SIMD3(innerR, innerB, borderZ),
                SIMD3(outerR, innerB, borderZ),
                SIMD3(outerR, innerT, borderZ),
                SIMD3(innerR, innerT, borderZ))

        var borderDesc = MeshDescriptor()
        borderDesc.positions = MeshBuffer(borderVerts)
        borderDesc.primitives = .triangles(borderIndices)

        let borderMesh = try! MeshResource.generate(from: [borderDesc])

        var borderMaterial = UnlitMaterial()
        borderMaterial.color = .init(tint: .white)

        let borderEntity = ModelEntity(mesh: borderMesh, materials: [borderMaterial])
        borderEntity.name = "\(objectName)_Border"
         go.addChild(borderEntity)
        // ----- Debug end -----

        // Unity RectTransform equivalent defaults
        go.localSize = Vector2(width * 2, height * 2)

        return go
    }
    
    public func TransformAll(_ baseScale: Vector3, _ position: Vector3, _ scale: Vector3, _ rotation: Vector3, _ positionPivot: Vector2, _ scalePivot: Vector2, _ rotationPivot: Vector2) {
        
        // Reset all transformations first
        ResetTransform()

        let aspectRatioY: Float = UIWorldUnitPerLogicalUnit;
        let aspectRatioX: Float = UIWorldUnitPerLogicalUnit * GE.UICamera.aspect
        
        // Scale to the actual size first (at its center)
        let baseScaleX = baseScale.x //Image.Width / screenWidth;
        let baseScaleY = baseScale.y //Image.Height / screenHeight;
        let baseScaleZ = baseScale.z
        ThisObject.scale = SIMD3(baseScaleX, baseScaleY, baseScaleZ)
        
        // Then, whilst at its center position, move to the desired position
        let offsetX: Float = (position.x * (aspectRatioX * 2) - aspectRatioX) + (aspectRatioX - positionPivot.x * (aspectRatioX * 2)) * baseScaleX;
        let offsetY: Float = (aspectRatioY - position.y * (aspectRatioY * 2)) + (positionPivot.y * (aspectRatioY * 2) - aspectRatioY) * baseScaleY;
        let offsetZ: Float = position.z * baseScaleZ;
        
        ThisObject.position = SIMD3(offsetX, offsetY, offsetZ)

        // Actual size (world units) after baseScale applied
        let baseW = aspectRatioX * baseScale.x * 2
        let baseH = aspectRatioY * baseScale.y * 2

        let deltaW = baseW * (scale.x - 1)
        let deltaH = baseH * (scale.y - 1)

        // pivot 0..1 (where top-left is origin: 0,0)
        let pivotOffsetX = -deltaW * (scalePivot.x - 0.5)
        let pivotOffsetY =  deltaH * (scalePivot.y - 0.5)

        // Apply desired scale
        ThisObject.scale *= SIMD3(scale.x, scale.y, scale.z)
        // Fix difference amount after scaling
        ThisObject.position += SIMD3(
            pivotOffsetX,
            pivotOffsetY,
            0
        )
        
        // Rotation
        // Calculate final size (after scale)
        let finalW = baseW * scale.x
        let finalH = baseH * scale.y
        // Create rotation pivot inside local space
        let pivotLocal = SIMD3<Float>(
            (rotationPivot.x - 0.5) * finalW,
            (0.5 - rotationPivot.y) * finalH,
            0
        )
        // Create quaternion
        let rx = rotation.x * .pi / 180
        let ry = rotation.y * .pi / 180
        let rz = rotation.z * .pi / 180
        let q =
            simd_quatf(angle: ry, axis: SIMD3(0,1,0)) *
            simd_quatf(angle: rx, axis: SIMD3(1,0,0)) *
            simd_quatf(angle: rz, axis: SIMD3(0,0,1))
        // Fix difference amount after rotation
        let rotatedPivot = q.act(pivotLocal)
        let delta = rotatedPivot - pivotLocal
        // Apply rotation
        ThisObject.transform.rotation = q
        ThisObject.position -= delta
    }
    
    public func TransformPosition(_ position: Vector3, _ pivot: Vector2? = nil) {
        Position = position;
        PositionPivot = pivot ?? PositionPivot;
        TransformAll(BaseScale, Position, Scale, Rotation, PositionPivot, ScalePivot, RotationPivot);
    }

    public func TransformScale(_ scale: Vector3, _ pivot: Vector2? = nil) {
        Scale = scale;
        ScalePivot = pivot ?? ScalePivot;
        TransformAll(BaseScale, Position, Scale, Rotation, PositionPivot, ScalePivot, RotationPivot);
    }

    public func TransformRotation(_ rotation: Vector3, _ pivot: Vector2? = nil) {
        Rotation = rotation;
        RotationPivot = pivot ?? RotationPivot;
        TransformAll(BaseScale, Position, Scale, Rotation, PositionPivot, ScalePivot, RotationPivot);
    }
}


/*
 // --- Motion Tweening State ---
 public enum TargetProperty: Int {
     case Position = 0
     case Rotation = 1
     case Scale = 2
 }
 private var motionTweenWaitCount: Int = 0
 private var currentMotionTweenWaitCount: Int = 0

 private var motionDistanceFromPrevFrame: Int = 0
 private var motionTotalFrames: Int = 1

 // [0] = Position, [1] = Rotation, [2] = Scale
 private var motionTweenData: [MotionTweenData?] = [nil, nil, nil]
 
 /// <summary>
 /// Sets the time frame to wait until this object applies transformations during motion tween.
 /// By specifiying 0, it will apply motion tween per frame as normally according to the game's main FPS.
 /// By specifying more than 0, the motion tween will not trigger until the frame elapses - so for example:
 /// If you have 60 FPS, and you set the frames to 2, the motion tween will be applied after 2 frames step, which results in this object being applied motion tweens as if it is running in 30 FPS
 /// </summary>
 /// <param name="frames">Number of frames to wait</param>
 public func SetMotionTweenWaitCount(_ frames: Int) {
     motionTweenWaitCount = frames
     currentMotionTweenWaitCount = frames
 }

 /// <summary>Sets the motion path bezier of this object</summary>
 /// <param name="targetProperty">The target property ID: [0] = PositionXYZ, [1] = RotateXYZ, [2] = ScaleXYZ</param>
 /// <param name="totalFrames">The number of frames (moving forward in the timeline) to apply the motion path bezier</param>
 /// <param name="targetX">The destination target position/rotation/scale X-axis value when the object reaches the "totalFrames"</param>
 /// <param name="targetY">The destination target position/rotation/scale Y-axis value when the object reaches the "totalFrames"</param>
 /// <param name="targetZ">The destination target position/rotation/scale Z-axis value when the object reaches the "totalFrames"</param>
 /// <param name="targetPivotX">The destination target pivot X-axis value when the object reaches the "totalFrames"</param>
 /// <param name="targetPivotY">The destination target pivot Y-axis value when the object reaches the "totalFrames"</param>
 /// <param name="P0X">The bezier P0 point X-axis</param>
 /// <param name="P0Y">The bezier P0 point Y-axis</param>
 /// <param name="P1X">The bezier P1 point X-axis</param>
 /// <param name="P1Y">The bezier P1 point Y-axis</param>
 /// <param name="P2X">The bezier P2 point X-axis</param>
 /// <param name="P2Y">The bezier P2 point Y-axis</param>
 /// <param name="P3X">The bezier P3 point X-axis</param>
 /// <param name="P3Y">The bezier P3 point Y-axis</param>
 public func SetMotionPathBezier(
     _ targetProperty: Int,
     _ totalFrames: Int,
     _ targetX: Float,
     _ targetY: Float,
     _ targetZ: Float,
     _ targetPivotX: Float,
     _ targetPivotY: Float,
     _ P0X: Float,
     _ P0Y: Float,
     _ P1X: Float,
     _ P1Y: Float,
     _ P2X: Float,
     _ P2Y: Float,
     _ P3X: Float,
     _ P3Y: Float
 ) {
     motionTotalFrames = totalFrames
     motionDistanceFromPrevFrame = 0

     var currentTransformVector3 = Vector3(0, 0, 0)
     if targetProperty == 0 {
         currentTransformVector3 = Position
     } else if targetProperty == 1 {
         currentTransformVector3 = Rotation
     } else if targetProperty == 2 {
         currentTransformVector3 = Scale
     }

     motionTweenData[targetProperty] = MotionTweenData(
         Vector3(targetX, targetY, targetZ),
         Vector2(targetPivotX, targetPivotY),
         [
             Vector3(P0X, P0Y, 0),
             Vector3(P1X, P1Y, 0),
             Vector3(P2X, P2Y, 0),
             Vector3(P3X, P3Y, 0)
         ],
         Vector3(currentTransformVector3.x, currentTransformVector3.y, currentTransformVector3.z),
         Vector2(Pivot.x, Pivot.y)
     )
 }

 /// <summary>
 /// Gets a point in a Cubic Bezier Curve
 /// (You can visualize the points better by using bezier curve simulators: https://www.desmos.com/calculator/d1ofwre0fr?lang=en)
 /// </summary>
 /// <param name="t">Time from range 0.0 to 1.0</param>
 /// <param name="p0">Point 0</param>
 /// <param name="p1">Point 1</param>
 /// <param name="p2">Point 2</param>
 /// <param name="p3">Point 3</param>
 /// <returns>Point on the bezier curve at a specified time</returns>
 private func BezierPoint(
     _ t: Float,
     _ p0: Vector3,
     _ p1: Vector3,
     _ p2: Vector3,
     _ p3: Vector3
 ) -> Vector3 {
     let u: Float = 1 - t
     let tt: Float = t * t
     let uu: Float = u * u
     let uuu: Float = uu * u
     let ttt: Float = tt * t

     let x =
         p0.x * uuu +
         p1.x * (3 * uu * t) +
         p2.x * (3 * u * tt) +
         p3.x * ttt

     let y =
         p0.y * uuu +
         p1.y * (3 * uu * t) +
         p2.y * (3 * u * tt) +
         p3.y * ttt

     let z =
         p0.z * uuu +
         p1.z * (3 * uu * t) +
         p2.z * (3 * u * tt) +
         p3.z * ttt

     return Vector3(x, y, z)
 }
 */
