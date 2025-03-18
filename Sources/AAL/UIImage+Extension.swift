//
//  UIImage+Extension.swift
//  AAL
//
//  Created by Ashish Tyagi on 18/03/25.
//

import Foundation
import UIKit

extension UIImage {
    static func loadFromBundle(named imageName: String, withExtension ext: String = "png") -> UIImage? {
        guard let imagePath = Bundle.module.path(forResource: imageName, ofType: ext) else {
            print("Image '\(imageName).\(ext)' not found in bundle!")
            return nil
        }
        return UIImage(contentsOfFile: imagePath)
    }
}
