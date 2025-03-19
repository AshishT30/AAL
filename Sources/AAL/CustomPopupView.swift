//
//  CustomPopupView.swift
//  AAL
//
//  Created by Ashish Tyagi on 17/03/25.
//

import Foundation
import UIKit

public class CustomPopupView: UIView {
    
    public var onButtonTap: (() -> Void)? // Callback for retrying authentication
    
    // UI Elements
    public let imageView = UIImageView()
    public let titleLabel = UILabel()
    public let messageLabel = UILabel()
    public let actionButton = UIButton(type: .system)
    public let buttonColor = String()
      
      // MARK: - Initializer
    public init(title: String, message: String, buttonTitle: String, image: String, buttonColor: String) {
           super.init(frame: .zero)
        setupUI(title: title, message: message, buttonTitle: buttonTitle, image: image, buttonColor: buttonColor)
       }

    required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    private func setupUI(title: String, message: String, buttonTitle: String, image: String, buttonColor: String) {
            self.backgroundColor = .white
            self.layer.cornerRadius = 15
            self.clipsToBounds = true

            // ImageView
            if let image = UIImage.loadFromBundle(named: image) {
                imageView.image = image
            } else {
                print("Failed to load image")
            }
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false

            // Title Label
            titleLabel.text = title
            titleLabel.textAlignment = .left
            titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
            titleLabel.textColor = .black
            titleLabel.translatesAutoresizingMaskIntoConstraints = false

            // Message Label
            messageLabel.text = message
            messageLabel.textAlignment = .left
            messageLabel.font = UIFont.systemFont(ofSize: 14)
            messageLabel.textColor = UIColor(hexString: "#3D4966")
            messageLabel.numberOfLines = 2
            messageLabel.translatesAutoresizingMaskIntoConstraints = false

            // Action Button (Full Width, Capsule Shape)
            actionButton.setTitle(buttonTitle, for: .normal)
            actionButton.backgroundColor = UIColor(hexString: buttonColor)
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.layer.cornerRadius = 20 // Capsule Shape
            actionButton.clipsToBounds = true
            actionButton.translatesAutoresizingMaskIntoConstraints = false
            actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

            // Layout using StackView
            let stackView = UIStackView(arrangedSubviews: [imageView, titleLabel, messageLabel, actionButton])
            stackView.axis = .vertical
            stackView.spacing = 15
            stackView.alignment = .center // Center align everything
            stackView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(stackView)

            // Constraints
            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
                stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
                stackView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),

                imageView.widthAnchor.constraint(equalToConstant: 60),
                imageView.heightAnchor.constraint(equalToConstant: 60),

                actionButton.widthAnchor.constraint(equalTo: stackView.widthAnchor), // Full Width
                actionButton.heightAnchor.constraint(equalToConstant: 40)
            ])
        }

        @objc private func buttonTapped() {
            onButtonTap?()
        }
    }
