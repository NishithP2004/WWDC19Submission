/*:
 # Start your journey to WWDC 19!
 
 Hi! I'm **Pranav Karthik**, a young programmer with a huge passion in programming. I've been interested in iOS Development for the past year, and love making my ideas into fruition. I started looking in to ARKit, and tried some cool prototypes and this is what I came up with. I used the awesome framework, ARKit to create a story about your (and hopefully mine soon) journey to WWDC. I hope you like my submission! Let's get started.

 # Tutorial
 
 Congratulations! You got a ticket to WWDC 19! Let's go over your journey to WWDC starting from your home. Use the joystick in the bottom left to drive the car to the airport. Don't get stuck in the buildings! Start by detecting a plane to deploy the floor and other models.
 
 ## Notice
 * Please use in **Fullscreen Mode** for optimal performance
 * Take a few steps back for best view of the level
 * If any errors occur please try running again
 
 */

//: [Next Page](@next)

//#-hidden-code
import UIKit
import PlaygroundSupport

let viewController = AirportViewController()

PlaygroundPage.current.liveView = viewController
PlaygroundPage.current.needsIndefiniteExecution = true
//#-end-hidden-code
