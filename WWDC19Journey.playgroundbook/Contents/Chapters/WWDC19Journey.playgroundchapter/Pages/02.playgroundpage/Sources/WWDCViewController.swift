import Foundation
import UIKit
import ARKit
import PlaygroundSupport
import AVFoundation

public enum BitMaskCategory: Int {
    case Developer = 4
    case Target = 7
    case Landmark = 8
}

public struct GameState {
    static let detectSurface = 0
    static let pointToSurface = 1
    static let readyToPlay = 2
}

public class WWDCViewController : UIViewController, ARSCNViewDelegate, ARSessionDelegate, SCNPhysicsContactDelegate {
    
    var sceneView: ARSCNView!
    
    
    var titleLabel: UILabel = UILabel()
    
    
    let synth = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")
    
    lazy var skView: SKView = {
        let view = SKView()
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()
    
    fileprivate var doneTutorial: Bool = false {
        didSet {
            if doneTutorial {
                PlaygroundPage.current.assessmentStatus = .pass(message: "**Congratulations** you have reached your destination on time! Head [**inside**](@next) to know more.")
                myUtterance = AVSpeechUtterance(string: "You have reached your destination ont ime! Head inside to proceed.")
                myUtterance.rate = 0.5
                myUtterance.voice = AVSpeechSynthesisVoice(language: "en-gb")
                synth.speak(myUtterance)
            }
        }
    }
    
    lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0)
        button.setTitle("", for: .normal)
        button.tintColor = .white
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(startGame), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private lazy var beginText: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 35.0, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var landmarkInfo: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.3)
        label.textColor = .black
        label.text = "Apple Park is the corporate headquarters of Apple Inc., located at 1 Apple Park Way in Cupertino, California, United States. It opened to employees in April 2017, while construction was still underway. Its research and development facilities are occupied by more than 2,000 people. It superseded the original headquarters at 1 Infinite Loop, which opened in 1993."
        label.numberOfLines = 4
        label.clipsToBounds = true
        label.layer.cornerRadius = 4.0
        label.isHidden = true
        return label
    }()
    
    var gameState: Int = GameState.detectSurface
    var focusPoint: CGPoint!
    var gameWorldCenterTransform: SCNMatrix4 = SCNMatrix4Identity
    
    var focusNode: SCNNode!
    
    var floorTemplateNode: SCNNode!
    var floor: SCNNode!
    
    var heroTemplateNode: SCNNode!
    var hero: SCNNode!
    
    var joystickNotificationName = NSNotification.Name("joystickNotificationName")
    let joystickVelocityMultiplier: CGFloat = 0.00007
    
    var wwdcTemplateNode: SCNNode!
    var wwdc: SCNNode!
    
    var Target: SCNNode!
    var bubbleDepth: Float = 0.01
    
    var applePark: SCNNode!
    
    override public func loadView() {
        sceneView = ARSCNView(frame: CGRect(x: 0.0, y: 0.0, width: 1024.0, height: 768.0))//width 1024 height 768
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.scene.physicsWorld.contactDelegate = self
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        sceneView.session.delegate = self
        self.view = sceneView
        sceneView.session.run(config)
    }
    
    override public func viewDidLoad() {
        
        NotificationCenter.default.addObserver(forName: joystickNotificationName, object: nil, queue: OperationQueue.main) { (notification) in
            guard let userInfo = notification.userInfo else { return }
            let data = userInfo["data"] as! AnalogJoystickData
            
            self.hero.position = SCNVector3(self.hero.position.x + Float(data.velocity.x * self.joystickVelocityMultiplier), self.hero.position.y, self.hero.position.z - Float(data.velocity.y * self.joystickVelocityMultiplier))
            
            self.hero.eulerAngles.y = Float(data.angular) + Float(0.degreesToRadians)
            
        }
        sceneView.addSubview(startButton)
        sceneView.addSubview(self.beginText)
        sceneView.addSubview(landmarkInfo)
        
        
        
        let beginTextleftMarginConstraint = NSLayoutConstraint(item: self.beginText, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0)
        let beginTextrightMarginConstraint = NSLayoutConstraint(item: self.beginText, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0)
        let beginTextcenterXConstraint = NSLayoutConstraint(item: self.beginText, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0)
        let beginTextcenterYConstraint = NSLayoutConstraint(item: self.beginText, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0)
        let beginTextheightConstraint = NSLayoutConstraint(item: self.beginText, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 200)
        
        
        self.view.addConstraints([beginTextleftMarginConstraint, beginTextrightMarginConstraint, beginTextcenterXConstraint, beginTextcenterYConstraint, beginTextheightConstraint])
        
        startButton.anchor(sceneView.safeAreaLayoutGuide.topAnchor, left: sceneView.safeAreaLayoutGuide.leftAnchor, bottom: nil, right: sceneView.safeAreaLayoutGuide.rightAnchor, topConstant: 6, leftConstant: 6, bottomConstant: 0, rightConstant: 6, widthConstant: 0, heightConstant: 768)
        
        landmarkInfo.anchor(sceneView.safeAreaLayoutGuide.topAnchor, left: sceneView.safeAreaLayoutGuide.leftAnchor, bottom: sceneView.safeAreaLayoutGuide.bottomAnchor, right: sceneView.safeAreaLayoutGuide.rightAnchor, topConstant: 234, leftConstant: 400, bottomConstant: 234, rightConstant:400, widthConstant: 200, heightConstant: 300)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [unowned self] in
            self.beginText.text = "Scan a surface \n ex. Floor, Table"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) { [unowned self] in
            self.beginText.text = "Tap anywhere when \n happy with location"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [unowned self] in
            self.beginText.removeFromSuperview()
        }
        
        view.addSubview(skView)
        skView.anchor(nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 180)
        
        let jscene = ARJoystickSKScene(size: CGSize(width: view.bounds.size.width, height: 180))
        jscene.scaleMode = SKSceneScaleMode.resizeFill
        skView.presentScene(jscene)
        skView.ignoresSiblingOrder = true
        
        focusPoint = CGPoint(x: view.center.x,
                             y: view.center.y + view.center.y * 0.25)
        
        let scene = SCNScene()
        scene.isPaused = false
        sceneView.scene = scene
        scene.physicsWorld.contactDelegate = self
        
        let focusScene = SCNScene(named: "../PrivateResources/Models/FocusScene.scn")!
        focusNode = focusScene.rootNode.childNode(withName: "focus", recursively: false)!
        focusNode.isHidden = true
        
        let floorScene = SCNScene(named: "../PrivateResources/Models/Floor.scn")!
        floorTemplateNode = floorScene.rootNode.childNode(withName: "floor", recursively: false)!
        
        let heroScene = SCNScene(named: "../PrivateResources/Models/Developer.scn")!
        heroTemplateNode = heroScene.rootNode.childNode(withName: "MaleDeveloper", recursively: false)!
        
        let wwdcScene = SCNScene(named: "../PrivateResources/Models/wwdc.scn")!
        wwdcTemplateNode = wwdcScene.rootNode.childNode(withName: "wwdc", recursively: false)!
        
        sceneView.scene.rootNode.addChildNode(focusNode)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    func createARPlaneNode(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = "../PrivateResources/Textures/Surface.png"
        planeGeometry.materials = [planeMaterial]
        
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        
        return planeNode
    }
    
    func updateARPlaneNode(planeNode: SCNNode, planeAchor: ARPlaneAnchor) {
        let planeGeometry = planeNode.geometry as! SCNPlane
        planeGeometry.width = CGFloat(planeAchor.extent.x)
        planeGeometry.height = CGFloat(planeAchor.extent.z)
        planeNode.position = SCNVector3Make(planeAchor.center.x, 0, planeAchor.center.z)
    }
    
    func removeARPlaneNode(node: SCNNode) {
        for childNode in node.childNodes {
            childNode.removeFromParentNode()
        }
    }
    
    func updateFocusNode() {
        let results = self.sceneView.hitTest(self.focusPoint,
                                             types: [.existingPlaneUsingExtent])
        
        if results.count == 1 {
            if let match = results.first {
                let t = match.worldTransform
                self.focusNode.position = SCNVector3( x: t.columns.3.x,
                                                      y: t.columns.3.y - 0.05,
                                                      z: t.columns.3.z)
                self.gameState = GameState.readyToPlay
            }
        } else {
            self.gameState = GameState.pointToSurface
        }
    }
    
    func suspendARPlaneDetection() {
        let config = sceneView.session.configuration as! ARWorldTrackingConfiguration
        config.planeDetection = []
        sceneView.session.run(config)
    }
    
    func hideARPlaneNodes() {
        for anchor in (self.sceneView.session.currentFrame?.anchors)! {
            if let node = self.sceneView.node(for: anchor) {
                for child in node.childNodes {
                    let material = child.geometry?.materials.first!
                    material?.colorBufferWriteMask = []
                }
            }
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    
    public func removeChildrenNodes() {
        let children = self.sceneView.scene.rootNode.childNodes
        for child in children {
            child.removeFromParentNode()
        }
    }
    
    
    @objc func startGame() {
        DispatchQueue.main.async {
            self.startButton.isHidden = true
            self.focusNode.isHidden = true
            self.suspendARPlaneDetection()
            self.hideARPlaneNodes()
            self.gameState = GameState.pointToSurface
            self.createGameWorld()
        }
    }
    
    func createGameWorld() {
        gameWorldCenterTransform = focusNode.transform
        skView.isHidden = false
        
        addFloor(to: sceneView.scene.rootNode)
        addHero()
        addWWDC()
        addLandmarks()
    }
    
    func addFloor(to rootNode: SCNNode) {
        floor = floorTemplateNode.clone()
        floor.name = "floor"
        
        floor.position = SCNVector3(gameWorldCenterTransform.m41,gameWorldCenterTransform.m42,gameWorldCenterTransform.m43)
        
        let rotate = simd_float4x4(SCNMatrix4MakeRotation(sceneView.session.currentFrame!.camera.eulerAngles.y, 0, 1, 0))
        let rotateTransform = simd_mul(simd_float4x4(gameWorldCenterTransform), rotate)
        floor.transform = SCNMatrix4(rotateTransform)
        floor.scale = SCNVector3(1,1,1)
        rootNode.addChildNode(floor)
    }
    
    func moveObstacle1(node: SCNNode) {
        let move = CABasicAnimation(keyPath: "position")
        move.fromValue = node.presentation.position
        move.toValue = SCNVector3(node.presentation.position.x,node.presentation.position.y,node.presentation.position.z - 0.3)
        move.duration = 2
        move.autoreverses = true
        move.repeatCount = 100
        node.addAnimation(move, forKey: "position")
    }
    
    func addHero() {
        hero = heroTemplateNode.clone()
        hero.name = "hero"
        hero.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: hero, options: nil))
        hero.physicsBody?.isAffectedByGravity = false
        hero.physicsBody?.categoryBitMask = BitMaskCategory.Developer.rawValue
        hero.physicsBody?.contactTestBitMask = BitMaskCategory.Target.rawValue | BitMaskCategory.Landmark.rawValue
        hero.physicsBody?.collisionBitMask = 8
        floor.addChildNode(hero)
    }
    func addWWDC() {
        wwdc = wwdcTemplateNode.clone()
        wwdc.name = "wwdc"
        wwdc.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: wwdc, options: nil))
        wwdc.physicsBody?.categoryBitMask = BitMaskCategory.Target.rawValue
        wwdc.physicsBody?.contactTestBitMask = BitMaskCategory.Developer.rawValue
        
        let wwdcScene = SCNScene(named: "../PrivateResources/Models/wwdc.scn")!
        let wwdcTop = wwdcScene.rootNode.childNode(withName: "wwdcTop", recursively: false)!
        let wwdcTopTop = wwdcScene.rootNode.childNode(withName: "wwdcTopTop", recursively: false)!
        let wwdcText: SCNNode = createNewBubbleParentNode(" WWDC 19 ")
        let buildingText: SCNNode = createNewBubbleParentNode("McEnery Convention Center")
        buildingText.position = wwdcTop.position
        wwdcText.position = wwdcTopTop.position
        
        floor.addChildNode(wwdcText)
        floor.addChildNode(buildingText)
        floor.addChildNode(wwdc)
    }
    
    func addLandmarks() {
        let appleScene = SCNScene(named: "../PrivateResources/Models/apple.scn")!
        let appleNode = appleScene.rootNode.childNode(withName: "apple", recursively: false)!
        let appleTop = appleScene.rootNode.childNode(withName: "appleTop", recursively: false)!
        applePark = appleNode.clone()
        applePark.name = "applePark"
        applePark.physicsBody? = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: applePark, options: nil))
        applePark.physicsBody?.categoryBitMask = BitMaskCategory.Landmark.rawValue
        applePark.physicsBody?.contactTestBitMask = BitMaskCategory.Developer.rawValue
        let appleText : SCNNode = createNewBubbleParentNode("Apple Park")
        appleText.position = appleTop.position
        
        let googleScene = SCNScene(named: "../PrivateResources/Models/Google.scn")!
        let googleNode = googleScene.rootNode.childNode(withName: "google", recursively: false)!
        let googleTop = googleScene.rootNode.childNode(withName: "googleTop", recursively: false)!
        googleNode.name = "googlePlex"
        let googleText: SCNNode = createNewBubbleParentNode("Googleplex")
        googleText.position = googleTop.position
        
        let goldenScene = SCNScene(named: "../PrivateResources/Models/goldenGate.scn")!
        let goldenNode = goldenScene.rootNode.childNode(withName: "bridge", recursively: false)!
        let goldenTop = goldenScene.rootNode.childNode(withName: "bridgeTop", recursively: false)!
        goldenNode.name = "goldenGateBridge"
        let goldenText: SCNNode = createNewBubbleParentNode("Golden Gate Bridge")
        goldenText.position = goldenTop.position
        
        let salesforceScene = SCNScene(named: "../PrivateResources/Models/salesforce.scn")!
        let salesforceNode = salesforceScene.rootNode.childNode(withName: "building", recursively: false)!
        let salesforceTop = salesforceScene.rootNode.childNode(withName: "buildingTop", recursively: false)!
        salesforceNode.name = "salesforceTower"
        let salesforceText: SCNNode = createNewBubbleParentNode("Salesforce Tower")
        salesforceText.position = salesforceTop.position
        
        floor.addChildNode(applePark)
        floor.addChildNode(appleText)
        floor.addChildNode(googleNode)
        floor.addChildNode(googleText)
        floor.addChildNode(goldenNode)
        floor.addChildNode(goldenText)
        floor.addChildNode(salesforceNode)
        floor.addChildNode(salesforceText)
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let location = sender.location(in: sceneView)
        let results = sceneView.hitTest(location, options: [SCNHitTestOption.searchMode : 1])
        
        guard sender.state == .began else { return }
        for result in results.filter( { $0.node.name != nil }) {
            if result.node.name == "applePark" {
                landmarkInfo.isHidden = false
                result.node.removeFromParentNode()
            }
        }
    }
    
    func createNewBubbleParentNode(_ text : String) -> SCNNode {
        
        // TEXT BILLBOARD CONSTRAINT
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // BUBBLE-TEXT
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        var font = UIFont(name: "Futura", size: 0.15)
        bubble.font = font
        bubble.alignmentMode = kCAAlignmentCenter
        bubble.firstMaterial?.diffuse.contents = UIColor.red
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
        bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.addChildNode(sphereNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        
        return bubbleNodeParent
    }
    
    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact : SCNPhysicsContact) {
        print("CONTACT")
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        if ((nodeA.physicsBody?.categoryBitMask == BitMaskCategory.Developer.rawValue) && (nodeB.physicsBody?.categoryBitMask)! == BitMaskCategory.Target.rawValue) {
            if nodeA.position.x > 0.4 && nodeB.position.z > 0.3{
                nodeA.removeFromParentNode()
                doneTutorial = true
            }
        }
        if ((nodeB.physicsBody?.categoryBitMask == BitMaskCategory.Developer.rawValue) && (nodeA.physicsBody?.categoryBitMask == BitMaskCategory.Target.rawValue)) {
            if nodeB.position.x > 0.4 && nodeB.position.z > 0.3{
                nodeB.removeFromParentNode()
                doneTutorial = true
            }
        }
        
        if ((nodeA.physicsBody?.categoryBitMask == BitMaskCategory.Developer.rawValue) && (nodeB.physicsBody?.categoryBitMask)! == BitMaskCategory.Landmark.rawValue) {
                landmarkInfo.isHidden = false
        }
        if ((nodeB.physicsBody?.categoryBitMask == BitMaskCategory.Developer.rawValue) && (nodeA.physicsBody?.categoryBitMask == BitMaskCategory.Landmark.rawValue)) {
                landmarkInfo.isHidden = false
        }
    }
    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusNode()
        }
    }
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if let planeAnchor = anchor as? ARPlaneAnchor {
            
            DispatchQueue.main.async {
                let planeNode = self.createARPlaneNode(planeAnchor: planeAnchor)
                node.addChildNode(planeNode)
                
                if self.startButton.isHidden {
                    self.startButton.isHidden = false
                }
                if self.focusNode.isHidden {
                    self.focusNode.isHidden = false
                }
            }
            
        }
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor, node.childNodes.count > 0 {
            DispatchQueue.main.async {
                self.updateARPlaneNode(planeNode: node.childNodes[0], planeAchor: planeAnchor)
            }
        }
    }
    
    public func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        DispatchQueue.main.async {
            self.removeARPlaneNode(node: node)
        }
    }
}
extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

