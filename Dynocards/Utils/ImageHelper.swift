//
//  ImageHelper.swift
//  Dynocards
//
//  Created by User on 2024
//

import UIKit
import SwiftUI

extension UIImage {
    /// Resizes the image to a maximum dimension while maintaining aspect ratio
    func resizeToMaxDimension(_ maxDimension: CGFloat) -> UIImage? {
        let size = self.size
        
        // If image is already smaller, return as is
        guard max(size.width, size.height) > maxDimension else {
            return self
        }
        
        let ratio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
        } else {
            newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        self.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

