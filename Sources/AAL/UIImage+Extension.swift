//
//  UIImage+Extension.swift
//  AAL
//
//  Created by Ashish Tyagi on 18/03/25.
//

import Foundation
import UIKit

extension UIImage {
    static func fromBundle(named imageName: String) -> UIImage? {
        let bundle = Bundle(for: CustomPopupView.self)
        return UIImage(named: imageName, in: bundle, compatibleWith: nil)
    }
}
