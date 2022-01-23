//
//  GameScene.swift
//  Traffic Sim
//
//  Created by Alex Halbesleben on 12/1/21.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    static let TRIAL_LENGTH: CGFloat = 45 // Trial length in seconds
    static let TRIALS_PER_DENSITY = 10
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    var road: Roads!
    
    var cars: [Car] = []
    
    var upLight: SKSpriteNode? // Traffic light nodes
    var rightLight: SKSpriteNode?
    var leftLight: SKSpriteNode?
    var downLight: SKSpriteNode?
    
    var dataManager: DataManager = DataManager() // Stores recorded data
    
    private var lastUpdateTime : TimeInterval = 0
    
    var stats: [String: CGFloat] = ["distance": 0, "time": 0, "cars": 0, "avs": 0, "humans": 0, "av distance": 0, "human distance": 0, "av density": 0, "cars through intersection": 0, "light changes": 0] // Keeps track of stats
    
    override func sceneDidLoad() {
        self.lastUpdateTime = 0
        
        upLight = (self.childNode(withName: "UpLight") as! SKSpriteNode)
        downLight = (self.childNode(withName: "DownLight") as! SKSpriteNode)
        rightLight = (self.childNode(withName: "RightLight") as! SKSpriteNode)
        leftLight = (self.childNode(withName: "LeftLight") as! SKSpriteNode)
        
        road = Roads(scene: self)
        
        print("Scene loaded")
    }
    
    func setDensity(_ value: CGFloat) {
        stats["av density"]! = value
        print("Set density to \(value): \(stats["av density"] ?? CGFloat.nan)%")
    }
    
    func startTrial() {
        print("Starting trial")
        // Removes the old cars
        for car in cars {
            car.current.cars.removeAll { $0 == car } // This is necessary. If it doesn't happen, new cars will stop for these "ghost cars"
            car.node.removeFromParent()
            entities.remove(at: entities.firstIndex(of: car)!)
        }
        print("Cars removed")
        for key in stats.keys {
            if (key == "av density") { // This stat stays the same throughout
                continue
            }
            stats[key]! = 0
        }
        print("Stats reset")
        cars = []
        for r in [road.outLeftUpIn, road.outLeftDownOut, road.outDownLeftIn, road.outDownRightOut, road.outRightDownIn, road.outRightUpOut, road.outUpRightIn, road.outUpLeftOut, road.inUpRight, road.inDownLeft] {
            let isHuman = cars.count * 10 >= Int(stats["av density"]!) //
            let car: Car = isHuman ? HumanCar(node: SKSpriteNode(imageNamed: "Car"), scene: self, road: r) : AutonomousCar(node: SKSpriteNode(imageNamed: "Car"), scene: self, road: r)
            car.progress = r.distance / 2 + CGFloat.random(in: -100...100) // So we can make each run different
            cars.append(car)
            entities.append(car)
            scene?.addChild(car.node)
            stats["cars"]! += 1
            if (isHuman) {
                stats["humans"]! += 1
                (car as! HumanCar).queue = Array(repeating: 0.01, count: (car as! HumanCar).queueSize)
            } else {
                stats["avs"]! += 1
                (car as! AutonomousCar).changeColor() // Autonomous cars should be green so they can be differentiated from human-controlled cars
            }
        }
        print("Cars created")
        print("Trial begun")
    }
    
    override func didMove(to view: SKView) {
        // Create a tracking area object with self as the owner (i.e., the recipient of mouse-tracking messages
        let trackingArea = NSTrackingArea(rect: view.frame, options: [.activeInKeyWindow, .mouseMoved], owner: self, userInfo: nil)
        // Add the tracking area to the view
        view.addTrackingArea(trackingArea)
        print("Tracking area created")
    }
    
    var selectedCar: Int = -1
    
    override func mouseUp(with event: NSEvent) {
        let loc = event.location(in: self)
        for node in self.nodes(at: loc) { // Finds which nodes the mouse clicked on
            let matchingCars = cars.filter { $0.node == node}
            for car in matchingCars {
                selectedCar = car.id
            }
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if (event.keyCode == 0x31) { // Pause when the spacebar is hit
            isPaused = !isPaused
        } else {
            startTrial()
        }
    }
    
    var trialsCompleted = 0 // Trials completed at the given density
    var secondsSinceTrialStart: CGFloat = 0 // Seconds elapsed since the most recent trial began
    
    func nextTrial() {
        trialsCompleted += 1
        
        let currentDensity = stats["av density"] ?? 0
        
        let dcs = stats["distance"]! / stats["cars"]! / stats["time"]!
        let adcs = stats["av distance"]! / stats["avs"]! / stats["time"]!
        let hdcs = stats["human distance"]! / stats["humans"]! / stats["time"]!
        let cpl = stats["cars through intersection"]! / stats["light changes"]!
        
        if (dcs >= 20.0) {
            dataManager.addEntry(key: "DCS", density: currentDensity, value: dcs)
            dataManager.addEntry(key: "aDCS", density: currentDensity, value: adcs)
            dataManager.addEntry(key: "hDCS", density: currentDensity, value: hdcs)
            dataManager.addEntry(key: "CPL", density: currentDensity, value: cpl) // TODO
            
            print("Added DCS \(dcs), aDCS \(adcs), hDCS \(hdcs), CPL \(cpl)")
        } else {
            trialsCompleted -= 1
            print("Did not add DCS \(dcs) because it was under 20; re-running trial")
        }
        
        print("\(updatesInTrial) updates in trial")
        
        
        if (trialsCompleted >= GameScene.TRIALS_PER_DENSITY) {
            trialsCompleted = 0
            
            let currentDensity = stats["av density"] ?? 0
            if (currentDensity >= 100.0) { // i.e. we have done everything
                dataManager.output()
                // Essentially resets everything
                secondsSinceTrialStart = 0
                isPaused = true
                setDensity(0)
                return
            } else {
                setDensity(currentDensity + 10) // increment density
            }
        }
        
        let total = 11 * Int(GameScene.TRIAL_LENGTH) * GameScene.TRIALS_PER_DENSITY
        let trialsRun = trialsCompleted + Int(currentDensity / 10) * GameScene.TRIALS_PER_DENSITY
        let eta = total - trialsRun * Int(GameScene.TRIAL_LENGTH)
        
        print("ETA: \(eta / 3600) hours, \(eta / 60 % 60) minutes, \(eta % 60) seconds")
        
        startTrial()
        secondsSinceTrialStart = 0
    }
    
    var updatesInTrial: Int = 0
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        stats["time"]! += CGFloat(dt)
        secondsSinceTrialStart += CGFloat(dt)
        
        updatesInTrial += 1
        if (secondsSinceTrialStart >= GameScene.TRIAL_LENGTH) {
            nextTrial()
            updatesInTrial = 0
        }
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
}
