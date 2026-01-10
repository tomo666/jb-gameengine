//
//  GameEngine.swift
//  JBGE_RealityKit
//
//  Created by Tomohiro Kadono on 2026/01/03.
//

import RealityKit

open class GameEngine {
    // For showing debug info (although this uses Unity's Canvas so currently is a placeholder)
    public var DebugDeviceInputCanvasObj: GameObject? = nil
    public var DebugPerformanceCanvasObj: GameObject? = nil

    // Main GameObject
    public var MainGameObject: GameObject
    
    // Reference to 2D Game Engine
    public var TopDownGameMain: Any? = nil

    // Manages the non-UI components
    public var SceneManager: GameObject? = nil
    // Manages the actors within the game
    public var ActorManager: GameObject? = nil
    // Manages the map within the game
    public var MapManager: GameObject? = nil
    
    // Flag to determine if DEBUG info should be shown on screen or not
    public var IsShowDebugInfo: Bool = false
    // Defines the target frame rate (defaults to 60)
    public var TargetFrameRate: Int = 60
    // Stores the average frame rate
    public var AverageFrameRate: Int = 0
    // Stores the frame count 0 to 60
    public var FrameCount: Int = 0
    // Amount of frame to wait until executing the next script
    public var WaitFrameCount: Int = 0
    // Determines if we are in wait state or not
    public var IsWaiting: Bool = false

    // Reference to the Main Camera object
    public var MainCamera: Camera = Camera("MainCamera")
    // Reference to the UICamera camera object
    public var UICamera: Camera = Camera("UICamera")
    // Set to false if camera is in perspective mode, else true in orthographic mode
    public var IsUICameraOrthographic: Bool = false
    // If in perspective mode, the horizontal Field Of View Angle (in degrees)
    public var FOV: Float = 60.0
    // The Pixel Per Unit scale to lift up UI scaling
    public var PPUScaleUpUI: Float = 4.0
    // The Pixel Per Unit scale to lift up 2D Map scaling (Actually it's the ortho size so not affecting the actual object scales)
    public var PPUScaleUpWorld: Float = 5.0

    // Reference to the Main Camera (or virtual camera) object
    public var CinemachineVirtualCamera: Any? = nil
    // Reference to the CinemachinePositionComposer
    public var CinemachinePositionComposer: Any? = nil

    // Manages all textmeshpro text used in game
    public var TextBlockManagerList: [Any] = []
    // TextBlockManager: current list index to operate on
    public var CurrentTextBlockManagerIndex: Int = 0
    // TextBlock: current list index to operate on
    public var CurrentTextBlockIndex: Int = 0

    // TextBlockManager: current list index to operate on
    public var CurrentBMPTextManagerIndex: Int = 0
    // TextBlock: current list index to operate on
    public var CurrentBMPTextIndex: Int = 0
    
    // The one and only Base UI Layer that always sits in front of the UICamera
    public var UIBaseLayer: UIComponent? = nil
    // UI layer that manages actors (or sprites)
    public var UIBackgroundLayer: UIComponent? = nil
    
    // Stores all the UILayer(s) that is placed on the UIBaseLayer UICanvas
    public var UILayers: [Int: UIComponent] = [:]
    // Stores all the 2D textures used in this game
    public var Textures: [Int: Any] = [:]
    // Stores all the Image object used in this game
    public var Images: [Int: Any] = [:]
    // Stores all the Font object used in this game
    public var Fonts: [Int: Any] = [:]
    // Stores all the BMPText object used in this game
    public var Texts: [Int: Any] = [:]
    // Stores all the Actor2D object used in this game
    public var Actor2Ds: [Int: Any] = [:]
    // Stores all the Map2D object used in this game
    public var Map2Ds: [Int: Any] = [:]

    // ImageManager: current list index to operate on
    public var CurrentImageManagerIndex: Int = 0
    // Image: current list index to operate on
    public var CurrentImageIndex: Int = 0

