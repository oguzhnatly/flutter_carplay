//
//  FCPProtocols.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 25.08.2021.
//

/// Protocol representing a template that can be presented in the Flutter CarPlay (FCP) framework.
protocol FCPPresentTemplate : FCPTemplate{}

/// Protocol representing a root template in the Flutter CarPlay (FCP) framework.
protocol FCPRootTemplate {}

/// Protocol representing a generic template in the Flutter CarPlay (FCP) framework.
protocol FCPTemplate {
    /// The unique identifier for the present template.
    var elementId: String{get set}
}
