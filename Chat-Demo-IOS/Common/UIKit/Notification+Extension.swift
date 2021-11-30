//
//  Notification+Extension.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 31/05/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let didStartTyping = Notification.Name(rawValue: "didStartTyping")
    static let didEndTyping = Notification.Name(rawValue: "didEndTyping")
    static let didGroupCreated = Notification.Name(rawValue: "didGroupCreated")
    static let removeCount = Notification.Name(rawValue: "removeCount")
}
