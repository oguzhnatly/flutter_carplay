import Foundation
import UIKit

/// A custom UIView subclass representing a banner view with a message label.
class FCPBannerView: UIView {
    // MARK: Properties

    /// The background view of the banner.
    @IBOutlet var contentView: UIView! {
        didSet {
            guard let view = contentView else { return }
            view.backgroundColor = .gray
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

    // MARK: Initializers

    /// Initializes a new instance of `FCPBannerView` with the specified frame.
    ///
    /// - Parameter frame: The frame rectangle for the view, measured in points.
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    /// Initializes a new instance of `FCPBannerView` from data encoded in a given decoder.
    ///
    /// - Parameter aDecoder: An unarchiver object.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    // MARK: Private Methods

    /// Configures the UI elements and layout for the banner view.
    private func setupUI() {
        Bundle(for: FCPBannerView.self).loadNibNamed("FCPBannerView", owner: self, options: nil)
        contentView.fixInView(self)
    }
}

// MARK: - Public Method

extension FCPBannerView {
    /// Sets the message to display in the banner view.
    func setMessage(_ message: String) {
        messageLabel.text = message
    }

    /// Sets the content view background color
    func setBackgroundColor(_ color: Int) {
        contentView.backgroundColor = UIColor(argb: color)
    }
}
