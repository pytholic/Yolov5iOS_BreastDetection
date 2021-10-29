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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        prepareCamera()
    }


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
    
    private func show_fps() {

        let fps = measureFPS()
        let labelFPS = String(format: "FPS %.2f", fps)
        print(labelFPS)

    }
    
    func prepareCamera() {
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080 //high //vga640x480

        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
            .devices

        captureDevice = availableDevices.first
        beginSession()
    }

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

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        guard let connection = previewLayer.connection else {
            fatalError("fatal : preview layer connection is nil")
        }
        connection.videoOrientation = .landscapeRight

        self.previewLayer = previewLayer
        //self.previewLayer.contentsGravity = .resize
        view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = view.layer.frame
        view.bringSubviewToFront(visionView)

        captureSession.startRunning()

        let dataOutput = AVCaptureVideoDataOutput()

        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
            // Add a video data output
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

    func captureOutput(_: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from _: AVCaptureConnection)
    {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNCoreMLRequest(model: yoloModel!) { finishedReq, _ in

            guard let results = finishedReq.results else { return }

            for observation in results where observation is VNRecognizedObjectObservation {
                guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                    continue
                }

                print(objectObservation)// .labels[0], objectObservation.confidence)
            }

            let width = self.view.bounds.width
            let height = width * 9 / 16 //3 / 4
            let offsetY = (self.view.bounds.height - height) / 2
            let scale = CGAffineTransform.identity.scaledBy(x: width, y: height)
            let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -height - offsetY)

            Task {
                await MainActor.run {
                    var rects = results.map { ($0 as! VNRecognizedObjectObservation).boundingBox }
                    //print(rects)


                    rects = rects.map { $0.applying(scale).applying(transform) }
                    //rects = rects.map{ VNImageRectForNormalizedRect($0, 1184, 834) }
                    //print(rects)
                    self.visionView.rects = rects
                    //print(self.visionView.rects)
                    self.visionView.setNeedsDisplay()
                    self.show_fps()
                }
            }

            // print(finishedReq.results)

//            guard let results = finishedReq.results as? [VNRecognizedObjectObservation] else { return }
//
//            // get first object from results
//            guard let firstObservation = results.first else { return }
//
//            print(firstObservation.labels[0], firstObservation.confidence)
        }

        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }


//    override func viewDidAppear(_ animated: Bool) {
//        let url = Bundle.main.url(forResource: modelname,
//                                  withExtension: "mlmodelc")!
//        let yoloModel = try! VNCoreMLModel(for: MLModel(contentsOf: url))
//
//    }
}

