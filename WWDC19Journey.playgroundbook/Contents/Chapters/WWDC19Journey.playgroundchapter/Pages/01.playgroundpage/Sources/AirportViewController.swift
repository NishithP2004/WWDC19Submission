import Foundation
import UIKit
import ARKit
import PlaygroundSupport
import AVFoundation
import AudioToolbox

public enum BitMaskCategory: Int {
    case Developer = 4
    case Target = 7
}

public struct GameState {
    static let detectSurface = 0
    static let pointToSurface = 1
    static let readyToPlay = 2
}

public class AirportViewController : UIViewController, ARSCNViewDelegate, ARSessionDelegate, SCNPhysicsContactDelegate {
    
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
                    PlaygroundPage.current.assessmentStatus = .pass(message: "**Great** You've reached the airport! Now let's go to the [**Next Page**](@next) to see what happens next.")
                    myUtterance = AVSpeechUtterance(string: "Great! You got to the airport. Continue to see what happens next.")
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
    
    private lazy var waitLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 35.0, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var gameState: Int = GameState.detectSurface
    var focusPoint: CGPoint!
    var gameWorldCenterTransform: SCNMatrix4 = SCNMatrix4Identity
    
    var focusNode: SCNNode!
    
    var floorTemplateNode: SCNNode!
    var floor: SCNNode!
    
    var carTemplateNode: SCNNode!
    var car: SCNNode!
    
    var joystickNotificationName = NSNotification.Name("joystickNotificationName")
    let joystickVelocityMultiplier: CGFloat = 0.00007
    
    var airportTemplateNode: SCNNode!
    var airport: SCNNode!
    
    var bubbleDepth: Float = 0.01
    
    var Target: SCNNode!
    
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
            self.car.position = SCNVector3(self.car.position.x + Float(data.velocity.x * self.joystickVelocityMultiplier), self.car.position.y, self.car.position.z - Float(data.velocity.y * self.joystickVelocityMultiplier))
            self.car.eulerAngles.y = Float(data.angular) + Float(0.degreesToRadians)
        }
        
        sceneView.addSubview(startButton)
        sceneView.addSubview(self.waitLabel)
        
        let waitLabelleftMarginConstraint = NSLayoutConstraint(item: self.waitLabel, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0)
        let waitLabelrightMarginConstraint = NSLayoutConstraint(item: self.waitLabel, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0)
        let waitLabelcenterXConstraint = NSLayoutConstraint(item: self.waitLabel, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0)
        let waitLabelcenterYConstraint = NSLayoutConstraint(item: self.waitLabel, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0)
        let waitLabelheightConstraint = NSLayoutConstraint(item: self.waitLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 200)
        
        
        self.view.addConstraints([waitLabelleftMarginConstraint, waitLabelrightMarginConstraint, waitLabelcenterXConstraint, waitLabelcenterYConstraint, waitLabelheightConstraint])
        
        startButton.anchor(sceneView.safeAreaLayoutGuide.topAnchor, left: sceneView.safeAreaLayoutGuide.leftAnchor, bottom: nil, right: sceneView.safeAreaLayoutGuide.rightAnchor, topConstant: 6, leftConstant: 6, bottomConstant: 0, rightConstant: 6, widthConstant: 0, heightConstant: 768)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [unowned self] in
            self.waitLabel.text = "Scan a surface \n ex. Floor, Table"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) { [unowned self] in
            self.waitLabel.text = "Tap anywhere when \n happy with location"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [unowned self] in
            self.waitLabel.removeFromSuperview()
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
        
        let carScene = SCNScene(named: "../PrivateResources/Models/car.scn")!
        carTemplateNode = carScene.rootNode.childNode(withName: "car", recursively: false)!
        
        let airportScene = SCNScene(named: "../PrivateResources/Models/airport.scn")!
        airportTemplateNode = airportScene.rootNode.childNode(withName: "airport", recursively: false)!
        
        sceneView.scene.rootNode.addChildNode(focusNode)
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
        addCar()
        addAirport()
        addOther()
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
    
    func addCar() {
        car = carTemplateNode.clone()
        car.name = "car"
        car.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: car, options: nil))
        car.physicsBody?.isAffectedByGravity = false
        car.physicsBody?.categoryBitMask = BitMaskCategory.Developer.rawValue
        car.physicsBody?.contactTestBitMask = BitMaskCategory.Target.rawValue
        car.physicsBody?.collisionBitMask = 8
        floor.addChildNode(car)
    }
    func addAirport() {
        airport = airportTemplateNode.clone()
        airport.name = "airport"
        let smaller = airport.clone()
        smaller.scale = SCNVector3(0.06,0.6,0.06)
        airport.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: airport, options: nil))
        airport.physicsBody?.categoryBitMask = BitMaskCategory.Target.rawValue
        airport.physicsBody?.contactTestBitMask = BitMaskCategory.Developer.rawValue
        
        let airportScene = SCNScene(named: "../PrivateResources/Models/airport.scn")!
        let airportTop = airportScene.rootNode.childNode(withName: "airportTop", recursively: false)!
        let airportText: SCNNode = createNewBubbleParentNode("International Airport")
        airportText.position = airportTop.position
        
        let airplaneScene = SCNScene(named: "../PrivateResources/Models/plane.scn")!
        let airplaneNode = airplaneScene.rootNode.childNode(withName: "airplane", recursively: false)!
        
        floor.addChildNode(airportText)
        floor.addChildNode(airplaneNode)
        floor.addChildNode(airport)
    }
    
    func addOther() {
        let treeScene = SCNScene(named: "../PrivateResources/Models/Tree.scn")!
        let treesNode = treeScene.rootNode.childNode(withName: "trees", recursively: false)!
        
        let buildingScene = SCNScene(named: "../PrivateResources/Models/buildings.scn")!
        let buildingsNode = buildingScene.rootNode.childNode(withName: "buildings", recursively: false)!
        
        floor.addChildNode(treesNode)
        floor.addChildNode(buildingsNode)
        
    }
    
    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact : SCNPhysicsContact) {
        print("CONTACT")
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        if ((nodeA.physicsBody?.categoryBitMask == BitMaskCategory.Developer.rawValue) && (nodeB.physicsBody?.categoryBitMask)! == BitMaskCategory.Target.rawValue) {
            if nodeA.position.x > 0.4 {
            nodeA.removeFromParentNode()
            doneTutorial = true
            }
        }
        if ((nodeB.physicsBody?.categoryBitMask == BitMaskCategory.Developer.rawValue) && (nodeA.physicsBody?.categoryBitMask == BitMaskCategory.Target.rawValue)) {
            if nodeB.position.x > 0.4 {
            nodeB.removeFromParentNode()
            doneTutorial = true
            }
        }
    }
    
    func createNewBubbleParentNode(_ text : String) -> SCNNode {
        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
        
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
        // bubble.flatness // setting this too low can cause crashes.
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.addChildNode(sphereNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        
        return bubbleNodeParent
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
    static let width = UIScreen.main.bounds.size.width
    static let height = UIScreen.main.bounds.size.height
    static let maxLength = max(ScreenSize.width, ScreenSize.height)
    static let minLength = min(ScreenSize.width, ScreenSize.height)
    static let size = CGSize(width: ScreenSize.width, height: ScreenSize.height)
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

