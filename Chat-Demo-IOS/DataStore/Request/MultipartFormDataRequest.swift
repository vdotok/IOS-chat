//
//  MultipartFormDataRequest.swift
//  Chat-Demo-IOS
//
//  Created by Raza Abbas on 02/02/2023.
//  Copyright © 2023 VDOTOK. All rights reserved.
//

import Foundation


struct MultipartFormDataRequest {
    private var httpBody = NSMutableData()
    let url: URL
    let param :[String : String]
    let filePathKey :String
    let imageDataKey: Data
    let boundary: String
    let type :String


    init(url: URL,param:[String : String],filePathKey :String, imageDataKey: Data,boundary: String,type:String) {
        self.url = url
        self.param = param
        self.filePathKey = filePathKey
        self.imageDataKey = imageDataKey
        self.boundary = boundary
        self.type = type
    }
    
    func asURLRequest() -> URLRequest {
        var request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = dataFormField() as Data
        return request as URLRequest
    }

   func dataFormField() -> Data  {
        let fieldData = NSMutableData()
        if param != nil {
            for (key, value) in param {
                       fieldData.appendString(string: "--\(boundary)\r\n")
                       fieldData.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                       fieldData.appendString(string: "\(value)\r\n")
                   }
               }
               let filename = "user-profile"
               fieldData.appendString(string: "--\(boundary)\r\n")
               fieldData.appendString(string: "Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n")
               fieldData.appendString(string: "Content-Type: \(type)\r\n\r\n")
               fieldData.append(imageDataKey as Data)
               fieldData.appendString(string: "\r\n")
               fieldData.appendString(string:"--\(boundary)--\r\n")

        return fieldData as Data
    }
    
    
    
}

extension NSMutableData {
    func appendString(string: String) {
        let data = Data(string.utf8)
        append(data)
    }
}
