//
//  ViewController.swift
//  IOS-Swift-ARkitFaceTrackingNose01
//
//  Created by Pooya on 2018-11-27.
//  Copyright © 2018 Soonin. All rights reserved.
//

import UIKit
import ARKit
import ReplayKit
import Lottie
import Photos
import AVKit
import Alamofire
class ViewController: UIViewController , RPScreenRecorderDelegate {
    private var progressView: UIProgressView!
    @IBOutlet var sceneView: ARSCNView!
    var recodButton: RecordButton?
    private var emotionLabel: UILabel!
    private var lastProcessedTime: TimeInterval = 0
    private let processingInterval: TimeInterval = 0.5
    let recorder = RPScreenRecorder.shared()
    private var recordingURL: URL?

    //let noseOptions = ["👃", "🐽", "💧", " "]
    let eyeOptions = ["👁", "🌕", "🌟", "🔥", "⚽️", "🔎", " "]
    let mouthOptions = ["👄", "👅", "❤️", " "]
    let hatOptions = ["🎓", "🎩", "🧢", "⛑", "👒", " "]
    
//    let noseOptions = ["nose01", "🐽", "💧", " "]
    
//    let features = ["nose"]
//    let featureIndices = [[6]]
    let features = ["nose", "leftEye", "rightEye", "mouth", "hat"]
    let featureIndices = [[6], [1064], [42], [24, 25], [20]]
    
    private var currentEmotion: Emotion = .neutral
    let noseOptions = ["nose01", "nose02", "nose03", "nose04", "nose05", "nose06", "nose07", "nose08", "nose09"]
    private var emotionAnimationView: LottieAnimationView?
        private let animationNames: [Emotion: String] = [
            .happy: "Animation - happy",
            .sad: "Animation - sad",
            .angry: "Animation - 1734702428155",
            .surprised: "Animation - surprised",
            .neutral: "Animation - 1734702428155"
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let videoListVC = VideoListViewController()
//        navigationController?.pushViewController(videoListVC, animated: true)
        sceneView.delegate = self
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            self.sceneView.session.run(ARWorldTrackingConfiguration())
//        }
        
        setupEmotionLabel()
        setupRecordButton()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let configuratio = ARFaceTrackingConfiguration()
            self.sceneView.session.run(configuratio)
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
        emotionAnimationView?.removeFromSuperview()
        emotionAnimationView = nil
        sceneView.alpha = 1.0
    }
    private func setupProgressView() {
            progressView = UIProgressView(progressViewStyle: .default)
            progressView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(progressView)
            
            NSLayoutConstraint.activate([
                progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                progressView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
                progressView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
            ])
            
            progressView.isHidden = true
        }
    private func setupEmotionLabel() {
            emotionLabel = UILabel()
            emotionLabel.translatesAutoresizingMaskIntoConstraints = false
            emotionLabel.textAlignment = .center
            emotionLabel.textColor = .white
            emotionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            emotionLabel.layer.cornerRadius = 10
            emotionLabel.layer.masksToBounds = true
            emotionLabel.font = .systemFont(ofSize: 20, weight: .bold)
            view.addSubview(emotionLabel)
            
            NSLayoutConstraint.activate([
                emotionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
                emotionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                emotionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
                emotionLabel.heightAnchor.constraint(equalToConstant: 40)
            ])
        }

