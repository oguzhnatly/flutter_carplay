//
//  FCPMapTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay
import MapKit

/// A custom CarPlay map template with additional customization options.
@available(iOS 14.0, *)
class FCPMapTemplate: NSObject {
    // MARK: Properties
    
    /// The super template object representing the CarPlay map template.
    private(set) var _super: CPMapTemplate?
    
    /// The view controller associated with the map template.
    private(set) var viewController: UIViewController?
    
    /// The unique identifier for the map template.
    private(set) var elementId: String
    
    /// The title displayed on the map template.
    private var title: String?
    
    /// The map buttons to be displayed on the map template.
    private var mapButtons: [FCPMapButton]
    
    /// The leading navigation bar buttons for the map template.
    private var leadingNavigationBarButtons: [FCPBarButton]
    
    /// The trailing navigation bar buttons for the map template.
    private var trailingNavigationBarButtons: [FCPBarButton]
    
    /// A boolean value indicating whether the navigation bar is automatically hidden.
    private var automaticallyHidesNavigationBar: Bool = false
    
    /// A boolean value indicating whether buttons are hidden with the navigation bar.
    private var hidesButtonsWithNavigationBar: Bool = false
    
    // MARK: Initializer
    
    /// Initializes a new instance of `FCPMapTemplate` with the specified configuration.
    ///
    /// - Parameter obj: A dictionary containing the configuration parameters for the map template.
    init(obj: [String: Any]) {
        guard let elementId = obj["_elementId"] as? String else {
            fatalError("[FCPMapTemplate] Missing required property: _elementId.")
        }
        
        self.elementId = elementId
        title = obj["title"] as? String
        automaticallyHidesNavigationBar = obj["automaticallyHidesNavigationBar"] as? Bool ?? false
        hidesButtonsWithNavigationBar = obj["hidesButtonsWithNavigationBar"] as? Bool ?? false
        
        mapButtons = (obj["mapButtons"] as? [[String: Any]] ?? []).map {
            FCPMapButton(obj: $0)
        }
        
        leadingNavigationBarButtons = (obj["leadingNavigationBarButtons"] as? [[String: Any]] ?? []).map {
            FCPBarButton(obj: $0)
        }
        
        trailingNavigationBarButtons = (obj["trailingNavigationBarButtons"] as? [[String: Any]] ?? []).map {
            FCPBarButton(obj: $0)
        }
        
        
        /// Initialize the view controller.
        viewController = FCPMapViewController(nibName: "FCPMapViewController", bundle: Bundle(for: FCPMapViewController.self))
    }
    
    // MARK: Getter
    
    /// Gets the CarPlay map template object based on the configured parameters.
    var get: CPMapTemplate {
        let mapTemplate = CPMapTemplate()
        mapTemplate.setFCPObject(self)
        
        var mButtons: [CPMapButton] = []
        for button in mapButtons {
            mButtons.append(button.get)
        }
        
        var lBButtons: [CPBarButton] = []
        for button in leadingNavigationBarButtons {
            lBButtons.append(button.get)
        }
        
        var tBButtons: [CPBarButton] = []
        for button in trailingNavigationBarButtons {
            tBButtons.append(button.get)
        }
        
        mapTemplate.mapButtons = mButtons
        mapTemplate.leadingNavigationBarButtons = lBButtons
        mapTemplate.trailingNavigationBarButtons = tBButtons
        mapTemplate.automaticallyHidesNavigationBar = automaticallyHidesNavigationBar
        mapTemplate.hidesButtonsWithNavigationBar = hidesButtonsWithNavigationBar
        mapTemplate.mapDelegate = viewController as? CPMapTemplateDelegate
        
        _super = mapTemplate
        return mapTemplate
    }
    
    /// Updates the properties of the map template.
    ///
    /// - Parameters:
    ///   - title: The new title text.
    ///   - automaticallyHidesNavigationBar: A boolean value indicating whether the navigation bar is automatically hidden.
    ///   - hidesButtonsWithNavigationBar: A boolean value indicating whether buttons are hidden with the navigation bar.
    ///   - mapButtons: The new array of map buttons.
    ///   - leadingNavigationBarButtons: The new array of leading navigation bar buttons.
    ///   - trailingNavigationBarButtons: The new array of trailing navigation bar buttons.
    public func update(title: String?, automaticallyHidesNavigationBar: Bool?, hidesButtonsWithNavigationBar: Bool?, mapButtons: [FCPMapButton]?, leadingNavigationBarButtons: [FCPBarButton]?, trailingNavigationBarButtons: [FCPBarButton]?) {
        if let _title = title {
            self.title = _title
        }
        
        if let _hidesButtonsWithNavigationBar = hidesButtonsWithNavigationBar {
            self.hidesButtonsWithNavigationBar = _hidesButtonsWithNavigationBar
            _super?.hidesButtonsWithNavigationBar = _hidesButtonsWithNavigationBar
        }
        
        if let _automaticallyHidesNavigationBar = automaticallyHidesNavigationBar {
            self.automaticallyHidesNavigationBar = _automaticallyHidesNavigationBar
            _super?.automaticallyHidesNavigationBar = _automaticallyHidesNavigationBar
        }
        
        if let _mapButtons = mapButtons {
            self.mapButtons = _mapButtons
            _super?.mapButtons = _mapButtons.map { $0.get }
        }
        
        if let _leadingNavigationBarButtons = leadingNavigationBarButtons {
            self.leadingNavigationBarButtons = _leadingNavigationBarButtons
            _super?.leadingNavigationBarButtons = _leadingNavigationBarButtons.map {
                $0.get
            }
        }
        
        if let _trailingNavigationBarButtons = trailingNavigationBarButtons {
            self.trailingNavigationBarButtons = _trailingNavigationBarButtons
            _super?.trailingNavigationBarButtons = _trailingNavigationBarButtons.map {
                $0.get
            }
        }
        _super?.setFCPObject(self)
    }
}

// MARK: - Extensions

// Extension for UIViewController utility methods
extension FCPMapTemplate {
    /// Displays a banner message at the top of the screen.
    func showBanner(message: String, color: Int) {
        guard let viewController = viewController as? FCPMapViewController else {
            return
        }
        
        viewController.showBanner(message: message, color: color)
    }
    
    /// Hides the banner message at the top of the screen.
    func hideBanner() {
        guard let viewController = viewController as? FCPMapViewController else {
            return
        }
        viewController.hideBanner()
    }
    
    /// Displays a toast message on the screen for a specified duration.
    func showToast(message: String, duration: TimeInterval = 2.0) {
        guard let viewController = viewController as? FCPMapViewController else {
            return
        }
        
        viewController.showToast(message: message, duration: duration)
    }
}

@available(iOS 14.0, *)
extension FCPMapTemplate: FCPRootTemplate {}

@available(iOS 14.0, *)
extension FCPMapTemplate: FCPTemplate {}
