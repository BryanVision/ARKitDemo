//
//  ViewController.swift
//  MitchellARKitDemo
//
//  Created by Bryan Mitchell on 8/12/19.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    //AR KIT SCENE VIEW (OUTPUT)
    @IBOutlet var sceneView: ARSCNView!
    
    //STORE PLANE TO ITERATE FOR TOUCH
    var planes = [UUID: GroundPlane]()
    
    //CHARACTER NODE REFERENCES (FOR TOGGLING)
    var drummerNode: SCNReferenceNode!
    var robotNode: SCNReferenceNode!
    
    //STATE/TRACKING
    //WHEN 0, ADD ROBOT ON PLANE TOUCH, WHEN 1, DO NOTHING
    var numNodes: Int = 0
    

    override func viewDidLoad() {
        
        //BOILERPLATE
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        //START AN EMPTY SCENE
        let scene = SCNScene()
        sceneView.scene = scene
        
        //INITIALIZE THE TWO USDZ MODELS
        self.initializeDrummerNode()
        self.initializeRobotNode()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        //BOILERPLATE
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()

        //SETUP CONFIG FOR HORIZONTAL PLANE DETECTION
        configuration.planeDetection = .horizontal

        //START SESSION
        sceneView.session.run(configuration)
        
        //DEBUG OPTIONS (FEATURES LEFT ON TO ASSIST WITH FINDING SURFACES THAT WILL MAKE A PLANE)
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
    }
    

    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    
    //TOGGLE BETWEEN ROBOT AND DRUMMER
    @IBAction func toggleAction (sender: UIButton) {
        funcToggleCharacter ()
    }


    //CHECK FOR PLANE ANCHORS, ADD PLANES TO SCENE
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        if let arPlaneAnchor = anchor as? ARPlaneAnchor {
            let plane = GroundPlane(anchor: arPlaneAnchor)
            self.planes[arPlaneAnchor.identifier] = plane
            node.addChildNode(plane)
        }
    }
    
    //UPDATE ANCHORS
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor, let plane = planes[arPlaneAnchor.identifier] {
            plane.updateWithNewAnchor(arPlaneAnchor)
        }
    }
    
    //REMOVE PLANES WHEN NEEDED
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor, let index = planes.index(forKey: arPlaneAnchor.identifier) {
            planes.remove(at: index)
        }
    }
    
    
    //CHECK TOUCHE AGAINST ALL PLANES
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else {
            return
        }
        
        let touchPoint = touch.location(in: sceneView)
 
        //IF USER TOUCHED A PLANE, ADD ROBOT TO PLANE AT LOCATION
        if let plane = planeForTouch(touchPoint: touchPoint) {
            addRobotToPlane(plane: plane, atPoint: touchPoint)
        }
    }
    
    //INIT DRUMMER BEFORE USE
    func initializeDrummerNode() {
        
        guard let urlPath = Bundle.main.url(forResource: "toy_drummer", withExtension: "usdz") else {
            print("COULD NOT LOAD TOY DRUMMER")
            return
        }
        self.drummerNode = SCNReferenceNode(url: urlPath)
        drummerNode.load()
        
    }
    
    //INIT ROBOT BEFORE USE
    func initializeRobotNode() {
        
        guard let urlPath = Bundle.main.url(forResource: "toy_robot_vintage", withExtension: "usdz") else {
            print("COULD NOT LOAD TOY ROBOT")
            return
        }
        self.robotNode = SCNReferenceNode(url: urlPath)
        robotNode.load()
        
    }
    
    //CHECK IF USER TOUCHED A PLANE, IF THEY DID, RETURN PLANE
    func planeForTouch(touchPoint: CGPoint) -> GroundPlane? {
        let hits = sceneView.hitTest(touchPoint, types: .existingPlaneUsingExtent)
        if hits.count > 0, let firstHit = hits.first, let identifier = firstHit.anchor?.identifier, let plane = planes[identifier] {
            return plane
        }
        return nil
    }
    
    //ADD A ROBOT TO A PLANE
    func addRobotToPlane(plane: GroundPlane, atPoint point: CGPoint) {
        let hits = sceneView.hitTest(point, types: .existingPlaneUsingExtent)
        if hits.count > 0, let firstHit = hits.first {
            if (self.numNodes < 1)
            {
                if let anotherRobot = robotNode?.clone() {
                    anotherRobot.position = SCNVector3Make(firstHit.worldTransform.columns.3.x, firstHit.worldTransform.columns.3.y, firstHit.worldTransform.columns.3.z)
                    anotherRobot.scale = SCNVector3(0.01, 0.01, 0.01)
                    anotherRobot.name = "robot"
                    sceneView.scene.rootNode.addChildNode(anotherRobot)
                    self.numNodes = self.numNodes + 1
                }
            }
        }
    }
    
    //TOGGLE BETWEEN ROBOT AND DRUMMER
    func funcToggleCharacter ()
    {
        //MAKE SURE WE HAVE ALREADY ADDED A CHARACTER BEFORE
        if (self.numNodes > 0)
        {
            //LOOP THROUGH ALL CHILDNODES TO LOOK FOR A ROBOT OR DRUMMER
            sceneView.scene.rootNode.enumerateChildNodes { (existingNode, _) in
                
                //IF WE FIND A ROBOT, GRAB THE LOCATION, SWAP IN A DRUMMER
                if (existingNode.name == "robot")
                {
                    let currentPosition = existingNode.position
                    existingNode.removeFromParentNode()
                    
                    if let anotherDrummer = drummerNode?.clone() {
                        anotherDrummer.position = currentPosition
                        anotherDrummer.scale = SCNVector3(0.02, 0.02, 0.02)
                        anotherDrummer.name = "drummer"
                        sceneView.scene.rootNode.addChildNode(anotherDrummer)
                        
                        return
                    }
                    
                }
                
                //IF WE FIND A DRUMMER, GRAB THE LOCATION, SWAP IN A ROBOT
                if (existingNode.name == "drummer")
                {
                    let currentPosition = existingNode.position
                    existingNode.removeFromParentNode()
                    
                    if let anotherRobot = robotNode?.clone() {
                        anotherRobot.position = currentPosition
                        anotherRobot.scale = SCNVector3(0.01, 0.01, 0.01)
                        anotherRobot.name = "robot"
                        sceneView.scene.rootNode.addChildNode(anotherRobot)
                        
                        return
                    }
                    
                }

            }
        }
    }
    
   
}
