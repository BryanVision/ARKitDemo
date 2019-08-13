//
//  GroundPlane.swift
//  MitchellARKitDemo
//
//  Created by Bryan Mitchell on 8/12/19.
//  Based on VirtualPlane by Ignacio Carvajal

import UIKit
import SceneKit
import ARKit

class GroundPlane: SCNNode {
    
    var anchor: ARPlaneAnchor!
    var planeGeometry: SCNPlane!
    
    //INIT FROM PLANE ANCHOR
    init(anchor: ARPlaneAnchor) {
        super.init()

        //ANCHOR
        self.anchor = anchor
        self.planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        //MATERIAL
        let material = initializePlaneMaterial()
        self.planeGeometry!.materials = [material]
        
        //POSITION
        let planeNode = SCNNode(geometry: self.planeGeometry)
        planeNode.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
        
        //UPDATE MATERIAL
        updatePlaneMaterialDimensions()
        
        //ADD
        self.addChildNode(planeNode)
    }
    
    //MATERIAL
    func initializePlaneMaterial() -> SCNMaterial {
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue.withAlphaComponent(0.35)
        return material
    }
    

    //UPDATE CALLED FROM RENDER ANCHOR UPDATE
    func updateWithNewAnchor(_ anchor: ARPlaneAnchor) {

        self.planeGeometry.width = CGFloat(anchor.extent.x)
        self.planeGeometry.height = CGFloat(anchor.extent.z)
        self.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        updatePlaneMaterialDimensions()
    }
    
    
    //UPDATE MATERIAL
    func updatePlaneMaterialDimensions() {
        
        let material = self.planeGeometry.materials.first!
        let width = Float(self.planeGeometry.width)
        let height = Float(self.planeGeometry.height)
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(width, height, 1.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
}
