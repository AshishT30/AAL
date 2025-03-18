//
//  CustomPopupView.swift
//  AAL
//
//  Created by Ashish Tyagi on 17/03/25.
//

import Foundation
import UIKit

class CustomPopupView: UIView {
    
    var onRetry: (() -> Void)? // Callback for retrying authentication

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        if let bundlePath = Bundle(for: CustomPopupView.self).resourcePath {
            print("Bundle Path: \(bundlePath)")
            let imagePath = "\(bundlePath)/myImage.png"
            print("Checking image path: \(imagePath)")
            print(FileManager.default.fileExists(atPath: imagePath) ? "Image found!" : "Image missing!")
        }
        
        if let bundlePath = Bundle(for: AppLockManager.self).resourcePath {
            print("Bundle Path: \(bundlePath)")
            let imagePath = "\(bundlePath)/myImage.png"
            print("Checking image path: \(imagePath)")
            print(FileManager.default.fileExists(atPath: imagePath) ? "Image found!" : "Image missing!")
        }
        imageView.image = loadImage(named: "lock")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Invest BharatPe is locked"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .black
        label.textAlignment = .left
        return label
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "For security reasons, please unlock your app to proceed."
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.init(red: 61/255.0, green: 73/255.0, blue: 102/255.0, alpha: 1)
        label.textAlignment = .left
        label.numberOfLines = 2
        return label
    }()
    
    let unlockButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Unlock", for: .normal)
        button.backgroundColor = UIColor.init(red: 16/255.0, green: 88/255.0, blue: 102/255.0, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 20
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        unlockButton.addTarget(self, action: #selector(handleUnlock), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 15
        translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [imageView, titleLabel, messageLabel, unlockButton])
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        imageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        unlockButton.widthAnchor.constraint(equalToConstant: 200).isActive = true

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8)
        ])
    }

    @objc private func handleUnlock() {
        onRetry?() // Trigger retry authentication
    }
}

extension CustomPopupView {
    func loadImage(named imageName: String) -> UIImage? {
        let bundle = Bundle(for: CustomPopupView.self)
        if let imagePath = bundle.path(forResource: imageName, ofType: "png") {
            return UIImage(contentsOfFile: imagePath)
        }
        return nil
    }
}
