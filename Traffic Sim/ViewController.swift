//
//  ViewController.swift
//  Traffic Sim
//
//  Created by Alex Halbesleben on 12/1/21.
//

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {

    @IBOutlet var skView: SKView!
    
    @IBOutlet weak var distanceLabel: NSTextField!
    @IBOutlet weak var carsLabel: NSTextField!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var distPerCarLabel: NSTextField!
    @IBOutlet weak var distPerSecLabel: NSTextField!
    @IBOutlet weak var distPerCarPerSecLabel: NSTextField!
    @IBOutlet weak var cplLabel: NSTextField!
    
    @IBOutlet weak var AVDCSLabel: NSTextField!
    @IBOutlet weak var humanDCSLabel: NSTextField!
    @IBOutlet weak var AVDensitySlider: NSSlider!
    
    @IBOutlet weak var selectedID: NSTextField!
    @IBOutlet weak var selectedAcc: NSTextField!
    @IBOutlet weak var selectedVel: NSTextField!
    @IBOutlet weak var selectedPos: NSTextField!
    @IBOutlet weak var selectedFollowing: NSTextField!
    @IBOutlet weak var selectedAccReason: NSTextField!
    
    var scene: GameScene?
    
    @IBAction func sliderChanged(_ sender: Any) {
        scene?.setDensity(CGFloat(AVDensitySlider.intValue))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load 'GameScene.sks' as a GKScene. This provides gameplay related content
        // including entities and graphs.
        if let scene = GKScene(fileNamed: "GameScene") {
            
            // Get the SKScene from the loaded GKScene
            if let sceneNode = scene.rootNode as! GameScene? {
                
                // Copy gameplay related content over to the scene
                sceneNode.entities = scene.entities
                sceneNode.graphs = scene.graphs
                
                // Set the scale mode to scale to fit the window
                sceneNode.scaleMode = .aspectFill
                
                // Present the scene
                if let view = self.skView {
                    view.presentScene(sceneNode)
                    
                    view.ignoresSiblingOrder = true
                    
                    view.showsFPS = true
                    view.showsNodeCount = true
                    
                    // It is more efficient to update statistics every 0.1 seconds (rather than every frame)
                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in self.updateStats() })
                    
                    self.scene = sceneNode
                }
            }
        }
        
    }
    
    // This function is a mess
    func updateStats() {
        let stats = scene!.stats
        
        let timeFormatter = DateComponentsFormatter()
        timeFormatter.unitsStyle = .short
        timeFormatter.allowsFractionalUnits = true
        
        let rounder = NumberFormatter()
        rounder.usesSignificantDigits = true
        rounder.maximumSignificantDigits = 5
        
        timeLabel.stringValue = timeFormatter.string(from: Double(stats["time"]!)) ?? "NaN"
        carsLabel.stringValue = "\(Int(stats["cars"] ?? -1))"
        
        let baseFormatter = MeasurementFormatter()
        baseFormatter.unitOptions = .providedUnit
        
        let feet = Double(stats["distance"]! * 32 / 15)
        
        let feetMeasurement = Measurement<UnitLength>(value: feet, unit: .feet)
        distanceLabel.stringValue = baseFormatter.string(from: feetMeasurement.converted(to: .kilometers))
        
        let distPerCar = Measurement<UnitLength>(value: feet / Double(stats["cars"]!), unit: .feet)
        distPerCarLabel.stringValue = baseFormatter.string(from: distPerCar.converted(to: .kilometers))
        
        let distPerSec = Measurement<UnitSpeed>(value: feetMeasurement.converted(to: .meters).value / Double(stats["time"]!), unit: .metersPerSecond)
        distPerSecLabel.stringValue = baseFormatter.string(from: distPerSec.converted(to: .metersPerSecond))
        
        let distPerCarPerSec = Measurement<UnitSpeed>(value: distPerSec.value / Double(stats["cars"]!), unit: .metersPerSecond)
        distPerCarPerSecLabel.stringValue = baseFormatter.string(from: distPerCarPerSec.converted(to: .metersPerSecond))
        
        let humanDistance: Measurement<UnitLength> = Measurement(value: Double(stats["human distance"]! * 32 / 15), unit: .feet)
        let humanDCS = CGFloat(humanDistance.converted(to: .meters).value) / stats["humans"]! / stats["time"]!
        let humanDCSMeasurement = Measurement<UnitSpeed>(value: Double(humanDCS), unit: .metersPerSecond)
        humanDCSLabel.stringValue = baseFormatter.string(from: humanDCSMeasurement)
        
        let avDistance: Measurement<UnitLength> = Measurement(value: Double(stats["av distance"]! * 32 / 15), unit: .feet)
        let avDCS = CGFloat(avDistance.converted(to: .meters).value) / stats["avs"]! / stats["time"]!
        let avDCSMeasurement = Measurement<UnitSpeed>(value: Double(avDCS), unit: .metersPerSecond)
        AVDCSLabel.stringValue = baseFormatter.string(from: avDCSMeasurement)
        
        let cpl: Measurement<Unit> = Measurement(value: Double(stats["cars through intersection"]! / stats["light changes"]!), unit: .init(symbol: "c/l"))
        cplLabel.stringValue = baseFormatter.string(from: cpl)
        
        AVDensitySlider.doubleValue = Double(stats["av density"] ?? 0)
        
        selectedID.stringValue = "\(scene!.selectedCar == -1 ? "None" : scene!.selectedCar.description)"
        let selectedCar: Car? = scene!.selectedCar == -1 ? nil : scene?.cars.first { $0.id == scene!.selectedCar }
        selectedAcc.stringValue = "\(selectedCar != nil ? selectedCar!.acceleration.description : "None")"
        selectedVel.stringValue = "\(selectedCar != nil ? selectedCar!.velocity.description : "None")"
        selectedPos.stringValue = "\(selectedCar != nil ? selectedCar!.progress.description : "None")"
        selectedFollowing.stringValue = "\(selectedCar != nil && selectedCar!.carAhead != nil ? selectedCar!.carAhead!.id.description : "None")"
        selectedAccReason.stringValue = "\(selectedCar != nil ? selectedCar!.velocityReason : "None")"
    }
}

