import UIKit
import AVFoundation
import AudioToolbox

public class QuizViewController: UIViewController {
    
    let questions = ["Which iPad's were most recently released by Apple Inc?", "Who is the current CEO of Apple?", "When was the first WWDC?", "How do you declare a constant in swift?"]
    
    let answers = [["iPad Mini & iPad Air", "iPad Pro 14 & iPad 0", "iPad & iPad 2020", "New iPad A & iPad Nano"],["Tim Cook", "Steve Jobs", "Steve Wozniak", "John Sculley"],["1987", "2001", "2011", "1979"], ["let", "const", "default", "value"]]
    
    var currentQuestion = 0
    var rightAnswerPlacement:UInt32 = 0
    
    let emitterLayer = CAEmitterLayer()
    
//    var upDown: CABasicAnimation!
    var badge: UIImageView!
    var security: UIImageView!
    var point: UIImageView!
    var github: UIImageView!
    var browser: UIImageView!
    
    let synth = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")
    
    var soundID: SystemSoundID = 0

    
    lazy var lbl: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "AvenirNext-Regular", size: 20.0)
        label.textColor = .black
        label.textAlignment = .left
        label.numberOfLines = 3
        label.frame = CGRect(x: 88, y: 45, width: 452, height: 209)
        return label
    }()
    
    lazy var githubText: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "AvenirNext-Regular", size: 35.0)
        label.text = "Pranav Karthik ~ ZORLAXX"
        label.textColor = .black
        label.textAlignment = .left
        label.numberOfLines = 1
        label.frame = CGRect(x: github.center.x + 200, y: github.center.y - 100, width: 452, height: 209)
        label.isHidden = true
        return label
    }()
    
    lazy var browserText: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "AvenirNext-Regular", size: 35.0)
        label.text = "www.pranavkarthik.surge.sh"
        label.textColor = .black
        label.textAlignment = .left
        label.numberOfLines = 1
        label.frame = CGRect(x: browser.center.x + 200, y: browser.center.y - 100, width: 452, height: 209)
        label.isHidden = true
        return label
    }()
    
    lazy var end: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 150.0, weight: .bold)
        label.text = "WWDC19"
        label.textColor = .white
        label.textAlignment = .left
        label.numberOfLines = 3
        label.frame = CGRect(x: 126, y: 103, width: 806, height: 180)
        label.isHidden = true
        return label
    }()
    
    lazy var nameProfile: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "AvenirNext-Bold", size: 80.0)
        label.text = "Pranav Karthik"
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 1
        label.frame = CGRect(x: 179, y: 103, width: 700, height: 100)
        label.isHidden = true
        return label
    }()
    
    lazy var answerButton1: UIButton = {
        let button = UIButton(type: .system)
        button.tag = 1
        button.backgroundColor = UIColor(red: 79/255, green: 210/255, blue: 247/255, alpha: 1)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        button.tintColor = .black
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(answerAction), for: .touchUpInside)
        button.frame = CGRect(x: 88, y: 240, width: 452, height: 73)
        return button
    }()
    
    lazy var answerButton2: UIButton = {
        let button = UIButton(type: .system)
        button.tag = 2
        button.backgroundColor = UIColor(red: 79/255, green: 210/255, blue: 247/255, alpha: 1)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        button.tintColor = .black
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(answerAction), for: .touchUpInside)
        button.frame = CGRect(x: 88, y: 337, width: 452, height: 73)
        return button
    }()
    
    lazy var answerButton3: UIButton = {
        let button = UIButton(type: .system)
        button.tag = 3
        button.backgroundColor = UIColor(red: 79/255, green: 210/255, blue: 247/255, alpha: 1)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        button.tintColor = .black
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(answerAction), for: .touchUpInside)
        button.frame = CGRect(x: 88, y: 437, width: 452, height: 73)
        return button
    }()
    
    lazy var answerButton4: UIButton = {
        let button = UIButton(type: .system)
        button.tag = 4
        button.backgroundColor = UIColor(red: 79/255, green: 210/255, blue: 247/255, alpha: 1)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        button.tintColor = .black
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(answerAction), for: .touchUpInside)
        button.frame = CGRect(x: 88, y: 537, width: 452, height: 73)
        return button
    }()
    
    lazy var profileButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 62/255, green: 115/255, blue: 163/255, alpha: 0)
        button.setTitle("About Me", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 40, weight: .bold)
        button.tintColor = .white
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(createProfile), for: .touchUpInside)
        button.frame = CGRect(x: 774, y: 291, width: 180, height: 60)
        button.isHidden = true
        return button
    }()
    
    let guardImage = UIImage(named: "../PrivateResources/guard.png")
    let pointImage = UIImage(named: "../PrivateResources/pointing.png")
    let badgeImage = UIImage(named: "../PrivateResources/badge.png")
    let githubImage = UIImage(named: "../PrivateResources/github.png")
    let browserImage = UIImage(named: "../PrivateResources/browser.png")
    
    
    @objc func createProfile() {
        self.view.backgroundColor = .white
        self.emitterLayer.removeFromSuperlayer()
        self.end.isHidden = true
        self.badge.isHidden = true
        self.nameProfile.isHidden = false
        self.point.isHidden = true
        self.profileButton.isHidden = true
        self.github.isHidden = false
        self.githubText.isHidden = false
        self.browserText.isHidden = false
        self.browser.isHidden = false
    
    }
    
    

