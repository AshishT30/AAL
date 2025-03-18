//
//  UIImage+Extension.swift
//  AAL
//
//  Created by Ashish Tyagi on 18/03/25.
//

import Foundation
import UIKit

extension UIImage {
    static func loadImage(named imageName: String) -> UIImage? {
        return UIImage(named: imageName) // Fallback for iOS 12 and earlier
    }
}
