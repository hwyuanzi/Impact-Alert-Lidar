import UIKit
import ARKit
import AVFoundation
// Main AR view controller that handles UI, AR session, depth processing, and alerts
class ARViewController: UIViewController, ARSessionDelegate {
    var sceneView: ARSCNView!
    var startStopButton: UIButton!
    // var statusLabel: UILabel!
    // var currentAverageLabel: UILabel!
    // var previousAverageLabel: UILabel!
    // var differenceLabel: UILabel!
    // var speedLabel: UILabel!
    // var timeToImpactLabel: UILabel!
    var isARSessionRunning: Bool = false
    // var gridOverlayView: UIView!
    var ttiSlider: UISlider!
    var ttilabel: UILabel!
    var ttiThreshold: Float = 3
    var speedThreshold: Float = -2.2
    var distanceThresholdLabel: UILabel!
    var distanceSlider: UISlider!
    var speedThresholdLabel: UILabel!
    var speedSlider: UISlider!
    var slabel: UILabel!
    var depthArray: [[Float32]] = []
    var middleSums: [Float32] = []
    var frameCounter: Int = 0
    var threatDistances: [Float32] = []
    var audioPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        sceneView = ARSCNView(frame: .zero)
        sceneView.isHidden = true
        view.addSubview(sceneView)
        sceneView.session.delegate = self

        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) else {
            fatalError("LiDAR not supported on this device.")
        }

        
        /*
        sceneView = ARSCNView(frame: self.view.frame)
        self.view.addSubview(sceneView)
        
        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) else {
            fatalError("LiDAR not supported on this device.")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
        sceneView.session.delegate = self
        */
        
        setupUI()               // Set up user interface elements
        // setupGridOverlay()      // Set up the detection grid overlay on the screen
        setupTTISlider()        // Set up the time-to-impact threshold slider
        setupSpeedSlider()      // Set up the speed threshold slider
        loadSound()             // Load alert sound
    }
    
    // Load the alert sound from the app bundle
    func loadSound() {
            guard let soundURL = Bundle.main.url(forResource: "alert", withExtension: "mp3") else {
                print("Sound file not found")
                return
            }
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Failed to load sound: \(error)")
            }
        }
    
    // Play the loaded alert sound
    func playAlertSound() {
        audioPlayer?.play()
        }

    // Set up the slider UI and label for adjusting speed threshold
    func setupSpeedSlider() {
        slabel = UILabel(frame: CGRect(x: 20, y: 280, width: view.frame.width - 40, height: 40))
        slabel.textAlignment = .center
        slabel.textColor = .blue
        slabel.text = "Speed Threshold: \(speedThreshold) m/s"
        view.addSubview(slabel)
        
        speedSlider = UISlider(frame: CGRect(x: 20, y: 320, width: view.frame.width - 40, height: 40))
        speedSlider.minimumValue = -5
        speedSlider.maximumValue = 0
        speedSlider.value = speedThreshold
        speedSlider.addTarget(self, action: #selector(speedSliderChanged), for: .valueChanged)
        view.addSubview(speedSlider)
    }

    // Handle value changes from the speed slider
    @objc func speedSliderChanged(sender: UISlider) {
        speedThreshold = sender.value
        slabel.text = String(format: "Speed Threshold: %.2f m/s", speedThreshold)
    }
    
    // Set up the slider UI and label for adjusting time-to-impact threshold
    func setupTTISlider() {
        ttilabel = UILabel(frame: CGRect(x: 20, y: 380, width: view.frame.width - 40, height: 40))
        ttilabel.textAlignment = .center
        ttilabel.textColor = .blue
        ttilabel.text = "Time to Impact Threshold: \(ttiThreshold) s"
        view.addSubview(ttilabel)
        
        ttiSlider = UISlider(frame: CGRect(x: 20, y: 420, width: view.frame.width - 40, height: 40))
        ttiSlider.minimumValue = 0
        ttiSlider.maximumValue = 6
        ttiSlider.value = ttiThreshold
        ttiSlider.addTarget(self, action: #selector(ttiSliderChanged), for: .valueChanged)
        view.addSubview(ttiSlider)
    }

    // Handle value changes from the time-to-impact slider
    @objc func ttiSliderChanged(sender: UISlider) {
        ttiThreshold = sender.value
        ttilabel.text = String(format: "Time to Impact Threshold: %.2f", ttiThreshold)
    }

    // Set up UI labels and start/stop button
    func setupUI() {
        startStopButton = UIButton(type: .system)
        startStopButton.setTitle("Start LiDAR", for: .normal)
        startStopButton.addTarget(self, action: #selector(toggleARSession), for: .touchUpInside)
        //Button Size
            let buttonWidth: CGFloat = 140
            let buttonHeight: CGFloat = 50

            //Location
            startStopButton.frame = CGRect(
                x: (view.frame.width - buttonWidth) / 2,
                y: view.frame.height - 180,
                width: buttonWidth,
                height: buttonHeight
            )

            startStopButton.backgroundColor = .white
            startStopButton.layer.cornerRadius = 5
            startStopButton.layer.borderWidth = 1
            startStopButton.layer.borderColor = UIColor.black.cgColor
            view.addSubview(startStopButton)
        /*
        startStopButton.frame = CGRect(x: 20, y: view.frame.height - 60, width: 100, height: 40)
        startStopButton.backgroundColor = .white
        startStopButton.layer.cornerRadius = 5
        startStopButton.layer.borderWidth = 1
        startStopButton.layer.borderColor = UIColor.black.cgColor
        view.addSubview(startStopButton)
         */
        
        // Disclaimer
        let disclaimerLabel = UILabel(frame: CGRect(
                x: 20,
                y: view.frame.height - 120,
                width: view.frame.width - 40,
                height: 60
            ))
            disclaimerLabel.textAlignment = .center
            disclaimerLabel.textColor = .lightGray
            disclaimerLabel.font = UIFont.systemFont(ofSize: 12)
            disclaimerLabel.numberOfLines = 0
            disclaimerLabel.text = "This app is for experimental use only. It may occasionally give false alerts or fail to provide alerts when needed. Please remain aware of your surroundings as you normally would without using this app."
            view.addSubview(disclaimerLabel)
        
        /*
        statusLabel = UILabel(frame: CGRect(x: 20, y: 40, width: view.frame.width - 40, height: 40))
        statusLabel.textAlignment = .center
        statusLabel.textColor = .white
        statusLabel.text = "AR Session Paused"
        view.addSubview(statusLabel)
        
        currentAverageLabel = UILabel(frame: CGRect(x: 20, y: 80, width: view.frame.width - 40, height: 40))
        currentAverageLabel.textAlignment = .center
        currentAverageLabel.textColor = .blue
        currentAverageLabel.text = "Current Average: N/A"
        view.addSubview(currentAverageLabel)
        
        previousAverageLabel = UILabel(frame: CGRect(x: 20, y: 120, width: view.frame.width - 40, height: 40))
        previousAverageLabel.textAlignment = .center
        previousAverageLabel.textColor = .blue
        previousAverageLabel.text = "Previous Average: N/A"
        view.addSubview(previousAverageLabel)
        
        differenceLabel = UILabel(frame: CGRect(x: 20, y: 160, width: view.frame.width - 40, height: 40))
        differenceLabel.textAlignment = .center
        differenceLabel.textColor = .blue
        differenceLabel.text = "Difference: N/A"
        view.addSubview(differenceLabel)
        
        // Set up the speed label
        speedLabel = UILabel(frame: CGRect(x: 20, y: 200, width: view.frame.width - 40, height: 40))
        speedLabel.textAlignment = .center
        speedLabel.textColor = .blue
        speedLabel.text = "Speed: N/A"
        view.addSubview(speedLabel)
        
        // Set up the time-to-impact label
        timeToImpactLabel = UILabel(frame: CGRect(x: 20, y: 240, width: view.frame.width - 40, height: 40))
        timeToImpactLabel.textAlignment = .center
        timeToImpactLabel.textColor = .blue
        timeToImpactLabel.text = "Time to Impact: N/A"
        view.addSubview(timeToImpactLabel)
        */
    }
    
    /*
    // Draw a red detection box overlay in the center of the screen
    func setupGridOverlay() {
        gridOverlayView = UIView(frame: self.view.frame)
        gridOverlayView.isUserInteractionEnabled = false
        gridOverlayView.backgroundColor = .clear

        let viewWidth = gridOverlayView.frame.width
        let viewHeight = gridOverlayView.frame.height

        let startX = viewWidth / 12
        let endX = 11 * (viewWidth / 12)
        let startY = viewHeight / 3
        let endY = 2 * (viewHeight / 3)

        let regionWidth = endX - startX
        let regionHeight = endY - startY

        let detectionRect = UIView(frame: CGRect(x: startX, y: startY, width: regionWidth, height: regionHeight))
        detectionRect.layer.borderWidth = 2
        detectionRect.layer.borderColor = UIColor.red.cgColor
        detectionRect.backgroundColor = .clear

        gridOverlayView.addSubview(detectionRect)
        view.addSubview(gridOverlayView)
    }
    */

    // Toggle the AR session on/off with the button
    @objc func toggleARSession() {
        if isARSessionRunning {
            sceneView.session.pause()
            startStopButton.setTitle("Start LiDAR", for: .normal)
            // statusLabel.text = "LiDAR Session Paused"
        } else {
            startARSession()
            startStopButton.setTitle("Stop LiDAR", for: .normal)
            // statusLabel.text = "LiDAR Session Running"
        }
        isARSessionRunning.toggle()
    }
    
    // Start the AR session with scene depth enabled
    func startARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
        sceneView.session.run(configuration)
    }
    
    // Called every time the AR session updates a frame
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        frameCounter += 1
        
        if frameCounter % 10 == 0, let sceneDepth = frame.sceneDepth {
            let depthData = sceneDepth.depthMap
            processMiddleDepthData(depthData)
        }
    }
    
    // Process the depth buffer to calculate speed and time-to-impact
    func processMiddleDepthData(_ depthData: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(depthData, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthData, .readOnly) }
        
        var depthValues: [Float32] = []
        var change: Float32 = 0
        var numChanges = 0
        var i = 0
        var difference: Float32 = 0
        var threatDistance: Float32 = 0

        let width = CVPixelBufferGetWidth(depthData)
        let height = CVPixelBufferGetHeight(depthData)

        guard let baseAddress = CVPixelBufferGetBaseAddress(depthData) else {
            return
        }

        let floatBuffer = baseAddress.assumingMemoryBound(to: Float32.self)

        let startX = width / 12
        let endX = 11 * (width / 12)
        let startY = height / 3
        let endY = 2 * (height / 3)

        for y in startY..<endY {
            for x in startX..<endX {
                let depth = floatBuffer[y * width + x]
                depthValues.append(depth)
            }
        }

        CVPixelBufferUnlockBaseAddress(depthData, .readOnly)
        
        // Step: Sort and get middle depth (median)
        let sortedDepths = depthValues.sorted()
        let middleIndex = sortedDepths.count / 2
        let middleDepth = sortedDepths[middleIndex]
        
        if threatDistances.count >= 10 && depthArray.count >= 1 {
            let prevDepthValues = depthArray.removeFirst()
            i = 0
            change = 0
            numChanges = 0
            threatDistance = 0
            
            for _ in startY..<endY {
                for _ in startX..<endX {
                    let currentDepth = depthValues[i]
                    let previousDepth = prevDepthValues[i]
                    let delta = currentDepth - previousDepth

                    // Only count pixels where current depth is less than the median (middleDepth)
                    if abs(delta) > 0.2 && (currentDepth < middleDepth) {
                        numChanges += 1
                        change += delta
                        threatDistance += currentDepth
                    }
                    i += 1
                }
            }

            if numChanges > 0 {
                difference = change / Float32(numChanges)
                threatDistance = threatDistance / Float32(numChanges)
            } else {
                difference = 0
                threatDistance = 0
            }

            // differenceLabel.text = String(format: "Difference: %.2f", difference)

            let timeInterval: Float32 = 10.0 / 20.0
            let speed = difference / timeInterval
            // speedLabel.text = String(format: "Speed: %.2f m/s", speed)

            // Calculate Time to Impact
            let timeToImpact: Float32
            if speed >= 0 {
                timeToImpact = 9999
            } else {
                timeToImpact = threatDistance / abs(speed)
            }
            // timeToImpactLabel.text = String(format: "Time to Impact: %.2f s", timeToImpact)

            if timeToImpact < ttiThreshold && speed < speedThreshold  {
                // differenceLabel.textColor = .red
                // timeToImpactLabel.textColor = .red
                playAlertSound()
            } else {
                // differenceLabel.textColor = .blue
                // timeToImpactLabel.textColor = .blue
            }
        }

        threatDistances.append(threatDistance)
        depthArray.append(depthValues)
        
        /*
        if let prev = threatDistances.dropLast().last {
            previousAverageLabel.text = String(format: "Previous Average: %.2f", prev)
        } else {
            previousAverageLabel.text = "Previous Average: N/A"
        }

        currentAverageLabel.text = String(format: "Current Average: %.2f", threatDistance)
         */
    }
}
