//
//  ARViewController.swift
//  Handy
//
//  Created by Mahmoud Aoata on 1.09.2024.
//

import Foundation
import ARKit

class ARViewController: UIViewController, ARSessionDelegate {
    
    // vars
    var arView: ARSCNView!
    var labelText: String = "" {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.secondLabel.text = self.labelText
            }
            
        }
    }
    
    private var label: UILabel = UILabel()
    private var secondLabel = UILabel()
    private var thirdLabel = UILabel()
    private var stackView: UIStackView = UIStackView()
    
    private var frameCounter = 0
    private let handPosePredictionInterval = 30
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraAccess()
        
    }
    
    func checkCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            
            setupARView()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { enabled in
                DispatchQueue.main.async {
                    if enabled {
                        self.setupARView()
                    } else {
                        print("not working...")
                    }
                }
            }
        case .denied, .restricted:
            print("Check settings..")
            
        @unknown default:
            print("Error")
        }
    }
    
    func setupARView() {
        arView = ARSCNView(frame: view.bounds)
        arView.session.delegate = self
        view.addSubview(arView)
        
        // generak world tracking
        
        let configuration = ARWorldTrackingConfiguration()
        
        // enable the front camera
        
        if ARFaceTrackingConfiguration.isSupported {
            let faceTrackingConfig = ARFaceTrackingConfiguration()
            arView.session.run(faceTrackingConfig)
        } else {
            // not supported
            // show an alert
            arView.session.run(configuration)
        }
        
        // add the label on the top or AR view
        // confidence
        thirdLabel = UILabel(frame: .init(x: 0, y: 0, width: 300, height: 12))
        thirdLabel.text = ""
        thirdLabel.textColor = .black
        thirdLabel.font = .systemFont(ofSize: 26)
        thirdLabel.backgroundColor = .lightText
        thirdLabel.textAlignment  = .center
        
        label = UILabel(frame: .init(x: 0, y: 0, width: self.view.frame.width, height: 30))
        label.text = labelText
        label.textColor = .white
        label.font = .systemFont(ofSize: 65)
        
        secondLabel = UILabel(frame: .init(x: 0, y: 0, width: self.view.frame.width, height: 12))
        secondLabel.text = labelText
        secondLabel.textColor = .white
        secondLabel.font = .systemFont(ofSize: 65)
        secondLabel.backgroundColor = .lightText
        secondLabel.textAlignment = .center
        
        // stack view
        stackView = .init(frame: .init(x: 0, y: 40, width: (self.view.frame.width), height: 200))
        stackView.axis = .vertical
        stackView.distribution = .equalCentering
        stackView.addArrangedSubview(secondLabel)
        stackView.addArrangedSubview(thirdLabel)
        stackView.spacing = 2
        stackView.layoutMargins = .init(top: 10, left: 30, bottom: 10, right: 30)
        
        
        view.addSubview(stackView)
        
    }
    
    // MARK: - delegate funcs
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        frameCounter += 1
        let pixelBuffer = frame.capturedImage
        
        let handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest.maximumHandCount = 1
        handPoseRequest.revision = VNDetectContourRequestRevision1
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([handPoseRequest])
        } catch {
            assertionFailure("Human Pose Request failed: \(error.localizedDescription)")
        }
        
        guard let handPoses = handPoseRequest.results, !handPoses.isEmpty else {
            // no effects to draw
            return
        }
        
        let handObservations = handPoses.first
        
        
        if frameCounter % handPosePredictionInterval == 0 {
            guard let keypointsMultiArray = try? handObservations!.keypointsMultiArray() else {
                fatalError("Failed to create key points array")
            }
            do {
                let config = MLModelConfiguration()
                config.computeUnits = .cpuAndGPU
                // ML model version setup
                let model = try HandyModel10.init(configuration: config)
                
                let handPosePrediction = try model.prediction(poses: keypointsMultiArray)
                let confidence = handPosePrediction.labelProbabilities[handPosePrediction.label]!
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.thirdLabel.text = "\(self.convertToPercentage(confidence))%"
                }
                print("labelProbabilities \(handPosePrediction.labelProbabilities)")

                // render handpose effect
                if confidence > 0.9 {

                    print("handPosePrediction: \(handPosePrediction.label)")
                    renderHandPose(name: handPosePrediction.label)
                } else {
                    print("handPosePrediction: \(handPosePrediction.label)")
                    cleanEmojii()

                }
                
            } catch let error {
                print("Failure HandyModel: \(error.localizedDescription)")
            }
            
            
        }
    }
    
    // MARK: - private funcs
    
    private func renderHandPose(name: String) {
        switch name {
        case "Two":
            
            self.showEmoji(for: .two)
            print("Two handPose dedicted...")
            
        case "Open":
            
            self.showEmoji(for: .open)
            print("Open handpose dedicted")
            
        case "Ok":
            self.showEmoji(for: .Ok)
            
            
        default:
            print("Remove nodes")
            cleanEmojii()
        }
    }
    
    private func showEmoji(for pose: Pose) {
        
        switch pose {
        case .two:
            DispatchQueue.main.async { [weak self]  in
                guard let self = self else { return }
             //   self.secondLabel.text = "✌️"
                self.labelText = "✌️"
            }
        case .open:
            
            DispatchQueue.main.async { [weak self]  in
                guard let self = self else { return }
                
                self.labelText = "✋"
            }
        case .Ok:
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.labelText = "👌"
            }
        }
    }
    
    private func cleanEmojii() {
        
        DispatchQueue.main.async {
            self.labelText = ""
            self.secondLabel.text = ""
        }
    }
    
    private func convertToPercentage(_ value: Double) -> Float {
        let result = Int((value * 1000))
        
        return Float(result) / 10
    }
    
    enum Pose: String {
        case two = "Two"
        case open = "Open"
        case Ok = "Ok"
        
    }
    
    
}