extension UIView {
    public func addConstraintsWithFormat(_ format: String, views: UIView...) {
        
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            viewsDictionary[key] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
    }
    
    public func fillSuperview() {
        translatesAutoresizingMaskIntoConstraints = false
        if let superview = superview {
            leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
            rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
            topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
            bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
        }
    }
    
    public func anchor(_ top: NSLayoutYAxisAnchor? = nil, left: NSLayoutXAxisAnchor? = nil, bottom: NSLayoutYAxisAnchor? = nil, right: NSLayoutXAxisAnchor? = nil, topConstant: CGFloat = 0, leftConstant: CGFloat = 0, bottomConstant: CGFloat = 0, rightConstant: CGFloat = 0, widthConstant: CGFloat = 0, heightConstant: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        
        _ = anchorWithReturnAnchors(top, left: left, bottom: bottom, right: right, topConstant: topConstant, leftConstant: leftConstant, bottomConstant: bottomConstant, rightConstant: rightConstant, widthConstant: widthConstant, heightConstant: heightConstant)
    }
    
    public func anchorWithReturnAnchors(_ top: NSLayoutYAxisAnchor? = nil, left: NSLayoutXAxisAnchor? = nil, bottom: NSLayoutYAxisAnchor? = nil, right: NSLayoutXAxisAnchor? = nil, topConstant: CGFloat = 0, leftConstant: CGFloat = 0, bottomConstant: CGFloat = 0, rightConstant: CGFloat = 0, widthConstant: CGFloat = 0, heightConstant: CGFloat = 0) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        
        var anchors = [NSLayoutConstraint]()
        
