//
//  GroupResponse.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 06/05/2021.
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
