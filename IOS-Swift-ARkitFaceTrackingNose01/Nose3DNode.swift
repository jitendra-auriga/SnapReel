//
//  Nose3D.swift
//  IOS-Swift-ARkitFaceTrackingNose01
//
//  Created by Jitendra on 20/12/24.
//  Copyright © 2024 Soonin. All rights reserved.
//

import SceneKit

class Nose3DNode: SCNNode {
    
    var options: [String] // Paths to 3D model files
    var index = 0
    
    init(with options: [String]) {
        self.options = options
        
        super.init()
        
        // Load the first 3D model
        loadModel(named: options.first!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadModel(named name: String) {
        guard let scene = SCNScene(named: "nose1.obj") else {
            print("Failed to load model: \(name)")
            return
        }
        
        // Extract the first child node of the scene
        if let modelNode = scene.rootNode.childNodes.first {
            // Clear existing geometry
            childNodes.forEach { $0.removeFromParentNode() }
            
            // Add the 3D model as a child node
            addChildNode(modelNode)
        }
    }
    func updatePosition(for vectors: [vector_float3]) {
        let newPos = vectors.reduce(vector_float3(), +) / Float(vectors.count)
        position = SCNVector3(newPos)
    }
}