        if let top = top {
            anchors.append(topAnchor.constraint(equalTo: top, constant: topConstant))
        }
        
        if let left = left {
            anchors.append(leftAnchor.constraint(equalTo: left, constant: leftConstant))
        }
        
        if let bottom = bottom {
            anchors.append(bottomAnchor.constraint(equalTo: bottom, constant: -bottomConstant))
        }
        
        if let right = right {
            anchors.append(rightAnchor.constraint(equalTo: right, constant: -rightConstant))
        }
        
        if widthConstant > 0 {
            anchors.append(widthAnchor.constraint(equalToConstant: widthConstant))
        }
        
        if heightConstant > 0 {
            anchors.append(heightAnchor.constraint(equalToConstant: heightConstant))
        }
        
        anchors.forEach({$0.isActive = true})
        
        return anchors
    }
    
    public func anchorCenterXToSuperview(constant: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        if let anchor = superview?.centerXAnchor {
            centerXAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        }
    }
    
    public func anchorCenterYToSuperview(constant: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        if let anchor = superview?.centerYAnchor {
            centerYAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        }
    }
    
    public func anchorCenterSuperview() {
        anchorCenterXToSuperview()
        anchorCenterYToSuperview()
    }
}

struct ScreenSize {
    static let width        = UIScreen.main.bounds.size.width
    static let height       = UIScreen.main.bounds.size.height
    static let maxLength    = max(ScreenSize.width, ScreenSize.height)
    static let minLength    = min(ScreenSize.width, ScreenSize.height)
    static let size         = CGSize(width: ScreenSize.width, height: ScreenSize.height)
}

struct DeviceType {
    static let isiPhone4OrLess = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength < 568.0
    static let isiPhone5 = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 568.0
    static let isiPhone6 = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 667.0
    static let isiPhone6Plus = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 736.0
    static let isiPhoneX = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 812.0
    static let isiPad = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.maxLength == 1024.0
    static let isiPadPro = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.maxLength == 1366.0
}

extension SCNNode {
    func size() -> (width: Float, height: Float, lenght: Float) {
        let (localMin, localMax) = self.boundingBox
        let min = self.convertPosition(localMin, to: nil)
        let max = self.convertPosition(localMax, to: nil)
        
        let width = max.x - min.x
        let height = max.y - min.y
        let lenght =  max.z - min.z
        
        return (width, height, lenght)
    }
}


