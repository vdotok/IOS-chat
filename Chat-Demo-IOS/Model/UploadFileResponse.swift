//
//  UploadFileResponse.swift
//  Chat-Demo-IOS
//
//  Created by Fajar Chishtee on 31/01/2023.
//  Copyright © 2023 VDOTOK. All rights reserved.
//

import Foundation
struct UploadFileResponse: Codable {
    let File_Name: String?
    let message: String
    let uploadType: String?
    let data: String?
    let status:Int?
    let file_name: String?
    let filetype: String?
    enum CodingKeys: String, CodingKey {
        case File_Name = "File_Name"
        case file_name = "file_name"
        case data = "data"
        case message = "message"
        case uploadType = "uploadType"
        case filetype = "filetype"
        case status = "status"
    }
}
