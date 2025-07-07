import UIKit
import ARKit

class ARViewController: UIViewController, ARSessionDelegate {
    
    var sceneView: ARSCNView!
    var startStopButton: UIButton!
    var statusLabel: UILabel!
    var currentAverageLabel: UILabel!
    var previousAverageLabel: UILabel!
    var differenceLabel: UILabel!
    var speedLabel: UILabel!
    var timeToImpactLabel: UILabel!
    var isARSessionRunning: Bool = false
    var gridOverlayView: UIView!
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
        
        sceneView = ARSCNView(frame: self.view.frame)
        self.view.addSubview(sceneView)
        
        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) else {
            fatalError("LiDAR not supported on this device.")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
        sceneView.session.delegate = self
        
        setupUI()
        setupGridOverlay()
        setupTTISlider()
        setupSpeedSlider()
        loadSound()
    }
    
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
        
        func playAlertSound() {
            audioPlayer?.play()
        }

    // Setup for Speed
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

    @objc func speedSliderChanged(sender: UISlider) {
        speedThreshold = sender.value
        slabel.text = String(format: "Speed Threshold: %.2f m/s", speedThreshold)
    }
    
    func setupTTISlider() {
        ttilabel = UILabel(frame: CGRect(x: 20, y: 380, width: view.frame.width - 40, height: 40))
        ttilabel.textAlignment = .center
        ttilabel.textColor = .blue
        ttilabel.text = "TTI Threshold: \(ttiThreshold) s"
        view.addSubview(ttilabel)
        
        ttiSlider = UISlider(frame: CGRect(x: 20, y: 420, width: view.frame.width - 40, height: 40))
        ttiSlider.minimumValue = 0
        ttiSlider.maximumValue = 6
        ttiSlider.value = ttiThreshold
        ttiSlider.addTarget(self, action: #selector(ttiSliderChanged), for: .valueChanged)
        view.addSubview(ttiSlider)
    }

    @objc func ttiSliderChanged(sender: UISlider) {
        ttiThreshold = sender.value
        ttilabel.text = String(format: "TTI Threshold: %.2f", ttiThreshold)
    }

    
    func setupUI() {
        startStopButton = UIButton(type: .system)
        startStopButton.setTitle("Start AR", for: .normal)
        startStopButton.addTarget(self, action: #selector(toggleARSession), for: .touchUpInside)
        startStopButton.frame = CGRect(x: 20, y: view.frame.height - 60, width: 100, height: 40)
        startStopButton.backgroundColor = .white
        startStopButton.layer.cornerRadius = 5
        startStopButton.layer.borderWidth = 1
        startStopButton.layer.borderColor = UIColor.black.cgColor
        view.addSubview(startStopButton)
        
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
    }
    
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

    
    @objc func toggleARSession() {
        if isARSessionRunning {
            sceneView.session.pause()
            startStopButton.setTitle("Start AR", for: .normal)
            statusLabel.text = "AR Session Paused"
        } else {
            startARSession()
            startStopButton.setTitle("Stop AR", for: .normal)
            statusLabel.text = "AR Session Running"
        }
        isARSessionRunning.toggle()
    }
    
    func startARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
        sceneView.session.run(configuration)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        frameCounter += 1
        
        if frameCounter % 10 == 0, let sceneDepth = frame.sceneDepth {
            let depthData = sceneDepth.depthMap
            processMiddleDepthData(depthData)
        }
    }

    
    func processMiddleDepthData(_ depthData: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(depthData, .readOnly)
        
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
                    if abs(delta) > 0.05 {
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

            differenceLabel.text = String(format: "Difference: %.2f", difference)

            // Calculate Speed
            let timeInterval: Float32 = 10.0 / 20.0 // 10帧，每秒20帧
            let speed = difference / timeInterval
            speedLabel.text = String(format: "Speed: %.2f m/s", speed)

            // Calculate Time to Impact
            let timeToImpact: Float32
            if speed >= 0 {
                timeToImpact = 9999
            } else {
                timeToImpact = threatDistance / abs(speed)
            }
            timeToImpactLabel.text = String(format: "Time to Impact: %.2f s", timeToImpact)

            if timeToImpact < ttiThreshold && speed < speedThreshold  {
                differenceLabel.textColor = .red
                timeToImpactLabel.textColor = .red
                playAlertSound()
            } else {
                differenceLabel.textColor = .blue
                timeToImpactLabel.textColor = .blue
            }
        }

        threatDistances.append(threatDistance)
        depthArray.append(depthValues)

        if let prev = threatDistances.dropLast().last {
            previousAverageLabel.text = String(format: "Previous Average: %.2f", prev)
        } else {
            previousAverageLabel.text = "Previous Average: N/A"
        }

        currentAverageLabel.text = String(format: "Current Average: %.2f", threatDistance)
    }
}