//
    @objc func answerAction(_ sender: AnyObject) {
        if (sender.tag == Int(rightAnswerPlacement)) {
            if (currentQuestion != questions.count) {
                AudioServicesPlaySystemSound(soundID)
                newQuestion()
            }
            else {
                UIView.animate(withDuration: 2) {
                    self.security.center.x += self.view.bounds.width
                }
                UIView.animate(withDuration: 2) {
                    self.answerButton1.center.x -= self.view.bounds.width - 30
                    self.answerButton2.center.x -= self.view.bounds.width - 30
                    self.answerButton3.center.x -= self.view.bounds.width - 30
                    self.answerButton4.center.x -= self.view.bounds.width - 30
                    self.lbl.center.x -= self.view.bounds.width
                }
                myUtterance = AVSpeechUtterance(string: "Congratulations! You made it to WWDC and received your badge! ")
                myUtterance.rate = 0.5
                myUtterance.voice = AVSpeechSynthesisVoice(language: "en-gb")
                synth.speak(myUtterance)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [unowned self] in
                    self.end.isHidden = false
                    self.badge.isHidden = false
                    self.view.backgroundColor = UIColor(red: 29/255, green: 45/255, blue: 68/255, alpha: 1)
                    self.setupBaseLayer()
                    self.launchFireworks()
                    self.profileButton.isHidden = false
                    self.point.isHidden = false
                    let upDown = CABasicAnimation(keyPath: "position")
                    upDown.duration = 0.9
                    upDown.repeatCount = 30
                    upDown.autoreverses = true
                    upDown.fromValue = NSValue(cgPoint: CGPoint(x: self.point.center.x, y: self.point.center.y))
                    upDown.toValue = NSValue(cgPoint: CGPoint(x: self.profileButton.center.x, y: self.point.center.y + 25))
                    self.point.layer.add(upDown, forKey: "position")
                }
            }
        }
        else {
            print("do incorrect animation here")
        }
    }
    
    
    func setupBaseLayer()
    {
        // Add a layer that emits, animates, and renders a particle system.
        let size = view.bounds.size
        emitterLayer.emitterPosition = CGPoint(x: size.width / 2, y: size.height - 100)
        view.layer.addSublayer(emitterLayer)
    }
    
    func launchFireworks()
    {
        // Get particle image
        let particleImage = UIImage(named: "../PrivateResources/particle.png")?.cgImage
        
        // The definition of a particle (launch point of the firework)
        let baseCell = CAEmitterCell()
        baseCell.color = UIColor.white.withAlphaComponent(0.8).cgColor
        baseCell.emissionLongitude = -CGFloat.pi / 2
        baseCell.emissionRange = CGFloat.pi / 5
        baseCell.emissionLatitude = 0
        baseCell.lifetime = 2.0
        baseCell.birthRate = 1
        baseCell.velocity = 400
        baseCell.velocityRange = 50
        baseCell.yAcceleration = 300
        baseCell.redRange   = 0.5
        baseCell.greenRange = 0.5
        baseCell.blueRange  = 0.5
        baseCell.alphaRange = 0.5
        
        // The definition of a particle (rising animation)
        let risingCell = CAEmitterCell()
        risingCell.contents = particleImage
        risingCell.emissionLongitude = (4 * CGFloat.pi) / 2
        risingCell.emissionRange = CGFloat.pi / 7
        risingCell.scale = 0.4
        risingCell.velocity = 100
        risingCell.birthRate = 50
        risingCell.lifetime = 1.5
        risingCell.yAcceleration = 350
        risingCell.alphaSpeed = -0.7
        risingCell.scaleSpeed = -0.1
        risingCell.scaleRange = 0.1
        risingCell.beginTime = 0.01
        risingCell.duration = 0.7
        
        // The definition of a particle (spark animation)
        let sparkCell = CAEmitterCell()
        sparkCell.contents = particleImage
        sparkCell.emissionRange = 2 * CGFloat.pi
        sparkCell.birthRate = 8000
        sparkCell.scale = 0.5
        sparkCell.velocity = 130
        sparkCell.lifetime = 3.0
        sparkCell.yAcceleration = 80
        sparkCell.beginTime = 1.5
        sparkCell.duration = 0.1
        sparkCell.alphaSpeed = -0.1
        sparkCell.scaleSpeed = -0.1
        
        // baseCell contains rising and spark particle
        baseCell.emitterCells = [risingCell, sparkCell]
        
        // Add baseCell to the emitter layer
        emitterLayer.emitterCells = [baseCell]
    }
    
    
    override public func viewWillAppear(_ animated: Bool) {
        
    }
    
    func newQuestion () {
        lbl.text = questions[currentQuestion]
        
        rightAnswerPlacement = arc4random_uniform(4)+1
        
        var button:UIButton = UIButton()
        var x = 1
        
        for i in 1...4 {
            button = view.viewWithTag(i) as! UIButton
            
            if (i == rightAnswerPlacement) {
                button.setTitle(answers[currentQuestion][0], for: .normal)
                
            }
            else {
                button.setTitle(answers[currentQuestion][x], for: .normal)
                if x == 2 {
                    x = 3
                }
                else {
                    x = 2
                }
            }
        }
        currentQuestion += 1
    }
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        security = UIImageView(image: guardImage!)
        security.frame = CGRect(x: 598, y: 240, width: 406, height: 374)
        github = UIImageView(image: githubImage!)
        github.frame = CGRect(x: 174, y: 476, width: 180, height: 180)
        github.isHidden = true
        browser = UIImageView(image: browserImage!)
        browser.frame = CGRect(x: 174, y: 276, width: 180, height: 180)
        browser.isHidden = true
        badge = UIImageView(image: badgeImage!)
        badge.frame = CGRect(x: 377, y: 291, width: 271, height: 428)
        badge.isHidden = true
        point = UIImageView(image: pointImage!)
        point.frame = CGRect(x: 774, y: 426, width: 180, height: 213)
        point.isHidden = true
        
        let path = Bundle.main.path(forResource: "correct", ofType: "mp3")
        let baseURL = NSURL(fileURLWithPath: path!)
        AudioServicesCreateSystemSoundID(baseURL, &soundID)
        
        view.addSubview(lbl)
        view.addSubview(end)
        view.addSubview(nameProfile)
        view.addSubview(answerButton1)
        view.addSubview(answerButton2)
        view.addSubview(answerButton3)
        view.addSubview(answerButton4)
        view.addSubview(profileButton)
        view.addSubview(point)
        view.addSubview(security)
        view.addSubview(badge)
        view.addSubview(github)
        view.addSubview(githubText)
        view.addSubview(browser)
        view.addSubview(browserText)
        newQuestion()
        // Do any additional setup after loading the view, typically from a nib.
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


