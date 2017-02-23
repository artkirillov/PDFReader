//
//  PDFThumbnailCollectionViewController.swift
//  PDFReader
//
//  Created by Artem Kirillov on 24.02.17.
//  Copyright © 2017 Artem Kirillov. All rights reserved.
//

import UIKit

/// Delegate that handles thumbnail collection view selections
protocol PDFThumbnailControllerDelegate: class {

    func didSelectIndexPath(_ indexPath: IndexPath)
}

internal final class PDFThumbnailCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var document: PDFDocument!
    var currentPageIndex: Int = 0 {
        didSet {
            guard let collectionView = collectionView else { return }
            
            let curentPageIndexPath = IndexPath(row: currentPageIndex, section: 0)
            collectionView.scrollToItem(at: curentPageIndexPath, at: .centeredHorizontally, animated: true)
            collectionView.reloadData()
        }
    }
    
    weak var delegate: PDFThumbnailControllerDelegate?

    
    // MARK: - UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = document.pageCount
        if UIDevice.current.orientation.isLandscape {
            return count / 2 + 1
        } else {
            return count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PDFThumbnailCell
        let isCurrentPage = indexPath.row != currentPageIndex
        if indexPath.row == 0 {
            cell.setup(indexPath.row, document: document, isCurrentPage: isCurrentPage)
            return cell
        }
        
        if UIDevice.current.orientation.isLandscape {
            cell.setup(indexPath.row * 2 - 1, document: document, isCurrentPage: isCurrentPage)
            return cell
        } else {
            cell.setup(indexPath.row, document: document, isCurrentPage: isCurrentPage)
            return cell
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if UIDevice.current.orientation.isLandscape && indexPath.row != 0 && indexPath.row != document.pageCount / 2 {
            return PDFThumbnailCell.landscapeCellSize
        } else {
            return PDFThumbnailCell.portraitCellSize
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    // MARK: - UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectIndexPath(indexPath)
    }
}
