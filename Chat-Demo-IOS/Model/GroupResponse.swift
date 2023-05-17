//
//  GroupResponse.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 06/05/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import Foundation

struct GroupResponse: Codable {
    let groups: [Group]?
    let message: String
    let processTime, status: Int
    

    enum CodingKeys: String, CodingKey {
        case groups, message
        case processTime = "process_time"
        case status
        
    }
}
struct Group: Codable {
    let adminID, autoCreated: Int
    let channelKey, channelName, createdDatetime: String
    var groupTitle: String
    let id: Int
    let participants: [Participant]
    
    enum CodingKeys: String, CodingKey {
        case adminID = "admin_id"
        case autoCreated = "auto_created"
        case channelKey = "channel_key"
        case channelName = "channel_name"
        case createdDatetime = "created_datetime"
        case groupTitle = "group_title"
        case id, participants
    }
    
    func getParticipantsIds() -> [String]{
        return self.participants.compactMap({ participant in
            return String(participant.refID)
        })
    }
}



// MARK: - Participant
struct Participant: Codable {
    let colorCode: String
    let colorID: Int
    let email, fullName, refID: String
    let userID: Int

    enum CodingKeys: String, CodingKey {
        case colorCode = "color_code"
        case colorID = "color_id"
        case email
        case fullName = "full_name"
        case refID = "ref_id"
        case userID = "user_id"
    }
}



struct CreateGroupNotification: Codable {
    
    public var from: String?
    public var data: GroupNotification
    public var to: [String]?
}


struct ReceivedGroupNotification: Codable {
    let data: GroupNotification
    let from, id: String?
}


struct GroupNotification: Codable {
    let action: String
    let groupModel: Group?
}

enum GroupNotificationAction: String {
    case new = "new"
    case modify = "modify"
    case delete = "delete"
}
