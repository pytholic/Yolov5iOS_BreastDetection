# Description
**YOLO** is an object detection network. It can detect multiple objects in an image/video and puts `bounding boxes` around these objects. This project is for breast detection during surgery using **YOLOv5** model on **iOS**. The main goal of the project is to perform inference using `.coreml` model and displaying the result (*bounding boxes, labels and confidence*) on the video feed in real-time.

# Steps

## Setting up the environment
Create a project in **Xcode** on your **MacOS**. Create a new `Resource` group and plave your `.coreml` model inside it. That is all the setup you need to begin.

## Script details
Most of the code is written in `ViewController` script. I created two `ViewController` since I had the choice to use `CALayers` to view my prediction or I could use `UIView`.

In case of `ViewController_CALayers`, I added two additional scipt i.e. `DisplayBoxes.swift` and `ShowFPS.swift`. These scripts are sued to to display the predictiosn and current FPS on the video preview.

In case of `ViewController_UIView`, I added `VisionView.swift` to draw the boxes.

I also make use of Apple's new `MainActor.run` isntead of `Dispatchque.main.async` method to run tasks on  main thread.

## Results
Currently, I am getting around 27 fps on the new `Apple Ipad 11 pro (M1)` which is quite ok I think.

## Helpful links
Special thanks to [Ma-Dan](https://github.com/Ma-Dan/YOLOv3-CoreML) and [hollance](https://github.com/hollance/YOLO-CoreML-MPSNNGraph) for their repos.
