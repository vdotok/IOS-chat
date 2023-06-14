//  
//  ContactViewModel.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 20/05/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import Foundation
import iOSSDKConnect

typealias ContactViewModelOutput = (ContactViewModelImpl.Output) -> Void

protocol ContactViewModelInput {
    
}

protocol ContactViewModel: ContactViewModelInput {
    var output: ContactViewModelOutput? { get set}
    var contacts: [User] {get set}
    var searchContacts: [User] {get set}
    var isSearching: Bool {get set}
    var client: ChatClient? {get set}
    func viewModelDidLoad()
    func viewModelWillAppear()
    func rowsCount() -> Int
    func viewModelItem(row: Int) -> User
    func filterGroups(with text: String)
    func createGroup(with user: User)
}

class ContactViewModelImpl: ContactViewModel, ContactViewModelInput {
    
    var isSearching: Bool = false
    var createGroupStoreAble: GroupStorable = CreateGroupService(service: NetworkService())
    var contacts: [User] = []
    var searchContacts: [User] = []
    private let router: ContactRouter
    private let allUserStoreAble: AllUserStoreAble = AllUsersService(service: NetworkService())
    var output: ContactViewModelOutput?
    var client: ChatClient?
    
    init(router: ContactRouter, client: ChatClient) {
        self.router = router
        self.client = client
    }
    
    func viewModelDidLoad() {
        getUsers() 
    }
    
    func viewModelWillAppear() {
        
    }

    
    //For all of your viewBindings
    enum Output {
        case reload
        case showProgress
        case hideProgress
        case failure(message: String)
        case groupCreated(group: Group, isExit: Bool)
        case alreadyCreated(message : String)
    }
}

extension ContactViewModelImpl {
    
    func viewModelItem(row: Int) -> User {
        return isSearching ? searchContacts[row] : contacts[row]
    }
    
    func rowsCount() -> Int {
        return isSearching ? searchContacts.count : contacts.count
    }
    
    private func getUsers() {
        let request = AllUserRequest()
        output?(.showProgress)
        allUserStoreAble.fetchUsers(with: request) { [weak self] (result) in
            guard let self = self else {return}
            self.output?(.hideProgress)
            switch result {
            case .success(let response):
                switch  response.status {
                case 503:
                    self.output?(.failure(message: response.message ))
                case 500:
                    self.output?(.failure(message: response.message))
                case 401:
                    self.output?(.failure(message: response.message))
                case 200:
                    guard let user = VDOTOKObject<UserResponse>().getData() else {return}
                    self.contacts = response.users.filter({ $0.userID != user.userID})
                    self.searchContacts = self.contacts
                    DispatchQueue.main.async {
                        self.output?(.reload)
                    }
                    
                default:
                    break
                }
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func filterGroups(with text: String) {
        self.searchContacts = contacts.filter({$0.fullName.lowercased().prefix(text.count) == text.lowercased()})
        output?(.reload)
    }
    
    func createGroup(with user: User) {
        guard let myUser = VDOTOKObject<UserResponse>().getData() else {return}
        let groupName: String = myUser.fullName! + " - " + user.fullName
    
        let request = CreateGroupRequest(groupTitle: groupName, participants: [user.userID], autoCreated: 1)
        output?(.showProgress)
        createGroupStoreAble.createGroup(with: request) { [weak self] (result) in
            guard let self = self else {return}
            self.output?(.hideProgress)
            switch result {
            case .success(let response):
                guard let group = response.group, let isExist = response.isalreadyCreated else {return}
                self.sendGroupNotification(groupModel: response, toUser: user.refID)
                
                DispatchQueue.main.async {
                    if isExist {
                        self.output?(.groupCreated(group: group, isExit: true))
                    } else {
                        self.output?(.groupCreated(group: group, isExit: false))
                    }
                }
                
            case .failure(let error):
                self.output?(.failure(message: error.localizedDescription))
                
            }
        }
        
    }
    
    func sendGroupNotification(groupModel: CreateGroupResponse, toUser: String){
        
        guard let myUser = VDOTOKObject<UserResponse>().getData() else {return}
        let model = GroupNotification(action: GroupNotificationAction.new.rawValue, groupModel: groupModel)
        let createModel = CreateGroupNotification(from: myUser.refID!, data: model, to: [toUser])
        
        let jsonData = try! JSONEncoder().encode(createModel)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        self.client?.sendGroupNotification(data: jsonString)
    }
}
