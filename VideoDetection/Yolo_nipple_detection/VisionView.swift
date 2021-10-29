//
//  VisionView.swift
//  Yolo_nipple_detection
//
//  Created by skia on 2021/10/27.
//

import Foundation
import UIKit

class VisionView: UIView {
    var rects: [CGRect] = []

    override func draw(_: CGRect) {
        // Get the Graphics Context
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        if rects.isEmpty { return }

        for rect in rects {            
            // Set the rectangle outerline-width
            context.setLineWidth(5.0)

            // Set the rectangle outerline-colour
            UIColor.red.set()

            // Create Rectangle
            context.addRect(rect)

            // Draw
            context.strokePath()
        }
    }
}