    private func updateNoseForEmotion(_ emotion: Emotion) {
            guard let node = sceneView.scene.rootNode.childNode(withName: "nose", recursively: true) as? Nose3DNode else {
                return
            }
            
            // You can modify the nose appearance based on emotion
            switch emotion {
            case .happy:
                node.scale = SCNVector3(0.06, 0.06, 0.06)  // Make nose slightly bigger when happy
            case .sad:
                node.scale = SCNVector3(0.04, 0.04, 0.04)  // Make nose slightly smaller when sad
            default:
                node.scale = SCNVector3(0.05, 0.05, 0.05)  // Default size
            }
        }
    private func setupEmotionAnimation(for emotion: Emotion) {
        // Remove existing animation if any
        emotionAnimationView?.removeFromSuperview()
        
        guard let animationName = animationNames[emotion] else { return }
        
        // Create new animation
        emotionAnimationView = .init(name: animationName)
        guard let animationView = emotionAnimationView else { return }
        
        // Configure animation
        animationView.frame = CGRect(x: view.bounds.width/2  - 50, y: 10, width: 100, height: 100)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore
        
        // Add to view behind AR scene
        view.insertSubview(animationView, belowSubview: sceneView)
        
        // Make sceneView partially transparent to see animation
        sceneView.alpha = 0.8
        
        // Play animation
        animationView.play()
    }
    func updateNoseForEmotion(_ emotion: Emotion, anchor: ARFaceAnchor) {
        guard let node = sceneView.scene.rootNode.childNode(withName: "nose", recursively: true) as? Nose3DNode else {
            return
        }
        
        switch emotion {
        case .happy:
            setupEmotionAnimation(for: .happy)
            node.scale = SCNVector3(0.06, 0.06, 0.06)
            // Add bouncing animation
            let scaleUp = SCNAction.scale(to: 0.07, duration: 0.2)
            let scaleDown = SCNAction.scale(to: 0.06, duration: 0.2)
            let sequence = SCNAction.sequence([scaleUp, scaleDown])
            node.runAction(SCNAction.repeatForever(sequence))
            
        case .angry:
            setupEmotionAnimation(for: .angry)
            node.scale = SCNVector3(0.05, 0.05, 0.05)
            // Add shaking and color animation
            let shakeLeft = SCNAction.moveBy(x: -0.01, y: 0, z: 0, duration: 0.1)
            let shakeRight = SCNAction.moveBy(x: 0.01, y: 0, z: 0, duration: 0.1)
            let colorRed = SCNAction.customAction(duration: 0.1) { node, _ in
                node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            }
            let colorNormal = SCNAction.customAction(duration: 0.1) { node, _ in
                node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            }
            let sequence = SCNAction.sequence([shakeLeft, shakeRight, colorRed, colorNormal])
            node.runAction(SCNAction.repeatForever(sequence))
            
        case .surprised:
            setupEmotionAnimation(for: .surprised)
            node.scale = SCNVector3(0.05, 0.05, 0.05)
            // Add jump animation
            let jumpUp = SCNAction.moveBy(x: 0, y: 0.02, z: 0, duration: 0.2)
            let jumpDown = SCNAction.moveBy(x: 0, y: -0.02, z: 0, duration: 0.2)
            let sequence = SCNAction.sequence([jumpUp, jumpDown])
            node.runAction(SCNAction.repeatForever(sequence))
            
        case .sad:
            setupEmotionAnimation(for: .sad)
            node.scale = SCNVector3(0.04, 0.04, 0.04)
            // Add drooping animation
            let droopDown = SCNAction.rotateBy(x: 0.2, y: 0, z: 0, duration: 0.5)
            let droopUp = SCNAction.rotateBy(x: -0.2, y: 0, z: 0, duration: 0.5)
            let sequence = SCNAction.sequence([droopDown, droopUp])
            node.runAction(SCNAction.repeatForever(sequence))
            
        default:
            // Reset everything
            emotionAnimationView?.removeFromSuperview()
            emotionAnimationView = nil
            sceneView.alpha = 1.0
            node.removeAllActions()
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            node.scale = SCNVector3(0.05, 0.05, 0.05)
        }
    }

    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: sceneView)
        let results = sceneView.hitTest(location, options: nil)
        if let result = results.first,
            let node = result.node as? Nose3DNode {
//            node.next()
        }
