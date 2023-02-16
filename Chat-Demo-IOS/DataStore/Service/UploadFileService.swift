//
//  UploadFileService.swift
//  Chat-Demo-IOS
//
//  Created by Fajar Chishtee on 31/01/2023.
//  Copyright © 2023 VDOTOK. All rights reserved.
//

import Foundation

typealias uploadComplition = ((Result<UploadFileResponse, Error>) -> Void)


protocol uploadStoreable {
    func uploadFile(with request: UploadFileRequest, complition: @escaping uploadComplition)
}

class UploadFileService: BaseDataStore, uploadStoreable {
    
    let translator: ObjectTranslator
    
    init(service: Service, translator: ObjectTranslator = ObjectTranslation()) {
        self.translator = translator
        super.init(service: service)
    }
    
    func uploadFile(with request: UploadFileRequest, complition: @escaping uploadComplition) {
        service.post(request: request) { (result) in
            switch result {
            case .success(let data):
                self.translate(data: data, complition: complition)
            case .failure(let error):
                complition(.failure(error))
                
            }
        }
    }
    
    private func translate(data: Data, complition: uploadComplition) {
        do {
            let response: UploadFileResponse = try translator.decodeObject(data: data)
            switch response.status {
            case 200:
                print("alooo->>\(response.self)")
//                VDOTOKObject<UserResponse>().setData(response)
//                VDOTOKObject<String>().setToken(response.authToken)
            case 486:
                print("alooo32->>\(response)")
            default:
                break
            }
            complition(.success(response))
            
        }
        catch {
            complition(.failure(error))
        }
    }
}
