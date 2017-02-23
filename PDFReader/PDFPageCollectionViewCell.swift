//
//  PDFPageCollectionViewCell.swift
//  PDFReader
//
//  Created by Artem Kirillov on 24.02.17.
//  Copyright © 2017 Artem Kirillov. All rights reserved.
//

import UIKit

/// Delegate that is handle taps in current cell
protocol PDFPageCollectionViewCellDelegate: class {
    func handleSingleTap(_ cell: PDFPageCollectionViewCell, pdfPageView: PDFPageView)
}

internal final class PDFPageCollectionViewCell: UICollectionViewCell {
    
    var pageIndex: Int?
    var pageView: PDFPageView? {
        didSet {
            subviews.forEach{ $0.removeFromSuperview() }
            if let pageView = pageView {
                addSubview(pageView)
            }
        }
    }
    
    fileprivate weak var delegate: PDFPageCollectionViewCellDelegate?
    
    
    /// Customizes and sets up the cell to be ready to be displayed (in landscape and portrait modes)
    ///
    /// - parameter indexPathRow:                   page index of the document to be displayed
    /// - parameter document:                       document to be displayed
    /// - parameter pageCollectionViewCellDelegate: delegate informed of important events
    func setup(_ indexPathRow: Int, document: PDFDocument, pageCollectionViewCellDelegate: PDFPageCollectionViewCellDelegate?) {
        
        delegate = pageCollectionViewCellDelegate
        pageIndex = indexPathRow
        
        if indexPathRow == 0 || indexPathRow == document.pageCount - 1 {
            if let image = document.image(for: indexPathRow + 1) {
                pageView = PDFPageView(frame: bounds, document: document, pageNumber: indexPathRow + 1, backgroundImage: image, pageViewDelegate: self)
            }
            return
        }
        
        if UIDevice.current.orientation.isLandscape {
            if let image = document.spread(for: indexPathRow + 1, in: bounds) {
                pageView = PDFPageView(frame: bounds, document: document, pageNumber: indexPathRow + 1, backgroundImage: image, pageViewDelegate: self)
            }
        } else {
            if let image = document.image(for: indexPathRow + 1) {
                pageView = PDFPageView(frame: bounds, document: document, pageNumber: indexPathRow + 1, backgroundImage: image, pageViewDelegate: self)
            }
        }
    }
}


// MARK: - PDFPageViewDelegate
extension PDFPageCollectionViewCell: PDFPageViewDelegate {
    func handleSingleTap(_ pdfPageView: PDFPageView) {
        delegate?.handleSingleTap(self, pdfPageView: pdfPageView)
    }
}