    // Image direction to search in the atlas for creating animations that are made up of multiple sprites
    public enum SheetOrientation {
        case Horizontal
        case Vertical
    }
    // General horizontal alignment definitions
    public enum HorizontalAlignment {
        case Left
        case Center
        case Right
    }
    // General vertical alignment definitions
    public enum VerticalAlignment {
        case Top
        case Middle
        case Bottom
    }
    // General orientation definitions
    public enum Orientation {
        case Horizontal
        case Vertical
    }
    // General speed identifiers
    public enum MovementSpeed {
        case VerySlow
        case Slow
        case Normal
        case Fast
        case VeryFast
    }

    // User gamepad device inputs
    public var IDGamePad: IDGamePad = JBGE_RealityKit.IDGamePad()
    // User mouse device inputs
    public var IDMouse: IDMouse = JBGE_RealityKit.IDMouse()
    // User keyboard device inputs
    public var IDKeyboard: IDKeyboard = JBGE_RealityKit.IDKeyboard()
    // Manages all user inputs
    public lazy var UserInput: IDUserInput = IDUserInput(self)

    // The global pixel per unit applied to non-UI 2D graphic elements
    public var GlobalPixelPerUnit = 32
    
    public init(_ gameObject: GameObject, _ screenWidth: Float, _ screenHeight: Float) {
        MainGameObject = gameObject

        SceneManager = CreateGameObject("SceneManager")
        ActorManager = CreateGameObject("ActorManager")
        MapManager = CreateGameObject("MapManager")

        ActorManager?.transform.SetParent(SceneManager?.transform)
        MapManager?.transform.SetParent(SceneManager?.transform)
        
        if let cube = MainGameObject.findEntity(named: "CubeTest") {
            cube.removeFromParent()
            SceneManager?.addChild(cube)
        }
        
        //SceneManager?.transform.SetParent(MainCamera.transform)
        
        // We need to call this in order to check for Addressable asset existence
        //Addressables.InitializeAsync();
        
        UpdateScreenSize(screenWidth, screenHeight)
        
        // Initialize UI
        InitializeUI()
    }
    
    // RealityKit Specific: Creates a new GameObject under the root anchor
    public func CreateGameObject(_ name: String) -> GameObject {
        let newGameObject = GameObject(name)
        MainGameObject.addChild(newGameObject)
        return newGameObject
    }

    public func UpdateScreenSize(_ width: Float, _ height: Float) {
        guard height > 0 else { return }

        let aspect = width / height
        MainCamera.aspect = aspect
        UICamera.aspect = aspect

        print("[GameMain] Screen Size Changed: \(width) x \(height) --> aspect: \(aspect)")
    }


    private func InitializeUI() {
        MainGameObject.addChild(MainCamera)
        MainGameObject.addChild(UICamera)

        CinemachineVirtualCamera = nil
        CinemachinePositionComposer = nil

        // If perspective mode, set camera properties
        if !IsUICameraOrthographic {
            // Perspective UI Camera
            MainCamera.orthographic = false
            MainCamera.fieldOfView = FOV
        } else {
            // Orthographic UI Camera（pseudo）
            UICamera.orthographic = true
        }

        // Create the one and utmost base layer
        UIBaseLayer = UIComponent(self, "UIBaseLayer", nil, true, true)
        UIBaseLayer?.TransformAll(Vector3(1.0, 1.0, 1.0), Vector3(0.0, 0.0, 0.0), Vector3(0.5, 0.5, 1.0), Vector3(0, 0, 45),
        Vector2(0.0, 0.0), Vector2(0.0, 0.0), Vector2(1.0, 1.0))
        //UIBaseLayer?.TransformScale(Vector3(0.5, 0.5, 0.5), Vector2(1.0, 1.0));
        //UIBaseLayer?.TransformPosition(Vector3(0.0, 0.0, 0.0), Vector2(0.0, 0.0));
        //UIBaseLayer?.TransformRotation(Vector3(0.0, 0.0, 45.0), Vector2(1.0, 1.0));
        
        UIBaseLayer?.IsVisible = true

        // Create UI Layers
        //let UIBackgroundLayerID = CreateUILayer("UIBackgroundLayer")
        //UIBackgroundLayer = UILayers[UIBackgroundLayerID]
        
        // Debug test
        //UIBackgroundLayer?.SetPivot(0.5, 0.5)
        //UIBackgroundLayer?.SetScale(0.25, 0.25)
        
        
        print("[GameEngine] Initialize UI Completed.")
        print("===== ENTITY HIERARCHY DUMP =====")
        dumpEntityTree(MainGameObject)
        print("================================")
    }

