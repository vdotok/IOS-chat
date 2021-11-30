//
//  DeleteGroupRequest.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 25/06/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import Foundation

struct DeleteGroupRequest: APIRequest {
    func getMethod() -> RequestType {
        .POST
    }
    
    func getPath() -> String {
        "DeleteGroup"
    }
    
    let group_id: Int
}
