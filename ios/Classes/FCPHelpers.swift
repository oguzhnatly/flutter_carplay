//
//  FCPHelpers.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

/// Generates a Flutter CarPlay (FCP) channel ID based on the specified event.
/// - Parameter event: The event associated with the channel.
/// - Returns: The FCP channel ID combining the base identifier and the provided event.
func makeFCPChannelId(event: String?) -> String {
    return "com.oguzhnatly.flutter_carplay" + (event ?? "")
}