//        startRecording(UIButton())
//        Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(stopRecording), userInfo: nil, repeats: false)
    }
    
    @IBAction func startRecording(_ sender: UIButton) {
        guard recorder.isAvailable else {
                    printContent("Screen recording is not available")
                    return
                }
                
        let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
                let fileName = "Recording_\(dateFormatter.string(from: Date())).mp4"
                
                // Use temporary directory instead of documents directory
                let tempDir = FileManager.default.temporaryDirectory
                recordingURL = tempDir.appendingPathComponent(fileName)
                
            recorder.isMicrophoneEnabled = true
        
            recorder.startRecording { error in
                DispatchQueue.main.async(execute: {
                    self.recodButton?.isHidden = true
                    self.navigationController?.navigationBar.isHidden = true
                })
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10, execute: {
                    self.navigationController?.navigationBar.isHidden = false
                    self.recodButton?.stopRecording()
                })

                if let error = error {
                    print("Recording failed: \(error.localizedDescription)")
                } else {
                    print("Recording started.")
                }
            }
        }
    @IBAction func stopRecording(_ sender: UIButton) {
            recorder.stopRecording { previewController, error in
                if let error = error {
                    print("Stopping failed: \(error.localizedDescription)")
                    self.showAlert(title: "Error", message: "Failed to stop recording")
                } else if let previewController = previewController {
                    previewController.previewControllerDelegate = self
                    previewController.modalPresentationStyle = .overFullScreen
                    self.present(previewController, animated: true, completion: nil)
                    self.handleRecordedVideo(previewController: previewController)
                }
            }
        }
    private func handleRecordedVideo(previewController: RPPreviewViewController) {
        guard let outputURL = previewController.value(forKey: "_movieURL") as? URL else {
            print("Failed to retrieve the recorded video URL")
            return
        }
        PHPhotoLibrary.requestAuthorization { status in
                        if status == .authorized {
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetCreationRequest.forAsset().addResource(with: .video, fileURL: outputURL, options: nil)
                            }) { success, error in
                                if success {
                                    print("Video saved to Photos library successfully")
                                    
                                    // After successful save to Photos, try to save to temp directory and upload
                                    DispatchQueue.main.async {
                                        do {
                                            // Copy to temporary directory
                                            if let recordingURL = self.recordingURL {
                                                let videoData = try Data(contentsOf: outputURL)
                                                try videoData.write(to: recordingURL)
                                                print("Video saved successfully to temp directory: \(recordingURL.path)")
                                                
                                                // Upload the video
                                                self.uploadVideo(fileURL: recordingURL)
                                            }
                                        } catch {
                                            print("Error handling video file: \(error.localizedDescription)")
                                            self.showAlert(title: "Error", message: "Failed to process video")
                                        }
                                    }
                                } else {
                                    print("Error saving to Photos library: \(String(describing: error))")
                                    self.showAlert(title: "Error", message: "Failed to save video to Photos")
                                }
                            }
                        } else {
                            print("Photos library permission denied")
                            self.showAlert(title: "Error", message: "Photos library access denied")
                        }
                    }
                    
//        uploadVideo(fileURL: outputURL)
//        playVideo(at: outputURL)
//        // Create a unique filename with timestamp
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
//        let fileName = "Recording_\(dateFormatter.string(from: Date())).mp4"
//        DispatchQueue.main.async {
//            self.saveToDocuments(from: outputURL, withFileName: fileName)
//        }
//        // First save to Photos Library
//        PHPhotoLibrary.requestAuthorization { status in
//            if status == .authorized {
//                PHPhotoLibrary.shared().performChanges({
//                    PHAssetCreationRequest.forAsset().addResource(with: .video, fileURL: outputURL, options: nil)
//                }) { success, error in
//                    if success {
//                        print("Video saved to Photos successfully")
//                        
//                        // After saving to Photos, try to save to documents
//                        
//                    } else {
//                        print("Error saving to Photos: \(String(describing: error))")
//                        DispatchQueue.main.async {
//                            self.showAlert(title: "Error", message: "Failed to save to Photos")
//                        }
//                    }
//                }
//            }
//        }
        
        // Dismiss the preview controller
