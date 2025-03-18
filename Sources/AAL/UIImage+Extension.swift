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
        if #available(iOS 13.0, *) {
              return UIImage(named: imageName, in: Bundle.module, with: nil)
          } else {
              return UIImage(named: imageName) // Fallback for iOS 12 and earlier
          }
    }
}
