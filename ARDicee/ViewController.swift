//
//  ViewController.swift
//  ARDicee
//
//  Created by Michael Chen on 1/16/21.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    var diceArray = [SCNNode]()
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        //show feature points used to detect a frame
        //self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        //let there be light
        sceneView.autoenablesDefaultLighting = true
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        //enable plane detection, detecting falt surfaces
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    
    
    //ARSCNViewDelegate
    //detected a horiziontal surface, anchor is a like a tile on the floor
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        print("plane detetcted")
        
        let planeNode = createPlane(with: planeAnchor)
        
        node.addChildNode(planeNode)
        
            
    }
    
    
    
    func createPlane(with planeAnchor: ARPlaneAnchor) -> SCNNode {
        
        //think of a anchor as a tile on the ground (it has a width and a length)
        //extent is only is x and z direction
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        let planeNode = SCNNode()
        //no y since it is horizontal plane
        planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
        
        /*SCNplane is a rectangular 2d vertical plane (has x and y but no z axis)
         our plane is horizontal (has x and z but no y axis)
         need to tranform our plane node and rotate it by 90 degrees
         https://developer.apple.com/documentation/scenekit/scnplane
         red:x, green:y, blue:z
         */
        
        //angle is in radians, negative means clockwise along x axis
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
        
        //using a grid image to show the plane
        plane.materials = [gridMaterial]
        
        planeNode.geometry = plane
        
        return planeNode
        
    }
    
    
    //detecting touches on the screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //theres's only one touch object in array unless it is mutli-touch
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            
            addDice(atLocation: touchLocation)
            
            
        }
    }
    
    
    func addDice(atLocation touchLocation: CGPoint){
        
        //changes touch location in 2d space (iphone screen) to 3d spaces through camera image
        guard let query = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneInfinite, alignment: .any) else{ return }
        
        let results = sceneView.session.raycast(query)
        
        //if empty that means user touch a point outside of the existing plane
        if let hitResult = results.first{
            
            // Create a new scene
            let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn")!

            //identity name in diceCollada scene file, recursively means will go down tree to find node
            if let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true){

                /*
                 -worldTransform is a 4x4 matrix of floats (4 columns and 4 rows)
                 fourth column at index 3 corresponds to location
                 -worldTransform.columns.3.y put dice on plane so center of dice is place flush with center
                 of plane of half above and half below
                 -We need to add half the height of dice to get it to show flush on plane
                 */
                
                diceNode.position = SCNVector3(
                    x: hitResult.worldTransform.columns.3.x,
                    y: hitResult.worldTransform.columns.3.y + diceNode.boundingSphere.radius,
                    z: hitResult.worldTransform.columns.3.z)

                diceArray.append(diceNode)
                
                sceneView.scene.rootNode.addChildNode(diceNode)
                
                roll(dice: diceNode)

            }
            
        }
        
    }
    
    
    func roll (dice: SCNNode) {
        
        /*rolling the dice set up
         four faces on x and z axis
         rotating in x axis is like rotisseries chicken horizonatlly
        */
        let randomX =  Float((Int.random(in: 1...4))) * (Float.pi/2)
        
        //rotating in z axis is like pointing pencil away from you and spinning it
        let randomZ =  Float((Int.random(in: 1...4))) * (Float.pi/2)
        
        //times 5 makes the dice spins more before it stops
        dice.runAction(SCNAction.rotateBy(
                            x: CGFloat(randomX * 5),
                            y: 0,
                            z: CGFloat(randomZ * 5),
                            duration: 0.5)
        )

    }
    
    func rollAll(){
        if !diceArray.isEmpty{
            for dice in diceArray{
                roll(dice: dice)
            }
        }
    }
    
    
    @IBAction func rollAgain(_ sender: UIBarButtonItem) {
        rollAll()
    }
    
    //after you finish shaking
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        rollAll()
    }
    
    
    @IBAction func removeAllDice(_ sender: UIBarButtonItem) {
        if !diceArray.isEmpty{
            for dice in diceArray{
                dice.removeFromParentNode()
            }
        }
    }
    
    
    
    
    /*
     
     //units are in meters, chamfer radius is how round the corners would be
     //let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
     
     let sphere = SCNSphere(radius: 0.2)
     
     let material = SCNMaterial()
     material.diffuse.contents = UIImage(named: "art.scnassets/moon.jpg")    //base material for object
     sphere.materials = [material]
     
     //use for position (nodes are points in 3d space)
     let node = SCNNode()
     node.position = SCNVector3(x: 0, y: 0.1, z: -0.5)  //left-right, up-down, towards-aways from
     node.geometry = sphere       //object to display
     
     //adding the node to rootNode
     sceneView.scene.rootNode.addChildNode(node)
     
     */
    
    
    
    
    
}
