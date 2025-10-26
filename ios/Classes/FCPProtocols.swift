//
//  FCPProtocols.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 25.08.2021.
//
import CarPlay

public protocol FCPPresentTemplate: AnyObject {}

public protocol FCPRootTemplate: AnyObject {
  var get: CPTemplate { get }
  var elementId: String { get }
}
