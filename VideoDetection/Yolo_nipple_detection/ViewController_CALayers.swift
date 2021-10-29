//
//  ViewController.swift
//  Yolo_nipple_detection
//
//  Created by skia on 2021/10/22.
//

import AVFoundation
import UIKit
import Vision

var modelname = "yolov5-iOS"

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
   @IBOutlet var visionView: VisionView!
   @IBOutlet var timeLabel: UILabel?

   let captureSession = AVCaptureSession()

   // To display our datastream on our ViewController, what we need is previewLayer
   var previewLayer: CALayer!

   var captureDevice: AVCaptureDevice!

   let dataOutputQueue = DispatchQueue(
       label: "video data queue",
       qos: .userInitiated,
       attributes: [],
       autoreleaseFrequency: .workItem
   )

   private var framesDone = 0
   private var frameCapturingStartTime = CACurrentMediaTime()

   private var colors: [UIColor] = []
   private var boundingBoxes = [BoundingBox]()
   private var showFPS = ShowFps()
   
   let maxBoundingBoxes = 10

   override func viewDidLoad() {
       super.viewDidLoad()
       
       setUpBoundingBoxes()
       timeLabel?.text = ""
       
       // Do any additional setup after loading the view.
       prepareCamera()
   }

   // Function to calculate fps
   func measureFPS() -> Double {
       framesDone += 1
       let frameCapturingElapsed = CACurrentMediaTime() - frameCapturingStartTime
       let currentFPSDelivered = Double(framesDone) / frameCapturingElapsed
       if frameCapturingElapsed > 1 {
           framesDone = 0
           frameCapturingStartTime = CACurrentMediaTime()
       }
       return currentFPSDelivered
   }
   
   // Function to displace fps on the UI
   private func show_fps() {
       
       let fps = measureFPS()
       let labelFPS = String(format: "FPS %.2f", fps)
       let colorFPS = colors[1]
       
       showFPS.show_fps(labelfps: labelFPS, color: colorFPS)
       print(labelFPS)

   }
   
   // Function to show the predicted boxes and labels on the UI
   private func show(predictions: [VNRecognizedObjectObservation]) {

       // Transform the normalized boxes to input video coordinates
       let width = self.view.bounds.width
       let height = width * 9 / 16 //3 / 4
       let offsetY = (self.view.bounds.height - height) / 2
       let scale = CGAffineTransform.identity.scaledBy(x: width, y: height)
       let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -height - offsetY)

       //var rects = prediction.map { ($0 as! VNRecognizedObjectObservation).boundingBox }
       //rects = rects.map { $0.applying(scale).applying(transform) }

       for i in 0..<boundingBoxes.count {
           if i < predictions.count {
               
               let prediction = predictions[i]
               let box = prediction.boundingBox.applying(scale).applying(transform)
               
               //print(type(of: box))
               //self.setUpBoundingBoxes(boxes: [box])
               let color = colors[0]
               let label = String(format: "Breast %.2f", prediction.confidence * 100)
               boundingBoxes[i].show(frame: box, label: label, color: color)
               //boundingBoxes[i].show_fps(labelfps: labelFPS, color: color)
               
           } else {
               boundingBoxes[i].hide()
           }
       }
   }
   
   
   // INITIALIZATION
   
   func setUpBoundingBoxes() {
       for _ in 0..<maxBoundingBoxes {
         boundingBoxes.append(BoundingBox())
       }

       // Add two colors, one for my custom class, second for FPS display
       let color = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1)
       let colorFPS = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0)
       colors.append(color)
       colors.append(colorFPS)
     }

   func prepareCamera() {
       captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080 //vga640x480

       // Check available devices
       let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
           .devices

       captureDevice = availableDevices.first
       beginSession()
   }

   
   // Begin INFERENCE
   
   var yoloModel :VNCoreMLModel?
   func beginSession() {
       // Some problems can occur, so we use do-catch block
       do {
           let url = Bundle.main.url(forResource: modelname,
                                     withExtension: "mlmodelc")!
           yoloModel = try! VNCoreMLModel(for: MLModel(contentsOf: url))
           let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
           captureSession.addInput(captureDeviceInput)
       } catch {
           print(error.localizedDescription)
       }

       // Add video preview into the UI
       let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

       guard let connection = previewLayer.connection else {
           fatalError("fatal : preview layer connection is nil")
       }
       connection.videoOrientation = .landscapeRight

       self.previewLayer = previewLayer
       view.layer.addSublayer(self.previewLayer)
       self.previewLayer.frame = view.layer.frame

       // Add bounding boxes and fps to the preview layer, on top of the video preview
       for box in boundingBoxes {
           box.addToLayer(self.previewLayer)
       }
       
       showFPS.addToLayerFPS(self.previewLayer)

       // Start the session
       captureSession.startRunning()

       // Get access to the camera's frame layer
       let dataOutput = AVCaptureVideoDataOutput()

       // Add a video data output
       if captureSession.canAddOutput(dataOutput) {
           captureSession.addOutput(dataOutput)
           
           // Monitor the data output with a buffer delegate
           dataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
           dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)]
           dataOutput.alwaysDiscardsLateVideoFrames = true
       } else {
           print("Could not add video data output to the session!")
           captureSession.commitConfiguration()
           return
       }

       captureSession.commitConfiguration()
   }

   
   // This function will be called everytime camera captures a frame
   func captureOutput(_: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from _: AVCaptureConnection)
   {
       // Turn it into pixel buffer
       guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

       let request = VNCoreMLRequest(model: yoloModel!) { finishedReq, _ in

           guard let results = finishedReq.results as? [VNRecognizedObjectObservation]
               else { return }
           
           Task {
               await MainActor.run {

                   self.show_fps()
                   self.show(predictions: results)

               }
           }
       }

       // Execute the request
       try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
   }
}
