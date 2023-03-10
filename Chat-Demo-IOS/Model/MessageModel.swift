//
//  MessageModel.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 28/05/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import Foundation
import iOSSDKConnect

class MessageModel: Message {
    var id: String
    var to: String
    var key: String
    var from: String
    var type: String
    var content: String
    var size: Double
    var isGroupMessage: Bool
    var status: Int
    var subType: Int?
    var date: UInt64
    
    internal init(id: String,
                  to: String,
                  key: String,
                  from: String,
                  type: String,
                  content: String,
                  size: Double,
                  isGroupMessage: Bool,
                  status: Int,
                  subType: Int?,
                  date: UInt64) {
        self.id = id
        self.to = to
        self.key = key
        self.from = from
        self.type = type
        self.content = content
        self.size = size
        self.isGroupMessage = isGroupMessage
        self.status = status
        self.subType = subType
        self.date = date
    }
    
}