//        previewController.dismiss(animated: true)
    }


    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }


    // Function to get list of saved videos
    func getSavedVideos() -> [URL] {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: documentsPath,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            return fileURLs.filter { $0.pathExtension.lowercased() == "mp4" }
        } catch {
            print("Error accessing saved videos: \(error)")
            return []
        }
    }

    func playVideo(at url: URL) {
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        present(playerViewController, animated: true) {
            player.play()
        }
    }
    
    func updateFeatures3D(for node: SCNNode, using anchor: ARFaceAnchor) {
//        print(featureIndices)
        for (feature, indices) in zip(features, featureIndices) {
            let child = node.childNode(withName: feature, recursively: false) as? Nose3DNode
            let vertices = indices.map { anchor.geometry.vertices[$0] }
            child?.updatePosition(for: vertices)
        }
    }
    
    func updateFeatures2D(for node: SCNNode, using anchor: ARFaceAnchor) {
//        print(featureIndices)
        for (feature, indices) in zip(features, featureIndices) {
            let child = node.childNode(withName: feature, recursively: false) as? EmojiNode
            let vertices = indices.map { anchor.geometry.vertices[$0] }
            child?.updatePosition(for: vertices)
        }
    }
    
    
}
extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let device: MTLDevice!
        device = MTLCreateSystemDefaultDevice()
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            return nil
        }
        
        let faceGeometry = ARSCNFaceGeometry(device: device)
        
        let node = SCNNode(geometry: faceGeometry)
        node.geometry?.firstMaterial?.transparency = 0.0
//        node.geometry?.firstMaterial?.fillMode = .lines
        
//        let noseNode = EmojiNode(with: noseOptions)
//        noseNode.name = "nose"
//        node.addChildNode(noseNode)
        
        let leftEyeNode = EmojiNode(with: eyeOptions)
        leftEyeNode.name = "leftEye"
        leftEyeNode.rotation = SCNVector4(0, 1, 0, GLKMathDegreesToRadians(180.0))
        node.addChildNode(leftEyeNode)
        
        let rightEyeNode = EmojiNode(with: eyeOptions)
        rightEyeNode.name = "rightEye"
        node.addChildNode(rightEyeNode)
        
//        let mouthNode = EmojiNode(with: mouthOptions)
//        mouthNode.name = "mouth"
//        node.addChildNode(mouthNode)
        
//        let hatNode = EmojiNode(with: hatOptions)
//        hatNode.name = "hat"
//        node.addChildNode(hatNode)
        
        
        let noseNode3D = Nose3DNode(with: [""])//FaceNode(with: noseOptions)
        noseNode3D.name = "nose"
        noseNode3D.position = SCNVector3(0, 0, 0) // Adjust this to position the 3D nose correctly
        noseNode3D.scale = SCNVector3(0.05, 0.05, 0.05)
        node.addChildNode(noseNode3D)
        
        updateFeatures3D(for: node, using: faceAnchor)
        updateFeatures2D(for: node, using: faceAnchor)

        return node
    }
    
    func renderer(
            _ renderer: SCNSceneRenderer,
            didUpdate node: SCNNode,
            for anchor: ARAnchor) {
                guard let faceAnchor = anchor as? ARFaceAnchor,
                      let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
                    return
                }
                
                // Detect emotion
                let detectedEmotion = EmotionDetector.detectEmotion(from: faceAnchor)
                if detectedEmotion != currentEmotion {
                    currentEmotion = detectedEmotion
                    DispatchQueue.main.async {
                        self.emotionLabel.text = detectedEmotion.description
                        self.updateNoseForEmotion(detectedEmotion, anchor: faceAnchor)
                    }
                }
                
                faceGeometry.update(from: faceAnchor.geometry)
                
                updateFeatures3D(for: node, using: faceAnchor)
                updateFeatures2D(for: node, using: faceAnchor)
            }
    
    
}

extension ViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.dismiss(animated: true, completion: {
            self.getAndProcessLastVideo()
        })
    }
}
enum Emotion {
    case happy
    case sad
    case angry
    case surprised
    case neutral
    
    var description: String {
        switch self {
        case .happy: return "Happy"
        case .sad: return "Sad"
        case .angry: return "Angry"
        case .surprised: return "Surprised"
        case .neutral: return "Neutral"
        }
    }
}

