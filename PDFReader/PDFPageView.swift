//
//  PDFPageView.swift
//  PDFReader
//
//  Created by Artem Kirillov on 24.02.17.
//  Copyright © 2017 Artem Kirillov. All rights reserved.
//

import UIKit

//// Delegate that is handle taps in current page
protocol PDFPageViewDelegate: class {
    
    func handleSingleTap(_ pdfPageView: PDFPageView)
}

/// An interactable page of a document
internal final class PDFPageView: UIScrollView {
    
    fileprivate var highResolutionView: HighResolutionPageView?
    fileprivate var scale: CGFloat
    
    /// Number of zoom levels possible when double tapping
    private let zoomLevels: CGFloat = 2
    
    /// View which contains all of our content
    fileprivate var contentView: UIView
    private let lowResolutionImageView: UIImageView
    
    /// Page reference being displayed
    private let pdfPage: CGPDFPage
    
    /// Current amount being zoomed
    private var zoomAmount: CGFloat?
    
    /// Delegate that is informed of important interaction events
    private weak var pageViewDelegate: PDFPageViewDelegate?
    
    /// Instantiates a scrollable page view
    ///
    /// - parameter frame:            frame of the view
    /// - parameter document:         document to be displayed
    /// - parameter pageNumber:       specific page number of the document to display
    /// - parameter backgroundImage:  background image of the page to display while rendering
    /// - parameter pageViewDelegate: delegate notified of any important interaction events
    ///
    /// - returns: a freshly initialized page view
    init(frame: CGRect, document: PDFDocument, pageNumber: Int, backgroundImage: UIImage?, pageViewDelegate: PDFPageViewDelegate?) {
        guard let pageRef = document.coreDocument.page(at: pageNumber) else { fatalError() }
        
        pdfPage = pageRef
        self.pageViewDelegate = pageViewDelegate
        
        // Determine the size of the PDF page.
        var pageRect = pdfPage.getBoxRect(.mediaBox)
        scale = min(frame.size.width/pageRect.size.width, frame.size.height/pageRect.size.height)
        pageRect.size = CGSize(width: pageRect.size.width * scale, height: pageRect.size.height * scale)
        
        if UIDevice.current.orientation.isLandscape && pageNumber != 1 && pageNumber != document.pageCount {
            pageRect.size = CGSize(width: pageRect.width * 2, height: pageRect.height)
        }
        
        guard !pageRect.isEmpty else { fatalError() }
        
        // Create our content view based on the size of the PDF page
        contentView = UIView(frame: pageRect)
        
        lowResolutionImageView = UIImageView(image: backgroundImage)
        lowResolutionImageView.frame = contentView.bounds
        
        if UIDevice.current.orientation.isLandscape && pageNumber != 1 && pageNumber != document.pageCount {
            if let rightPage = document.coreDocument.page(at: pageNumber + 1) {
                highResolutionView = HighResolutionPageView(frame: contentView.bounds, newPage: pdfPage, newPage2: rightPage)
            }
        } else {
            highResolutionView = HighResolutionPageView(frame: contentView.bounds, newPage: pdfPage)
        }
        
        super.init(frame: frame)
        
        let targetRect = bounds.insetBy(dx: 0, dy: 0)
        var zoomScale = zoomScaleThatFits(targetRect.size, source: bounds.size)
        
        minimumZoomScale = zoomScale // Set the minimum and maximum zoom scales
        maximumZoomScale = zoomScale * (zoomLevels * zoomLevels) // Max number of zoom levels
        zoomAmount = (maximumZoomScale - minimumZoomScale) / zoomLevels
        
        scale = 1
        if zoomScale > minimumZoomScale {
            zoomScale = minimumZoomScale
        }
        
        contentView.addSubview(lowResolutionImageView)
        contentView.sendSubview(toBack: lowResolutionImageView)
        if let tiledView = highResolutionView {
            contentView.addSubview(tiledView)
        }
        addSubview(contentView)
        
        let doubleTapOne = UITapGestureRecognizer(target: self, action:#selector(handleDoubleTap))
        doubleTapOne.numberOfTapsRequired = 2
        doubleTapOne.cancelsTouchesInView = false
        addGestureRecognizer(doubleTapOne)
        
        let singleTapOne = UITapGestureRecognizer(target: self, action:#selector(handleSingleTap))
        singleTapOne.numberOfTapsRequired = 1
        singleTapOne.cancelsTouchesInView = false
        addGestureRecognizer(singleTapOne)
        
        singleTapOne.require(toFail: doubleTapOne)
        
        bouncesZoom = false
        decelerationRate = UIScrollViewDecelerationRateFast
        delegate = self
        autoresizesSubviews = true
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Use layoutSubviews to center the PDF page in the view.
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Center the image as it becomes smaller than the size of the screen.
        let boundsSize = bounds.size
        var frameToCenter = contentView.frame
    
        // Center horizontally.
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
    
        // Center vertically.
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        contentView.frame = frameToCenter
    
        // To handle the interaction between CATiledLayer and high resolution screens, set the 
        // tiling view's contentScaleFactor to 1.0. If this step were omitted, the content scale factor 
        // would be 2.0 on high resolution screens, which would cause the CATiledLayer to ask for tiles of the wrong scale.
        highResolutionView?.contentScaleFactor = 1
    }
    
    /// Notifies the delegate that a single tap was performed
    func handleSingleTap(_ tapRecognizer: UITapGestureRecognizer) {
        pageViewDelegate?.handleSingleTap(self)
    }
    
    /// Zooms in and out accordingly, based on the current zoom level
    func handleDoubleTap(_ tapRecognizer: UITapGestureRecognizer) {
        var newScale = zoomScale * zoomLevels
        if newScale >= maximumZoomScale {
            newScale = minimumZoomScale
        }
        let zoomRect = zoomRectForScale(newScale, zoomPoint: tapRecognizer.location(in: tapRecognizer.view))
        zoom(to: zoomRect, animated: true)
    }
    
    
    /// Calculates the zoom scale given a target size and a source size
    ///
    /// - parameter target: size of the target rect
    /// - parameter source: size of the source rect
    ///
    /// - returns: the zoom scale of the target in relation to the source
    private func zoomScaleThatFits(_ target: CGSize, source: CGSize) -> CGFloat {
        let widthScale = target.width / source.width
        let heightScale = target.height / source.height
        return (widthScale < heightScale) ? widthScale : heightScale
    }
    
    /// Calculates the new zoom rect given a desired scale and a point to zoom on
    ///
    /// - parameter scale:     desired scale to zoom to
    /// - parameter zoomPoint: the reference point to zoom on
    ///
    /// - returns: a new zoom rect
    private func zoomRectForScale(_ scale: CGFloat, zoomPoint: CGPoint) -> CGRect {
        // Normalize current content size back to content scale of 1.0f
        let updatedContentSize = CGSize(width: contentSize.width/zoomScale, height: contentSize.height/zoomScale)
    
        let translatedZoomPoint = CGPoint(x: (zoomPoint.x / bounds.size.width) * updatedContentSize.width,
                                          y: (zoomPoint.y / bounds.size.height) * updatedContentSize.height)
    
        // derive the size of the region to zoom to
        let zoomSize = CGSize(width: bounds.size.width / scale, height: bounds.size.height / scale)
    
        // offset the zoom rect so the actual zoom point is in the middle of the rectangle
        return CGRect(x: translatedZoomPoint.x - zoomSize.width / 2.0,
                      y: translatedZoomPoint.y - zoomSize.height / 2.0,
                      width: zoomSize.width,
                      height: zoomSize.height)
    }
}

// MARK: - UIScrollViewDelegate
extension PDFPageView: UIScrollViewDelegate {
    /// A UIScrollView delegate callback, called when the user starts zooming.
    /// Return the content view
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    
    /// A UIScrollView delegate callback, called when the user stops zooming.
    /// When the user stops zooming, create a new Tiled
    /// PDFView based on the new zoom level and draw it on top of the old TiledPDFView.
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.scale = scale
    }
}
