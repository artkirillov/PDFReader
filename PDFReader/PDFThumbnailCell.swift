//
//  PDFThumbnailCell.swift
//  PDFReader
//
//  Created by Artem Kirillov on 24.02.17.
//  Copyright © 2017 Artem Kirillov. All rights reserved.
//

import UIKit

/// An individual thumbnail in the collection view
internal final class PDFThumbnailCell: UICollectionViewCell {
    
    static let portraitCellSize = CGSize(width: 75, height: 120)
    static let landscapeCellSize = CGSize(width: 150, height: 120)
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var numberLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.layer.borderWidth = 1.5
    }
    
    /// Customizes and sets up the cell to be ready to be displayed (for landscape and portrait orientations)
    ///
    /// - Parameters:
    ///   - indexPathRow: page index of the document to be displayed
    ///   - document: document to be displayed
    ///   - isCurrentPage: shows if it is current page of the document
    func setup(_ indexPathRow: Int, document: PDFDocument, isCurrentPage: Bool) {
        
        imageView.layer.borderColor = isCurrentPage ? UIColor.lightGray.cgColor : UIColor(colorLiteralRed: 178/255, green: 38/255, blue: 39/255, alpha: 1).cgColor
        
        if indexPathRow == 0 || indexPathRow == document.pageCount - 1 {
            if let image = document.image(for: indexPathRow + 1) {
                numberLabel.text = "\(indexPathRow + 1)"
                imageView.image = image
            }
            return
        }
        
        if UIDevice.current.orientation.isLandscape {
            if let image = document.spread(for: indexPathRow + 1, in: bounds) {
                numberLabel.text = "\(indexPathRow + 1)                   \(indexPathRow + 2)"
                imageView.image = image
            }
        } else {
            if let image = document.image(for: indexPathRow + 1) {
                numberLabel.text = "\(indexPathRow + 1)"
                imageView.image = image
            }
        }
    }
}

