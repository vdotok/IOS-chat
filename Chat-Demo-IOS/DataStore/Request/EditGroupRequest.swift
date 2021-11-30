//
//  EditGroupRequest.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 25/06/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import Foundation

struct EditGroupRequest: APIRequest {
    func getMethod() -> RequestType {
        .POST
    }
    
    func getPath() -> String {
        "RenameGroup"
    }
    let group_title: String
    let group_id: Int
    
}
