//
//  CustomPopupView.swift
//  AAL
//
//  Created by Ashish Tyagi on 17/03/25.
//

import Foundation
import UIKit

class CustomPopupView: UIView {
    
    var onButtonTap: (() -> Void)? // Callback for retrying authentication
    
    // UI Elements
      private let imageView = UIImageView()
      private let titleLabel = UILabel()
      private let messageLabel = UILabel()
      private let actionButton = UIButton(type: .system)
      
      // MARK: - Initializer
        init(title: String, message: String, buttonTitle: String, image: String) {
           super.init(frame: .zero)
           setupUI(title: title, message: message, buttonTitle: buttonTitle, image: image)
       }

    required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    private func setupUI(title: String, message: String, buttonTitle: String, image: String) {
            self.backgroundColor = .white
            self.layer.cornerRadius = 15
            self.clipsToBounds = true

            // ImageView
            if let image = UIImage.loadFromBundle(named: image) {
                imageView.image = image
            } else {
                print("Failed to load image")
            }
            imageView.isHidden = false
            imageView.alpha = 1.0
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false

            // Title Label
            titleLabel.text = title
            titleLabel.textAlignment = .center
            titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false

            // Message Label
            messageLabel.text = message
            messageLabel.textAlignment = .center
            messageLabel.font = UIFont.systemFont(ofSize: 14)
            messageLabel.numberOfLines = 2
            messageLabel.translatesAutoresizingMaskIntoConstraints = false

            // Action Button
            actionButton.setTitle(buttonTitle, for: .normal)
            actionButton.backgroundColor = .systemBlue
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.layer.cornerRadius = 8
            actionButton.translatesAutoresizingMaskIntoConstraints = false
            actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

            // StackView
            let stackView = UIStackView(arrangedSubviews: [imageView, titleLabel, messageLabel, actionButton])
            stackView.axis = .vertical
            stackView.spacing = 15
            stackView.alignment = .leading
            stackView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(stackView)

            // Constraints
            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
                stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
                stackView.widthAnchor.constraint(equalToConstant: 280),

                imageView.widthAnchor.constraint(equalToConstant: 60),
                imageView.heightAnchor.constraint(equalToConstant: 60),

                actionButton.widthAnchor.constraint(equalToConstant: 200),
                actionButton.heightAnchor.constraint(equalToConstant: 40)
            ])
        }

        @objc private func buttonTapped() {
            onButtonTap?()
        }
    }
