//
//  Display.swift
//  Yolo_nipple_detection
//
//  Created by skia on 2021/10/28.
//

import Foundation
import UIKit

class ShowFps {
    
    private let textLayerFPS: CATextLayer

    init() {
        
        textLayerFPS = CATextLayer()
        textLayerFPS.foregroundColor = UIColor.yellow.cgColor
        textLayerFPS.isHidden = true
        textLayerFPS.contentsScale = UIScreen.main.scale
        textLayerFPS.fontSize = 30
        textLayerFPS.font = UIFont(name: "Avenir", size: textLayerFPS.fontSize)
        textLayerFPS.alignmentMode = CATextLayerAlignmentMode.center
        
    }
    
    func addToLayerFPS(_ parent: CALayer) {
        parent.addSublayer(textLayerFPS)
    }
    
    
    func show_fps(labelfps: String, color: UIColor) {

        CATransaction.setDisableActions(true)

        textLayerFPS.string = labelfps
        textLayerFPS.backgroundColor = color.cgColor
        textLayerFPS.isHidden = false

        let attributes = [ NSAttributedString.Key.font: textLayerFPS.font as Any ]

        let textRectFPS = labelfps.boundingRect(with: CGSize(width: 700, height: 200),
                                          options: .truncatesLastVisibleLine,
                                          attributes: attributes, context: nil)

        let textSizeFPS = CGSize(width: textRectFPS.width + 24, height: textRectFPS.height + 12)
        let textOriginFPS = CGPoint(x: 50, y: 50)
        textLayerFPS.frame = CGRect(origin: textOriginFPS, size: textSizeFPS)
    }
    
    func hideFPS() {
        textLayerFPS.isHidden = true
    }
    

}

