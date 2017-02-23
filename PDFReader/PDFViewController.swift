//  PDFViewController.swift
//  PDFReader
//
//  Created by Artem Kirillov on 24.02.17.
//  Copyright © 2017 Artem Kirillov. All rights reserved.
//

import UIKit

/// Main view controller that is show pages of PDF document
public final class PDFViewController: UIViewController {
    
    /// Name of the document
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    
    /// Collection veiw with pdf pages
    @IBOutlet fileprivate weak var collectionView: UICollectionView!
    
    /// Distance between the bottom thumbnail bar with bottom of page
    @IBOutlet fileprivate weak var thumbnailCollectionControllerBottom: NSLayoutConstraint!
    
    /// Name of PDF file in the file system (make it String if you don't use Objective-C in your project)
    var name: NSString?
    
    fileprivate var document: PDFDocument!
    fileprivate var currentPageIndex: Int = 0
    fileprivate var thumbnailCollectionController: PDFThumbnailCollectionViewController?
    fileprivate var inactiveLayer = CALayer()
    
    fileprivate var isThumbnailControllerHidden: Bool {
        return thumbnailCollectionControllerBottom.constant == -150
    }
    
    /// Toggles the hiding/showing of the thumbnail controller
    ///
    /// - parameter shouldHide: whether or not the controller show hide
    fileprivate func hideThumbnailController(_ shouldHide: Bool) {
        thumbnailCollectionControllerBottom.constant = shouldHide ? -150 : 0
    }
    
    /// Hides navigation bar and tab bar
    ///
    /// - Parameters:
    ///   - shouldHide: whether or not the controller show hide
    ///   - animated: whether or not hiding should be animated
    fileprivate func hideMenu(_ shouldHide: Bool, animated: Bool) {
        
        hideThumbnailController(shouldHide)
        navigationController?.setNavigationBarHidden(shouldHide, animated: animated)
    }
    
    /// Darken collection view cell when it's not active
    ///
    /// - Parameters:
    ///   - layer: layer to darken
    ///   - darken: flag
    func darken(cell: PDFPageCollectionViewCell, shouldDarken: Bool) {
        if shouldDarken {
            inactiveLayer.frame = view.bounds
            cell.layer.addSublayer(inactiveLayer)
        } else {
            inactiveLayer.removeFromSuperlayer()
        }
    }
    
    // MARK: - View Controller Life Cycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let textualModeBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "iconTextualMode"), style: .plain, target: self, action: #selector(textualModeButtonPressed))
        
        navigationItem.rightBarButtonItems = [textualModeBarButton]
        navigationController?.navigationBar.backgroundColor = .white
        
        tabBarController?.tabBar.isHidden = true
        titleLabel.text = document.fileName.components(separatedBy: ".").first?.replacingOccurrences(of: "_", with: " ")
    
        collectionView.register(PDFPageCollectionViewCell.self, forCellWithReuseIdentifier: "page")
        
        inactiveLayer.backgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.6).cgColor
        
        hideMenu(true, animated: false)
        
    }

    override public var prefersStatusBarHidden : Bool {
        return navigationController?.isNavigationBarHidden == true
    }
    
    override public var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return .slide
    }
    
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let documentURL = Bundle.main.url(forResource: name as? String, withExtension: "pdf") else { return }
        document = PDFDocument(fileURL: documentURL)
        
        if let controller = segue.destination as? PDFThumbnailCollectionViewController {
            thumbnailCollectionController = controller
            controller.document = document
            controller.delegate = self
            controller.currentPageIndex = currentPageIndex
        }
            
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.reloadData()
        thumbnailCollectionController?.collectionView?.reloadData()
        
        if UIDevice.current.orientation.isLandscape {
            currentPageIndex = currentPageIndex / 2 + currentPageIndex % 2
        } else if currentPageIndex > 0 {
            currentPageIndex = currentPageIndex * 2 - 1
        }
        
        let currentIndexPath = IndexPath(row: currentPageIndex, section: 0)

        coordinator.animate(alongsideTransition: { context in
            self.collectionView.reloadItems(at: [currentIndexPath])
            self.collectionView.scrollToItem(at: currentIndexPath, at: .centeredHorizontally, animated: false)
        }) { context in
            
            if !self.isThumbnailControllerHidden {
                if let cell = self.collectionView.cellForItem(at: currentIndexPath) as? PDFPageCollectionViewCell {
                    self.darken(cell: cell, shouldDarken: true)
                }
            }
            
            self.thumbnailCollectionController?.currentPageIndex = self.currentPageIndex
        }
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    func textualModeButtonPressed() {
        print("---- Show Textual Mode")
    }
    
    deinit {
        print ("- DEINIT PDFViewController")
    }
}

// MARK: - PDFThumbnailControllerDelegate
extension PDFViewController: PDFThumbnailControllerDelegate {
    
    func didSelectIndexPath(_ indexPath: IndexPath) {
        currentPageIndex = indexPath.row
        thumbnailCollectionController?.currentPageIndex = indexPath.row
        
        collectionView.isScrollEnabled = true
        let cell = collectionView.visibleCells.first as! PDFPageCollectionViewCell
        darken(cell: cell, shouldDarken: false)
        hideMenu(true, animated: true)
        
        collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
    }
}

// MARK: - UICollectionViewDataSource
extension PDFViewController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = document.pageCount
        if UIDevice.current.orientation.isLandscape {
            return count / 2 + 1
        } else {
            return count
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "page", for: indexPath) as! PDFPageCollectionViewCell
        
        if indexPath.row == 0 {
            cell.setup(indexPath.row, document: document, pageCollectionViewCellDelegate: self)
            return cell
        }
        
        if UIDevice.current.orientation.isLandscape {
            cell.setup(indexPath.row * 2 - 1, document: document, pageCollectionViewCellDelegate: self)
            return cell
        } else {
            cell.setup(indexPath.row, document: document, pageCollectionViewCellDelegate: self)
            return cell
        }
    }
}

// MARK: - PDFPageCollectionViewCellDelegate
extension PDFViewController: PDFPageCollectionViewCellDelegate {
    
    func handleSingleTap(_ cell: PDFPageCollectionViewCell, pdfPageView: PDFPageView) {
        let menuShown = !isThumbnailControllerHidden
        collectionView.isScrollEnabled = menuShown
        darken(cell: cell, shouldDarken: !menuShown)
        hideMenu(menuShown, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PDFViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}

// MARK: - UIScrollViewDelegate
extension PDFViewController: UIScrollViewDelegate {
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let updatedPageIndex = collectionView.indexPathsForVisibleItems.first?.row {
            if updatedPageIndex != currentPageIndex {
                currentPageIndex = updatedPageIndex
                thumbnailCollectionController?.currentPageIndex = currentPageIndex
            }
        }
    }
}
