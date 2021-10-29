import Accelerate
import Vision
import Darwin
import PlaygroundSupport
import UIKit
import AVFoundation
//import AVKit


// INPUT
let confidenceThreshold = 0.7
let iouThreshold = 0.5

var modelname = "yolov5-iOS"

var imgFN = "image"
var ctFN = "confidenceThreshold"
var itFN = "iouThreshold"

var confidenceFN = "confidence"
var coordFN = "coordinates"

var inputFeatureNames: Set<String> = [imgFN, ctFN, itFN]
var outputFeatureNames: Set<String> = [confidenceFN, coordFN]

var flip = false
//var imgFileName = "1"


// CAPTURE VIDEO FEED
class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // here is where we start up  the camera
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .vga640x480
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return } // .video is for back camera
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        // "try?" returns an optional with no value in error case
        // can get error if we have no device
        
        // add input to your capture session
        captureSession.addInput(input)
        
        captureSession.startRunning()
    
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        // Getting acces to camera's frame layer
        // add some kind of camera data output monitor
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let url = Bundle.main.url(forResource: modelname,
                                  withExtension: "mlmodelc")!
        let model = try! MLModel(contentsOf: url)
        
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didDrop sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        print("Camera was able to capture a frame:", Date())
        
        guard let pixelBuffer: CVPixelBuffer =
                CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    
        guard let model = try? VNCoreMLModel(for: MLModel(contentsOf: url)) else { return }
        
        let request = VNCoreMLRequest(model: model)
        {
            (finishedReq, err) in
            
            // perhaps check the err
            print(finishedReq.results)
        }
        
        // We pass the above request to ImageRequestHandler via an array
        // Then it will execute the request
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                              options: [:]).perform([request])
        
    }
    
}





class Input: MLFeatureProvider {
    var featureNames: Set<String> = inputFeatureNames
    var image: UIImage

    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == imgFN {
            return MLFeatureValue(pixelBuffer: image.pixelBuffer()!)
        } else if featureName == confidenceFN {
            return MLFeatureValue(double: confidenceThreshold)
        } else if featureName == itFN {
            return MLFeatureValue(double: iouThreshold)
        }
        return nil
    }

    init(image: UIImage) {
        guard image.size.width == 640,
              image.size.height == 640
        else {
            fatalError("you should fix size")
        }

        self.image = image
    }
}
