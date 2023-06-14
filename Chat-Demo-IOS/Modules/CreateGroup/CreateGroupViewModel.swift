//  
//  CreateGroupViewModel.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 20/05/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import Foundation
import iOSSDKConnect

typealias CreateGroupViewModelOutput = (CreateGroupViewModelImpl.Output) -> Void

protocol CreateGroupViewModelInput {
    
}


protocol CreateGroupViewModel: CreateGroupViewModelInput {
    var output: CreateGroupViewModelOutput? { get set }
    var selectedItems:[String] {get set}
    var selectedItemsUserId:[Int]{get set}
    var contacts: [User] {get set}
    var isSearching: Bool {get set}
    var searchContacts: [User] {get set}
    var client: ChatClient {get set}
    func viewModelDidLoad()
    func viewModelWillAppear()
    func rowsCount() -> Int
    func viewModelItem(row: Int) -> User
    func filterGroups(with text: String)
    func deleteUser(id:String,userID:Int)
    func addUser(userId:Int, row: Int,refID:String)
    func check(id: String) -> Bool
    func createGroup(with title: String)
    func createGroup(with user: User)
}

class CreateGroupViewModelImpl: CreateGroupViewModel, CreateGroupViewModelInput {

    var contacts: [User] = []
    var isSearching: Bool = false
    private let router: CreateGroupRouter
    var output: CreateGroupViewModelOutput?
    var searchContacts: [User] = []
    var selectedItems = [String]()
    var selectedItemsUserId = [Int]()
    var client: ChatClient
    var groupStorable: GroupStorable = CreateGroupService(service: NetworkService())
    private let allUserStoreAble: AllUserStoreAble = AllUsersService(service: NetworkService())
    
    init(router: CreateGroupRouter, client: ChatClient) {
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
        case groupCreated(group: Group)
        case updateRow(index: Int)
        case failure(message: String)
    }
}

extension CreateGroupViewModelImpl {
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
    
    internal func deleteUser(id: String,userID:Int) {
        let index = selectedItemsUserId.firstIndex(of: userID)
        let refIndex = selectedItems.firstIndex(of: id)
        selectedItems.remove(at: refIndex!)
        selectedItemsUserId.remove(at: index!)
    }
    func addUser(userId:Int, row: Int,refID:String) {
        if selectedItemsUserId.contains(userId) {
           deleteUser(id: refID,userID: userId)
            output?(.updateRow(index: row))
        } else {
            if selectedItemsUserId.count == 4 {
                output?(.failure(message: "You can only select 4 participants"))
                return
                
            }
            selectedItemsUserId.append(userId)
            selectedItems.append(refID)
            output?(.updateRow(index: row))
        }
    }
    
    func check(id: String) -> Bool {
        selectedItems.contains(id) ? false : true
    }
    
    
    func createGroup(with title: String) {
        guard let myUser = VDOTOKObject<UserResponse>().getData() else {return}
        let groupNotification = Constants.groupNotification
    
        let request = CreateGroupRequest(groupTitle: title, participants: selectedItemsUserId)
        output?(.showProgress)
        groupStorable.createGroup(with: request) { [weak self] (result) in
            guard let self = self else {return }
            self.output?(.hideProgress)
            switch result {
            case .success(let response):
                guard let group = response.group else {return }
                self.sendGroupNotification(groupModel: response, toUser: self.selectedItems)
                DispatchQueue.main.async {
                    self.output?(.groupCreated(group: group))
                }


            case .failure(let error):
                DispatchQueue.main.async {
                    self.output?(.failure(message: error.localizedDescription))
                }
                print(error)
            }
        }
    }
    
    func createGroup(with user: User) {
        guard let myUser = VDOTOKObject<UserResponse>().getData() else {return}
        let groupName: String = myUser.fullName! + " - " + user.fullName
    
        let request = CreateGroupRequest(groupTitle: groupName, participants: [user.userID], autoCreated: 1)
        output?(.showProgress)
        groupStorable.createGroup(with: request) { [weak self] (result) in
            guard let self = self else {return}
            self.output?(.hideProgress)
            switch result {
            case .success(let response):
                guard let group = response.group else {return}
                self.sendGroupNotification(groupModel: response, toUser: [user.refID])
                DispatchQueue.main.async {
                    self.output?(.groupCreated(group: group))
                }
                
            case .failure(let error):
                self.output?(.failure(message: error.localizedDescription))
                
            }
        }
        
    }
    
    func sendGroupNotification(groupModel: CreateGroupResponse, toUser: [String]){
        guard let myUser = VDOTOKObject<UserResponse>().getData() else {return}
        
        let model = GroupNotification(action: GroupNotificationAction.new.rawValue, groupModel: groupModel)
        let createModel = CreateGroupNotification(from: myUser.refID!, data: model, to: toUser)
        let jsonData = try! JSONEncoder().encode(createModel)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        self.client.sendGroupNotification(data: jsonString)
    }
    
}