    /// <summary>Creates a new Layer under the base layer</summary>
    /// <returns>ID is generated that can be used to identify the newly created object (if creation fails, returns -1)</returns>
    @discardableResult
    public func CreateUILayer(_ layerName: String = "Layer") -> Int {
        guard let baseLayer = UIBaseLayer else { return -1 }

        let layer = UIComponent(self, layerName, baseLayer, true, true)

        // We need to set the pivot and position of this layer to center of our UICamera
        layer.ResetTransform()
        layer.TransformScale(Vector3(1.0, 1.0, 1.0), Vector2(0.5, 0.5))
        layer.TransformRotation(Vector3(0, 0, 0), Vector2(0.5, 0.5))
        layer.TransformPosition(Vector3(0.5, 0.5, 0.0), Vector2(0.5, 0.5))

        if let controller = layer.Controller {
            layer.ThisObject.SetSizeFrom(controller)
        }

        layer.IsVisible = true

        // Sort order for each custom UI layer is incremented by 1000, where the UI BaseLayer is 0
        layer.SortOrder = (UILayers.count + 1) * 1000

        // Ensure unique ID
        while UILayers[layer.ID] != nil {
            layer.ID = Int.random(in: Int.min...Int.max)
        }

        UILayers[layer.ID] = layer
        return layer.ID
    }

    /// <summary>Destroys the UILayer from our list</summary>
    /// <param name="id">The handle ID of the object to be deleted</param>
    public func DestroyUILayer(_ id: Int) {
        guard let layer = UILayers[id] else { return }
        layer.Destroy()
        UILayers.removeValue(forKey: id)
    }
    
    private func updateUIFollowCamera() {
        guard let uiBase = UIBaseLayer else { return }

        let camPos = MainCamera.worldPosition
        let camForward = MainCamera.forward

        let uiPos = camPos + camForward * 1.0
        uiBase.ThisObject.position = SIMD3<Float>(uiPos.x, uiPos.y, uiPos.z)

        // 回転も同期（画面に正対させる）
        uiBase.ThisObject.orientation = MainCamera.orientation
    }
    
    private var time: Float = 0

    public func Update(_ deltaTime: Float) {
        time += deltaTime

        guard let scene = SceneManager else { return }

        let r: Float = 2.0
        let x = cos(time) * r
        let z = sin(time) * r

        // ワールドを動かす（＝カメラが周回して見える）
        scene.position = SIMD3<Float>(-x, 0, -z)
    }
    
    /*
    private var time: Float = 0
    public func Update(_ deltaTime: Float) {
        MainCamera.isEnabled = true
        UICamera.isEnabled = false
        time += deltaTime

        let r: Float = 2.0
        let x = cos(time) * r
        let z = sin(time) * r + 2.0

        MainCamera.position = Vector3(x, 0.5, z)
        MainCamera.lookAt(Vector3(0, 0, 0))

        updateUIFollowCamera()
        
        /*
        guard let cam = realityCamera else { return }
        time += deltaTime

        let r: Float = 2.0
        let x = cos(time) * r
        let z = sin(time) * r + 2.0
        cam.position = SIMD3(x, 0.5, z)
        cam.look(at: .zero, from: cam.position, relativeTo: nil)

        // 注視点（簡易）
        MainCamera.lookAt(Vector3(0, 0, 0))
         */
        
        //MainCamera.Render()
        //UICamera.Render()
        
