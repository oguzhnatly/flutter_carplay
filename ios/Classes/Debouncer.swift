//
// Debouncer.swift
// flutter_carplay
//
// Created by Pradip Sutariya on 29.04.2024.
// Copyright © 2024 Aubergine Solutions Pvt. Ltd. All rights reserved.
// 

import Foundation

/// Class implementing the debounce for optimizing search events.
class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue

    init(delay: TimeInterval, queue: DispatchQueue = DispatchQueue.main) {
        self.delay = delay
        self.queue = queue
    }

    func debounce(action: @escaping (() -> Void)) {
        workItem?.cancel()
        workItem = DispatchWorkItem { [weak self] in
            action()
            self?.workItem = nil
        }
        if let workItem = workItem {
            queue.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
}
