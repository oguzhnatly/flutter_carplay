//
//  FCPInformationTemplate.swift
//  flutter_carplay
//
//  Created by Olaf Schneider on 15.02.22.
//

import CarPlay

/// A wrapper class for CPInformationTemplate with additional functionality.
@available(iOS 14.0, *)
class FCPInformationTemplate {
    // MARK: Properties
    
    /// The underlying CPInformationTemplate instance.
    private(set) var _super: CPInformationTemplate?
    
    /// The unique identifier for the information template.
    private(set) var elementId: String
    
    /// The layout style of the information template.
    private var layout: CPInformationTemplateLayout
    
    /// The title of the information template.
    private var title: String
    
    /// An array of CPInformationItem instances associated with the information template.
    private var informationItems: [CPInformationItem]
    
    /// An array of FCPInformationItem instances associated with the information template.
    private var objcInformationItems: [FCPInformationItem]
    
    /// An array of CPTextButton instances associated with the information template.
    private var actions: [CPTextButton]
    
    /// An array of FCPTextButton instances associated with the information template.
    private var objcActions: [FCPTextButton]
    
    // MARK: Initializer
    
    /// Initializes an instance of FCPInformationTemplate with the provided parameters.
    ///
    /// - Parameter obj: A dictionary containing information about the information template.
    init(obj: [String: Any]) {
        guard let elementIdValue = obj["_elementId"] as? String,
              let layoutStringValue = obj["layout"] as? String,
              let titleValue = obj["title"] as? String else {
            fatalError("Missing required keys in dictionary for FCPInformationTemplate initialization.")
        }
        
        let informationItemsData = obj["informationItems"] as? [[String: Any]] ?? []
        let actionsData = obj["actions"] as? [[String: Any]] ?? []
        
        elementId = elementIdValue
        layout = layoutStringValue == "twoColumn" ? CPInformationTemplateLayout.twoColumn : CPInformationTemplateLayout.leading
        title = titleValue
        
        objcInformationItems = informationItemsData.map {
            FCPInformationItem(obj: $0)
        }
        informationItems = objcInformationItems.map {
            $0.get
        }
        
        objcActions = actionsData.map {
            FCPTextButton(obj: $0)
        }
        actions = objcActions.map {
            $0.get
        }
    }
    
    // MARK: Computed Property
    
    /// Returns the underlying CPInformationTemplate instance configured with the specified properties.
    var get: CPInformationTemplate {
        let informationTemplate = CPInformationTemplate(title: title, layout: layout, items: informationItems, actions: actions)
        _super = informationTemplate
        return informationTemplate
    }
}

// MARK: Extensions

@available(iOS 14.0, *)
extension FCPInformationTemplate: FCPRootTemplate {}

@available(iOS 14.0, *)
extension FCPInformationTemplate: FCPTemplate {}