        //print("T = \(t) / deltaTime = \(deltaTime)")
    }
    */
    
    /*
    public void Update() {

      UserInput.Update();

      foreach(KeyValuePair<int, Actor2D> kvp in Actor2Ds) {
        kvp.Value.Update();
      }
      foreach(KeyValuePair<int, Map2D> kvp in Map2Ds) {
        kvp.Value.Update();
      }
      foreach(KeyValuePair<int, Image> kvp in Images) {
        kvp.Value.Update();
      }
      foreach(KeyValuePair<int, BMPText> kvp in Texts) {
        kvp.Value.Update();
      }

      // Get user input states
      if(Gamepad.current != null) {
        IDGamePad.IsNorthPressed = Gamepad.current.buttonNorth.isPressed;
        IDGamePad.IsSouthPressed = Gamepad.current.buttonSouth.isPressed;
        IDGamePad.IsWestPressed = Gamepad.current.buttonWest.isPressed;
        IDGamePad.IsEastPressed = Gamepad.current.buttonEast.isPressed;
        IDGamePad.LeftStickValue = Gamepad.current.leftStick.ReadValue();
        IDGamePad.RightStickValue = Gamepad.current.rightStick.ReadValue();
        IDGamePad.IsLeftShoulderPressed = Gamepad.current.leftShoulder.ReadValue() == 1 ? true : false;
        IDGamePad.IsRightShoulderPressed = Gamepad.current.rightShoulder.ReadValue() == 1 ? true : false;
        IDGamePad.LeftTriggerValue = Gamepad.current.leftTrigger.ReadValue();
        IDGamePad.RightTriggerValue = Gamepad.current.rightTrigger.ReadValue();
        IDGamePad.DPadValue = Gamepad.current.dpad.ReadValue();
        IDGamePad.IsLeftStickPressed = Gamepad.current.leftStickButton.IsPressed();
        IDGamePad.IsRightStickPressed = Gamepad.current.rightStickButton.IsPressed();
        IDGamePad.IsSelectPressed = Gamepad.current.selectButton.IsPressed();
        IDGamePad.IsStartPressed = Gamepad.current.startButton.IsPressed();
      }

      if(Mouse.current != null) {
        IDMouse.IsMouseLeftPressed = Mouse.current.leftButton.isPressed;
        IDMouse.IsMouseRightPressed = Mouse.current.rightButton.isPressed;
        IDMouse.IsMouseMiddlePressed = Mouse.current.middleButton.isPressed;
        IDMouse.IsMouseForwardPressed = Mouse.current.forwardButton.isPressed;
        IDMouse.IsMouseBackPressed = Mouse.current.backButton.isPressed;
        IDMouse.ScrollAmount = (int)Mouse.current.scroll.y.ReadValue();
        Vector2 mousePosition = Mouse.current.position.ReadValue();
        IDMouse.MousePosition = new Vector2((float)Math.Round(mousePosition.x), (float)Math.Round(Screen.height - mousePosition.y));
      }

      // B Key to toggle debug info display
      if(IDKeyboard.IsKeyPressed((int)KeyCode.B) && IsWaiting == false) {
        IsShowDebugInfo = !IsShowDebugInfo;
        DebugDeviceInputCanvasObj.SetActive(IsShowDebugInfo);
        DebugPerformanceCanvasObj.SetActive(IsShowDebugInfo);
        WaitFrameCount = 10;
        IsWaiting = true;
      }

      // Show input status
      if(IsShowDebugInfo) {
        string strInputStates = "GAMEPAD STATES\n";
        strInputStates += "BTN NORTH [△]: " + IDGamePad.IsNorthPressed + "\n";
        strInputStates += "BTN EAST [〇]: " + IDGamePad.IsEastPressed + "\n";
        strInputStates += "BTN SOUTH [×]: " + IDGamePad.IsSouthPressed + "\n";
        strInputStates += "BTN WEST [□]: " + IDGamePad.IsWestPressed + "\n";
        strInputStates += "BTN LEFT1 [L1]: " + IDGamePad.IsLeftShoulderPressed + "\n";
        strInputStates += "BTN RIGHT1 [R1]: " + IDGamePad.IsRightShoulderPressed + "\n";
        strInputStates += "BTN Trigger Left [L2]: " + IDGamePad.IsLeftTriggerPressed + "\n";
        strInputStates += "BTN Trigger Right [R2]: " + IDGamePad.IsRightTriggerPressed + "\n";
        strInputStates += "BTN LEFT STICK [L3]: " + IDGamePad.IsLeftStickPressed + "\n";
        strInputStates += "BTN RIGHT STICK [R3]: " + IDGamePad.IsRightStickPressed + "\n";
        strInputStates += "BTN START [Start]: " + IDGamePad.IsStartPressed + "\n";
        strInputStates += "BTN Select [Select]: " + IDGamePad.IsSelectPressed + "\n";
        strInputStates += "DPAD Value (X,Y):" + IDGamePad.DPadValue + "\n";
        strInputStates += "DPAD [↑]: " + IDGamePad.IsDPadNorthPressed + "\n";
        strInputStates += "DPAD [↑→]: " + IDGamePad.IsDPadNorthEastPressed + "\n";
        strInputStates += "DPAD [→]: " + IDGamePad.IsDPadEastPressed + "\n";
        strInputStates += "DPAD [→↓]: " + IDGamePad.IsDPadSouthEastPressed + "\n";
        strInputStates += "DPAD [↓]: " + IDGamePad.IsDPadSouthPressed + "\n";
        strInputStates += "DPAD [↓←]: " + IDGamePad.IsDPadSouthWestPressed + "\n";
        strInputStates += "DPAD [←]: " + IDGamePad.IsDPadWestPressed + "\n";
        strInputStates += "DPAD [←↑]: " + IDGamePad.IsDPadNorthWestPressed + "\n";
        strInputStates += "Left Stick Value (X,Y): " + IDGamePad.LeftStickValue + "\n";
        strInputStates += "Right Stick Value (X,Y): " + IDGamePad.RightStickValue + "\n";
        strInputStates += "Left Trigger Value: " + IDGamePad.LeftTriggerValue + "\n";
        strInputStates += "Right Trigger Value: " + IDGamePad.RightTriggerValue + "\n";
        strInputStates += "--------------------------\n";
        strInputStates += "MOUSE STATES\n";
        strInputStates += "BTN LEFT PRESSED: " + IDMouse.IsMouseLeftPressed + "\n";
        strInputStates += "BTN RIGHT PRESSED: " + IDMouse.IsMouseRightPressed + "\n";
        strInputStates += "BTN MIDDLE PRESSED: " + IDMouse.IsMouseMiddlePressed + "\n";
        strInputStates += "BTN FORWARD PRESSED: " + IDMouse.IsMouseForwardPressed + "\n";
        strInputStates += "BTN BACK PRESSED: " + IDMouse.IsMouseBackPressed + "\n";
        strInputStates += "V-SCROLL: " + IDMouse.ScrollAmount + "\n";
        strInputStates += "V-SCROLL UP: " + IDMouse.IsScrolledUp + "\n";
        strInputStates += "V-SCROLL DOWN: " + IDMouse.IsScrolledDown + "\n";
        strInputStates += "POSITION: " + IDMouse.MousePosition + "\n";
        strInputStates += "--------------------------\n";
        strInputStates += "KEYBOARD STATES\n";
        strInputStates += "KEY PRESSED: " + IDKeyboard.IsAnyKeyPressed + "\n";
        strInputStates += "KEY CODE: " + IDKeyboard.PressedKeyCode + "\n";

        TextMeshProUGUI textInput = DebugDeviceInputCanvasObj.GetComponent<TextMeshProUGUI>();
        textInput.SetText(strInputStates);
      }
    }*/

    // Debug: Dumps the entire scene's hierarchy
    public func dumpEntityTree(
        _ entity: Entity,
        indent: String = "",
        isLast: Bool = true
    ) {
        let marker = isLast ? "└─" : "├─"
        let name = entity.name.isEmpty ? "(unnamed)" : entity.name
        let typeName = String(describing: type(of: entity))

        print("\(indent)\(marker) \(name) [\(typeName)]")

        let nextIndent = indent + (isLast ? "   " : "│  ")
        let children = entity.children

        for i in 0..<children.count {
            dumpEntityTree(
                children[i],
                indent: nextIndent,
                isLast: i == children.count - 1
            )
        }
    }
}

