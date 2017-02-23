//
//  HighResolutionPageView.swift
//  PDFReader
//
//  Created by Artem Kirillov on 24.02.17.
//  Copyright © 2017 Artem Kirillov. All rights reserved.
//

import UIKit
import QuartzCore

/// High resolution representation of a portion of a rendered pdf page
internal final class HighResolutionPageView: UIView {
    
    /// Pages of the PDF to be tiled
    private var leftPdfPage: CGPDFPage?
    private var rightPdfPage: CGPDFPage?
   
    /// Initializes a fresh tiled view
    ///
    /// - parameter frame:   desired frame of the tiled view
    /// - parameter scale:   scale factor
    /// - parameter newPage: new page representation
    init(frame: CGRect, newPage: CGPDFPage, newPage2: CGPDFPage? = nil) {
        leftPdfPage = newPage
        rightPdfPage = newPage2
        super.init(frame: frame)
        
        // levelsOfDetail and levelsOfDetailBias determine how the layer is
        // rendered at different zoom levels. This only matters while the view
        // is zooming, because once the the view is done zooming a new TiledPDFView
        // is created at the correct size and scale.
        let tiledLayer = self.layer as? CATiledLayer
        tiledLayer?.levelsOfDetail = 16
        tiledLayer?.levelsOfDetailBias = 15
        if rightPdfPage != nil {
            tiledLayer?.tileSize = CGSize(width: 2048, height: 1024)
        } else {
            tiledLayer?.tileSize = CGSize(width: 1024, height: 1024)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layerClass : AnyClass {
        return CATiledLayer.self
    }
    
    // Draw the CGPDFPage into the layer at the correct scale.
    override func draw(_ layer: CALayer, in con: CGContext) {
        guard let leftPdfPage = leftPdfPage else { return }
        // Fill the background with white.
        con.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        con.fill(bounds)
        
        // Flip the context so that the PDF page is rendered right side up.
        con.translateBy(x: 0, y: bounds.size.height)
        con.scaleBy(x: 1, y: -1)
        
        if let rightPage = rightPdfPage {
            let rect1 = CGRect(x: 0, y: 0, width: bounds.width / 2, height: bounds.height)
            con.saveGState()
            con.concatenate(leftPdfPage.getDrawingTransform(.cropBox, rect: rect1, rotate: 0, preserveAspectRatio: true))
            con.drawPDFPage(leftPdfPage)
            con.restoreGState()
            
            let rect2 = CGRect(x: bounds.width / 2, y: 0, width: bounds.width / 2, height: bounds.height)
            con.concatenate(rightPage.getDrawingTransform(.cropBox, rect: rect2, rotate: 0, preserveAspectRatio: true))
            con.drawPDFPage(rightPage)
            
        } else {
            let rect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
            con.concatenate(leftPdfPage.getDrawingTransform(.cropBox, rect: rect, rotate: 0, preserveAspectRatio: true))
            con.drawPDFPage(leftPdfPage)
        }
    }
    
    // Stops drawLayer
    deinit {
        leftPdfPage = nil
        rightPdfPage = nil
        layer.contents = nil
        layer.delegate = nil
        layer.removeFromSuperlayer()
    }
}
