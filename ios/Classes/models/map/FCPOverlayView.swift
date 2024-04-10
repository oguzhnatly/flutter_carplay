//
// FCPOverlayView.swift
// flutter_carplay
//
// Created by Oğuzhan Atalay on on 18/01/24.
// Copyright © 2024. All rights reserved.
//

import UIKit

/// A custom UIView class for displaying overlay views.
class FCPOverlayView: UIView {
    /// The background view of the overlay.
    @IBOutlet var contentView: UIView! {
        didSet {
            guard let view = contentView else { return }
            view.backgroundColor = .clear
        }
    }

    /// The title view of the overlay.
    @IBOutlet var titleView: UIView! {
        didSet {
            guard let view = titleView else { return }
            view.backgroundColor = UIColor(rgb: 0x248A3D)
        }
    }

    /// The subtitle view of the overlay.
    @IBOutlet var subtitleView: UIView! {
        didSet {
            guard let view = subtitleView else { return }
            view.backgroundColor = UIColor(rgb: 0x248A3D)
        }
    }

    /// The devider view of the overlay.
    @IBOutlet var deviderView: UIView!

    /// The primary title label of the overlay.
    @IBOutlet var primaryTitleLabel: UILabel! {
        didSet {
            guard let label = primaryTitleLabel else { return }
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 12)
            label.numberOfLines = 0
        }
    }

    /// The secondary title label of the overlay.
    @IBOutlet var secondaryTitleLabel: UILabel! {
        didSet {
            guard let label = secondaryTitleLabel else { return }
            label.textColor = .white
            label.font = UIFont.boldSystemFont(ofSize: 12)
            label.numberOfLines = 0
        }
    }

    /// The subtitle label of the overlay.
    @IBOutlet var subtitleLabel: UILabel! {
        didSet {
            guard let label = subtitleLabel else { return }
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 12)
            label.numberOfLines = 0
        }
    }

    // MARK: Initializers

    /// Initializes a new instance of `FCPOverlayView` with the specified frame.
    ///
    /// - Parameter frame: The frame rectangle for the view, measured in points.
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    /// Initializes a new instance of `FCPOverlayView` from data encoded in a given decoder.
    ///
    /// - Parameter aDecoder: An unarchiver object.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    // MARK: Private Methods

    private func setupUI() {
        Bundle(for: FCPOverlayView.self).loadNibNamed("FCPOverlayView", owner: self, options: nil)
        contentView.fixInView(self)
    }
}

// MARK: - Public Method

extension FCPOverlayView {
    /// Sets the primaryTitle to display in the overlay view.
    func setPrimaryTitle(_ text: String) {
        primaryTitleLabel.text = text
    }

    /// Sets the secondaryTitle to display in the overlay view.
    func setSecondaryTitle(_ text: String) {
        secondaryTitleLabel.text = text
    }

    /// Sets the subtitle to display in the overlay view.
    func setSubtitle(_ text: String) {
        subtitleLabel.text = text
    }
}
