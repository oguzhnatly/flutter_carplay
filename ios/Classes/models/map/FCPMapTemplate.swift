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
        self.title = obj["title"] as? String
        self.automaticallyHidesNavigationBar = obj["automaticallyHidesNavigationBar"] as? Bool ?? false
        self.hidesButtonsWithNavigationBar = obj["hidesButtonsWithNavigationBar"] as? Bool ?? false
        
        self.mapButtons = (obj["mapButtons"] as? [[String: Any]] ?? []).map {
            FCPMapButton(obj: $0)
        }
        
        self.leadingNavigationBarButtons = (obj["leadingNavigationBarButtons"] as? [[String: Any]] ?? []).map {
            FCPBarButton(obj: $0)
        }
        
        self.trailingNavigationBarButtons = (obj["trailingNavigationBarButtons"] as? [[String: Any]] ?? []).map {
            FCPBarButton(obj: $0)
        }
        
        self.viewController = FCPMapViewController()
    }
    
    // MARK: Getter
    
    /// Gets the CarPlay map template object based on the configured parameters.
    var get: CPMapTemplate {
        let mapTemplate = CPMapTemplate()
        
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
}

// MARK: - Extensions

@available(iOS 14.0, *)
extension FCPMapTemplate: FCPRootTemplate {}

@available(iOS 14.0, *)
extension FCPMapTemplate: FCPTemplate {}
