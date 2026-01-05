//
//  ContentView.swift
//  JBGE_RealityKit
//
//  Created by Tomohiro Kadono on 2026/01/03.
//

import SwiftUI
import RealityKit
import JBGE_RCP

struct ContentView: View {
    private let rootAnchor = AnchorEntity(world: .zero)
    private var gameMain = GameMain()
    private var gameObject: GameObject = GameObject("GameMain")
    
    var body: some View {
        RealityView { content in
            if let scene = try? await Entity(named: "Scene", in: JBGE_RCPBundle) {
                content.add(scene)
                content.add(gameObject)
                content.add(rootAnchor)
                rootAnchor.addChild(gameObject)
                
                // Unity: Start equivalent
                gameMain.start(gameObject: gameObject)
                
                //let MainCamera = PerspectiveCamera()
                //MainCamera.transform.translation = SIMD3(0, 0, 0.5)
                //let WorldAnchor = AnchorEntity(world: .zero)
                //let UIAnchor = AnchorEntity(world: .zero)

                //MainCamera.addChild(WorldAnchor)
                //MainCamera.addChild(UIAnchor)

                //content.add(MainCamera)
            }
        } update: { _ in
            // Unity: Update equivalent
            gameMain.Update()
        }
    }
}

#Preview {
    ContentView()
}