class EmotionDetector {
    static func detectEmotion(from anchor: ARFaceAnchor) -> Emotion {
        let mouthSmileLeft = anchor.blendShapes[.mouthSmileLeft]?.floatValue ?? 0.0
        let mouthSmileRight = anchor.blendShapes[.mouthSmileRight]?.floatValue ?? 0.0
        let innerBrowRaiser = anchor.blendShapes[.browInnerUp]?.floatValue ?? 0.0
        let browDownLeft = anchor.blendShapes[.browDownLeft]?.floatValue ?? 0.0
        let browDownRight = anchor.blendShapes[.browDownRight]?.floatValue ?? 0.0
        let jawOpen = anchor.blendShapes[.jawOpen]?.floatValue ?? 0.0
        let mouthFrownLeft = anchor.blendShapes[.mouthFrownLeft]?.floatValue ?? 0.0
        let mouthFrownRight = anchor.blendShapes[.mouthFrownRight]?.floatValue ?? 0.0
        let noseSneerLeft = anchor.blendShapes[.noseSneerLeft]?.floatValue ?? 0.0
        let noseSneerRight = anchor.blendShapes[.noseSneerRight]?.floatValue ?? 0.0
        let cheekPuff = anchor.blendShapes[.cheekPuff]?.floatValue ?? 0.0
        
        let smileValue = (mouthSmileLeft + mouthSmileRight) / 2.0
        let frownValue = (mouthFrownLeft + mouthFrownRight) / 2.0
        let browDownValue = (browDownLeft + browDownRight) / 2.0
        let noseSneerValue = (noseSneerLeft + noseSneerRight) / 2.0
        
        // Enhanced angry emotion detection
        if browDownValue > 0.4 &&
           (jawOpen > 0.3 || noseSneerValue > 0.3) &&
           cheekPuff > 0.2 {
            return .angry
        }
        
        // Other emotions
        if smileValue > 0.5 {
            return .happy
        } else if frownValue > 0.3 || browDownValue > 0.3 {
            return .sad
        } else if jawOpen > 0.5 && innerBrowRaiser > 0.3 {
            return .surprised
        }
        
        return .neutral
    }
}

extension ViewController {
    private func uploadVideo(fileURL: URL) {
        
        let uploadURL = baseURL + "/api/upload-video"
        let parameters: [String: String] = [
            "uploadById": "1",
            "path": "558-137190717_tiny.mp4",
            "originalName": fileURL.lastPathComponent,
            "quality": "Low"
        ]
        
        AF.upload(multipartFormData: { multipartFormData in
            // Add the video file
            do {
                let videoData = try Data(contentsOf: fileURL)
                multipartFormData.append(fileURL,
                                         withName: "video",
                                         fileName: fileURL.lastPathComponent,
                                         mimeType: "video/mp4")
            } catch {
                print("Error preparing video data: \(error)")
            }
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: fileURL.path) {
                print("File exists")
            } else {
                print("File does not exist")
            }
            // Add other form fields
            for (key, value) in parameters {
                multipartFormData.append(Data(value.utf8), withName: key)
            }
        }, to: uploadURL)
        .uploadProgress { progress in
            SwiftLoader.show(title: "\((progress.fractionCompleted * 100).rounded())%", animated: true)
            print("Upload Progress: \(progress.fractionCompleted * 100)%")
        }
        .response { response in
            SwiftLoader.hide()
            switch response.result {
            case .success(let data):
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Server Response: \(responseString)")
                    self.deleteLastVideo { _, _ in
                        self.navigationController?.popViewController(animated: true)
                    }
                    
                } else {
                    print("Upload succeeded but no response data")
                }
            case .failure(let error):
                print("Upload failed: \(error)")
            }
        }
    }


    // Helper function to update upload progress
    private func updateUploadProgress(_ progress: Double) {
        progressView.isHidden = false
                progressView.progress = Float(progress)
                
                if progress >= 1.0 {
                    // Hide progress view after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.progressView.isHidden = true
                        self.progressView.progress = 0
                    }
                }
    }
}
extension ViewController {
    func setupRecordButton() {
        let buttonSize: CGFloat = 80
        let button = RecordButton(frame: CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize))
        recodButton = button
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            button.widthAnchor.constraint(equalToConstant: buttonSize),
            button.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
        
