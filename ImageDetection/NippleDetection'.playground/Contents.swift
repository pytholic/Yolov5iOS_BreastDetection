import Accelerate
import CoreML
import Darwin
import PlaygroundSupport
import UIKit

// INPUT----------------------------------
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
var imgFileName = "1"
// ---------------------------------------

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

class Output: MLFeatureProvider {
    var featureNames: Set<String> = outputFeatureNames
    private let provider: MLFeatureProvider

    func featureValue(for featureName: String) -> MLFeatureValue? {
        for ofn in outputFeatureNames {
            if ofn == featureName {
                return provider.featureValue(for: featureName)
            }
        }

        return nil
    }

    init(featueres: MLFeatureProvider) {
        self.provider = featueres
    }

    func boundingBoxes() -> [BoundingBox] {
        var rects: [CGRect] = []
        var confs: [Double] = []
        var result: [BoundingBox] = []

        for featureName in featureNames {
            guard let feature = featureValue(for: featureName)?.multiArrayValue else {
                fatalError("\(#function): unknown error check mlmodel... \(featureName)")
            }

            var size = 0
            if featureName == confidenceFN {
                let pointer =
                    feature.dataPointer
                        .assumingMemoryBound(to: Double.self)
                size = feature.count

                for i in 0..<size {
                    confs.append(pointer[i])
                }
            }

            if featureName == coordFN {
                let pointer = feature.dataPointer
                    .assumingMemoryBound(to: Double.self)
                size = feature.count / 4

                for i in 0..<size {
                    rects.append(getBoundingBox(
                        pointer[4 * i],
                        pointer[4 * i + 1],
                        pointer[4 * i + 2],
                        pointer[4 * i + 3],
                        640.0,
                        640.0))
                }
            }
        }

        let size = confs.count
        for i in 0..<size {
            let bb = BoundingBox(classIndex: 1,
                                 score: Float(confs[i]),
                                 rect: rects[i])
            result.append(bb)
        }

        return result
    }

    func getBoundingBox(_ normalizedCx: Double,
                        _ normalizedCy: Double,
                        _ normalizedWidth: Double,
                        _ normalizedHeight: Double,
                        _ imageWidth: Double,
                        _ imageHeight: Double) -> CGRect
    {
        let cx = normalizedCx * imageWidth
        let cy = normalizedCy * imageHeight
        let width = normalizedWidth * imageWidth
        let height = normalizedHeight * imageHeight

        return CGRect(x: cx - width / 2.0,
                      y: cy - height / 2.0,
                      width: width,
                      height: height)
    }
}

func drawResultOnImage(image: UIImage, predictions: [BoundingBox]) -> UIImage? {
    let imageSize = image.size
    let scale: CGFloat = 0
    UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)

    image.draw(at: CGPoint.zero)

    let textColor = UIColor.green
    let textFont = UIFont(name: "Helvetica Bold", size: 12)!
    let textFontAttributes = [
        NSAttributedString.Key.font: textFont,
        NSAttributedString.Key.foregroundColor: textColor,
    ]

    for box in predictions {
        "\(round(box.score * 1000) / 1000)".draw(in: box.rect,
                                                 withAttributes: textFontAttributes)

        UIColor.blue.setFill()
        UIRectFrame(box.rect)
    }

    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage
}

let url = Bundle.main.url(forResource: modelname,
                          withExtension: "mlmodelc")!
let model = try! MLModel(contentsOf: url)

let imagepath = Bundle.main.path(forResource: imgFileName,
                                 ofType: "png")!

var image = UIImage(contentsOfFile: imagepath)!
image = image.resized(to: CGSize(width: 640, height: 640))
//image = normalize(image) // need not
//if flip { image = image.withHorizontallyFlippedOrientation() }

let input = Input(image: image)
do {
    // let options = MLPredictionOptions()
    // options.usesCPUOnly = true // Can't use GPU in the background

    let output = try model.prediction(from: input,
                                      options: MLPredictionOptions())

    let boxes = Output(featueres: output).boundingBoxes()
    for box in boxes {
        print(box)
    }

    image = drawResultOnImage(image: image, predictions: boxes)!

    // let imageView = UIImageView(image: image)

    PlaygroundPage.current.liveView = UIImageView(image: image)

} catch {
    print("\(error)")
}
