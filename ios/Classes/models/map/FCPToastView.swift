import Foundation
import UIKit

/// A custom UIView class for displaying toast messages.
class FCPToastView: UIView {
    // MARK: Properties

    /// The background view of the banner.
    @IBOutlet var contentView: UIView! {
        didSet {
            guard let view = contentView else { return }
            view.backgroundColor = .clear
        }
    }

    /// The label to display the message in the banner.
    @IBOutlet var messageLabel: UILabel! {
        didSet {
            guard let label = messageLabel else { return }
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 14)
            label.textAlignment = .center
            label.numberOfLines = 0
        }
    }

    // MARK: Initialization

    /// Initializes a new instance of `FCPToastView` with the specified frame.
    ///
    /// - Parameter frame: The frame rectangle for the view, measured in points.
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    /// Initializes a new instance of `FCPToastView` from data in a given decoder.
    ///
    /// - Parameter aDecoder: An NSCoder object.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    // MARK: Private Methods

    /// Sets up the UI components and layout constraints for the toast view.
    private func setupUI() {
        Bundle(for: FCPToastView.self).loadNibNamed("FCPToastView", owner: self, options: nil)
        contentView.fixInView(self)
    }
}

// MARK: - Public Method

extension FCPToastView {
    /// Sets the message to display in the toast view.
    func setMessage(_ message: String) {
        messageLabel.text = message
    }
}