        // Add long press gesture
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0 // For immediate response
        button.addGestureRecognizer(longPress)
        button.recordStarted = { [weak self] button in
            guard (self != nil) else {
                return print("Record button is nil")
            }
            self?.startRecording(UIButton())
        }
        button.recordFinished = {[weak self] button in
            guard (self != nil) else {
                return print("Record button is nil")
            }
            self?.stopRecording(UIButton())
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let recordButton = gesture.view as? RecordButton else { return }
        
        switch gesture.state {
        case .began:
            print("Recording started")
            recordButton.startRecording()
            // Add any recording logic here
            
        case .ended, .cancelled:
            print("Recording stopped")
//            recordButton.stopRecording()
            // Add stop recording logic here
            
        default:
            break
        }
    }
}
extension ViewController {
    func fetchLastSavedVideo(completion: @escaping (URL?) -> Void) {
        // Request permission to access Photos
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photos access denied")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Create fetch options
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            options.fetchLimit = 1
            
            // Fetch the most recent video
            let result = PHAsset.fetchAssets(with: .video, options: options)
            
            guard let asset = result.firstObject else {
                print("No videos found")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Create video request options
            let videoRequestOptions = PHVideoRequestOptions()
            videoRequestOptions.version = .original
            videoRequestOptions.deliveryMode = .highQualityFormat
            videoRequestOptions.isNetworkAccessAllowed = true
            
            // Request video asset
            PHImageManager.default().requestAVAsset(forVideo: asset, options: videoRequestOptions) { (avAsset, _, _) in
                guard let urlAsset = avAsset as? AVURLAsset else {
                    print("Could not get URL asset")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                
                // Return the URL of the video
                DispatchQueue.main.async {
                    completion(urlAsset.url)
                }
            }
        }
    }
    
    // Example usage function
    func getAndProcessLastVideo() {
        fetchLastSavedVideo { [weak self] videoURL in
            guard let videoURL = videoURL else {
                print("No video URL retrieved")
                return
            }
            
            // Here you can use the video URL
            print("Last saved video URL: \(videoURL)")
            
            // Example: Upload the video
            self?.uploadVideo(fileURL: videoURL)
        
        }
    }
    
    // Helper function to show alert
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Photos Access Required",
            message: "Please enable access to Photos in Settings to fetch your videos.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}
extension ViewController {
    func deleteLastVideo(completion: @escaping (Bool, Error?) -> Void) {
        // Request permission to access Photos
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photos access denied")
                DispatchQueue.main.async {
                    completion(false, NSError(domain: "", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "Photos access denied"]))
                }
                return
            }
            
            // Create fetch options
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            options.fetchLimit = 1
            
            // Fetch the most recent video
            let result = PHAsset.fetchAssets(with: .video, options: options)
            
            guard let asset = result.firstObject else {
                print("No videos found")
                DispatchQueue.main.async {
                    completion(false, NSError(domain: "", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "No videos found"]))
                }
                return
            }
            
            // Delete the video
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets([asset] as NSArray)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("Successfully deleted last video")
                        completion(true, nil)
                    } else {
                        print("Error deleting video: \(String(describing: error))")
                        completion(false, error)
                    }
                }
            }
        }
    }
    
    // Example usage function
    func deleteLastVideoWithConfirmation() {
        let alert = UIAlertController(
            title: "Delete Last Video",
            message: "Are you sure you want to delete the most recent video?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteLastVideo { success, error in
                DispatchQueue.main.async {
                    if success {
                        self?.showAlert(title: "Success", message: "Video deleted successfully")
                    } else {
                        self?.showAlert(title: "Error",
                                      message: error?.localizedDescription ?? "Failed to delete video")
                    }
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}
