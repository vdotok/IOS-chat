//  
//  LoginViewModel.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 06/05/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import Foundation

typealias LoginViewModelOutput = (LoginViewModelImpl.Output) -> Void

protocol LoginViewModelInput {
    func loginUser(with email: String, _ password: String)
}

protocol LoginViewModel: LoginViewModelInput {
    var output: LoginViewModelOutput? { get set}
    
    func viewModelDidLoad()
    func viewModelWillAppear()
}

class LoginViewModelImpl: LoginViewModel, LoginViewModelInput {

    private let router: LoginRouter
    var output: LoginViewModelOutput?
    var store: LoginStoreable
    
    init(router: LoginRouter, store: LoginStoreable = LoginService(service: NetworkService())) {
        self.router = router
        self.store = store
    }
    
    func viewModelDidLoad() {
        
    }
    
    func viewModelWillAppear() {
        
    }
    
    //For all of your viewBindings
    enum Output {
        case showProgress
        case hideProgress
        case success
        case internetConnected
        case internetNotConnected(message: String)
        case failure(message: String)
    }
}

extension LoginViewModelImpl {
    func loginUser(with email: String, _ password: String) {
    
       let email =  email.trimmingCharacters(in: .whitespaces)
        guard Reachability.isConnectedToNetwork() else {
            output?(.failure(message: "Internet appears to be offline"))
            return
        }
        if password.count > 14 || password.count < 8 {
            output?(.failure(message: "Password should be between 8 and 14."))
            return
        }
        self.output?(.showProgress)
        let request = LoginRequest(email: email, password: password)
        store.login(with: request) { (response) in
            self.output?(.hideProgress)
            switch response {
            case .success(let response):
                switch response.status {
                case 503:
                    self.output?(.failure(message: response.message))
                case 500:
                    self.output?(.failure(message: response.message))
                case 401:
                    self.output?(.failure(message: response.message))
                case 200:
                    print(response.self)
                    self.output?(.success)
                default:
                    break
                }
            case .failure(let error):
                self.output?(.failure(message: error.localizedDescription))
            }
        }
    }
}
