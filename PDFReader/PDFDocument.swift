//
//  PDFDocument.swift
//  PDFReader
//
//  Created by Artem Kirillov on 24.02.17.
//  Copyright © 2017 Artem Kirillov. All rights reserved.
//

import CoreGraphics
import UIKit

public final class PDFDocument {
    
    public let pageCount: Int
    public let fileName: String
    
    let fileURL: URL
    let coreDocument: CGPDFDocument
    let password: String?
    
    /// Image cache with the page index and and image of the page
    let images = NSCache<NSNumber, UIImage>()
    
    /// Returns a newly initialized document which is located on the file system.
    ///
    /// - parameter fileURL:  the file URL where the locked `.pdf` document exists on the file system
    /// - parameter password: password for the locked pdf
    ///
    /// - returns: A newly initialized `PDFDocument`.
    public init?(fileURL: URL, password: String? = nil) {
        
        print("- INIT PDFDocument")
        
        self.fileURL = fileURL
        self.fileName = fileURL.lastPathComponent
        
        guard let coreDocument = CGPDFDocument(fileURL as CFURL) else { return nil }
        
        if let password = password, let cPasswordString = password.cString(using: .utf8) {
            // Try a blank password first, per Apple's Quartz PDF example
            if coreDocument.isEncrypted && !coreDocument.unlockWithPassword("") {
                // Nope, now let's try the provided password to unlock the PDF
                if !coreDocument.unlockWithPassword(cPasswordString) {
                    print("CGPDFDocumentCreateX: Unable to unlock \(fileURL)")
                }
                self.password = password
            } else {
                self.password = nil
            }
        } else {
            self.password = nil
        }
        
        self.coreDocument = coreDocument
        self.pageCount = coreDocument.numberOfPages
    }
    
    deinit {
        print ("- DEINIT PDFDocument")
    }
    
    
    /// Image of the spread
    ///
    /// - parameter for: page number index of the page
    /// - returns: Image representation of the spread
    func spread(for pageNumber: Int, in bounds: CGRect) -> UIImage? {
        
        guard let image1 = image(for: pageNumber), let image2 = image(for: pageNumber + 1) else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        
        let rect1 = CGRect(x: 0, y: 0, width: bounds.width / 2, height: bounds.height)
        let rect2 = CGRect(x: bounds.width / 2, y: 0, width: bounds.width / 2, height: bounds.height)
        
        image1.draw(in: rect1)
        image2.draw(in: rect2)
        
        let spreadImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return spreadImage
    }
    
    
    /// Image of the document page, first looking at the cache, proccesses otherwise
    ///
    /// - parameter for: page number index of the page
    /// - returns: Image representation of the document page
    func image(for pageNumber: Int) -> UIImage? {
        
        if let image = images.object(forKey: NSNumber(value: pageNumber)) {
            //print("-- Using cached image for page \(pageNumber)")
            return image
        } else {
            //print("-- Proccess image for page \(pageNumber)")
            if let image = proccessImage(for: pageNumber) {
                images.setObject(image, forKey: NSNumber(value: pageNumber))
                return image
            }
        }
        return nil
    }
    
    
    /// Proccesses the raw image representation of the document page from the document reference
    ///
    /// - parameter for: page number index of the page
    /// - returns: Image representation of the document page
    private func proccessImage(for pageNumber: Int) -> UIImage? {
        
        guard let page = coreDocument.page(at: pageNumber) else { return nil }
        
        // Determine the size of the PDF page.
        var pageRect = page.getBoxRect(.mediaBox)
        let scalingConstant: CGFloat = 240
        let pdfScale = min(scalingConstant/pageRect.size.width, scalingConstant/pageRect.size.height)
        pageRect.size = CGSize(width: pageRect.size.width * pdfScale, height: pageRect.size.height * pdfScale)
        
        // Create a low resolution image representation of the PDF page to display before the TiledPDFView renders its content.
        UIGraphicsBeginImageContextWithOptions(pageRect.size, true, 1)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // First fill the background with white.
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(pageRect)
        
        context.saveGState()
        // Flip the context so that the PDF page is rendered right side up.
        context.translateBy(x: 0, y: pageRect.size.height)
        context.scaleBy(x: 1, y: -1)
        
        // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
        context.scaleBy(x: pdfScale, y: pdfScale)
        context.drawPDFPage(page)
        
        context.restoreGState()
        
        defer { UIGraphicsEndImageContext() }
        guard let backgroundImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        
        return backgroundImage
    }
}
