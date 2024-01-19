//
// FCPMapOverlayView.swift
// flutter_carplay
//
// Created by Oğuzhan Atalay on on 18/01/24.
// Copyright © 2024. All rights reserved.
//

import UIKit

class FCPOverlayView: UIView {
    /// The background view of the overlay.
    @IBOutlet var contentView: UIView! {
        didSet {
            guard let view = contentView else { return }
            view.backgroundColor = .clear
        }
    }
    
    @IBOutlet weak var titleView: UIView!{
        didSet {
            guard let view = titleView else { return }
            view.backgroundColor = UIColor(rgb: 0x248A3D)
        }
    }
    @IBOutlet weak var subTitleView: UIView!{
        didSet {
            guard let view = subTitleView else { return }
            view.backgroundColor = UIColor(rgb: 0x248A3D)
        }
    }
    
    @IBOutlet weak var primaryTitleLabel: UILabel!
    @IBOutlet weak var secondaryTitleLabel: UILabel!
    @IBOutlet weak var deviderView: UIView!
    @IBOutlet weak var subTitleLabel: UILabel!
    
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
    
    func setPrimaryTitle(_ text: String) {
        primaryTitleLabel.text = text
    }
    
    func setSecondaryTitle(_ text: String) {
        secondaryTitleLabel.text = text
    }
    
    func setSubTitle(_ text: String) {
        subTitleLabel.text = text
    }
}
