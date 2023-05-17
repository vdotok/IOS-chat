//
//  UploadFileService.swift
//  Chat-Demo-IOS
//
//  Created by Fajar Chishtee on 31/01/2023.
//  Copyright © 2023 VDOTOK. All rights reserved.
//

import Foundation

typealias uploadCompletion = ((Result<UploadFileResponse, Error>) -> Void)


protocol uploadStoreable {
    func uploadFile(with request: UploadFileRequest, complition: @escaping uploadCompletion)
}

class UploadFileService: BaseDataStore, uploadStoreable {
    
    let translator: ObjectTranslator
    
    init(service: Service, translator: ObjectTranslator = ObjectTranslation()) {
        self.translator = translator
        super.init(service: service)
    }
    
    func uploadFile(with request: UploadFileRequest, complition: @escaping uploadCompletion) {
        service.post(request: request) { (result) in
            switch result {
            case .success(let data):
                self.translate(data: data, completion: completion)
            case .failure(let error):
                completion(.failure(error))
                
            }
        }
    }
    
    private func translate(data: Data, completion: uploadCompletion) {
        do {
            let response: UploadFileResponse = try translator.decodeObject(data: data)
            switch response.status {
            case 200:
            case 486:
            default:
                break
            }
            completion(.success(response))
            
        }
        catch {
            completion(.failure(error))
        }
    }
}
