//  
//  GroupsViewModel.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 06/05/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import Foundation
import iOSSDKConnect
import UIKit


class ChatMessage {
    let id: String
    let sender: String
    let content: String
    var status: ReceiptType
    var fileType: URL?
    var mediaType: MediaType?
    var date: UInt64
    var readCount :Int
    var readParticipant:[String]
    
    
    init(id: String, sender: String, content: String, status: ReceiptType, fileType: URL? = nil, mediaType: MediaType? = nil, date: UInt64,readCount: Int = 0,readParticipant :[String] = []) {
        self.id = id
        self.sender = sender
        self.content = content
        self.status = status
        self.fileType = fileType
        self.mediaType = mediaType
        self.date = date
        self.readCount = readCount
        self.readParticipant = readParticipant
    }
}

class AvailableModel: Available, Codable {
    internal init(key: String, channel: String, changes: Bool, status: Bool) {
        self.key = key
        self.channel = channel
        self.changes = changes
        self.status = status
    }
    
    var key: String
    var channel: String
    var changes: Bool
    var status: Bool
}


struct TempGroup {
    let group: Group
    let unReadMessageCount: Int
    let lastMessage: String
    let presentParticipant: Int
}


typealias GroupsViewModelOutput = (GroupsViewModelImpl.Output) -> Void

protocol GroupsViewModelInput {
    func filterGroups(with text: String)
}

protocol GroupsViewModel: GroupsViewModelInput {
    var output: GroupsViewModelOutput? { get set}
    var groups: [Group] {get set}
    var searchGroup: [Group] {get set}
    var isSearching: Bool {get set}
    var mqttClient: ChatClient? {get set}
    var messages: [String: [ChatMessage]] {get set}
    var presentCandidates: [String: [String]] {get set}
    var unreadMessages:[String:[ChatMessage]] {get set}
    func viewModelDidLoad()
    func viewModelWillAppear()
    func fetchGroups()
    func subscribe(group: Group)
    func itemAt(row: Int) -> TempGroup
    func deleteGroup(with id: Int)
    func editGroup(with title: String, id: Int) 
}

class GroupsViewModelImpl: GroupsViewModel{
    private let router: GroupsRouter
    var output: GroupsViewModelOutput?
    var store: AllGroupStroreable
    var deleteStore: DeleteStoreable = DeleteService(service: NetworkService())
    var editStore: EditGroupStoreable = EditGroupService(service: NetworkService())
    var mqttClient: ChatClient?
    var groups: [Group] = []
    var searchGroup: [Group] = []
    var isSearching: Bool = false
    var presentCandidates: [String: [String]] = [:]
    var messages: [String: [ChatMessage]] = [:]
    var unreadMessages:[String:[ChatMessage]] = [:]
    
    init(router: GroupsRouter, store: AllGroupStroreable = AllGroupService(service: NetworkService()) ) {
        self.router = router
        self.store = store
        
    }
    
    func viewModelDidLoad() {
        if (!AuthenticationConstants.TENANTSERVER.isEmpty && !AuthenticationConstants.PROJECTID.isEmpty) {
             UserDefaults.baseUrl = AuthenticationConstants.TENANTSERVER
             UserDefaults.projectId = AuthenticationConstants.PROJECTID
          } else {
            AuthenticationConstants.TENANTSERVER =  UserDefaults.baseUrl
            AuthenticationConstants.PROJECTID = UserDefaults.projectId
        }
        self.conncectMqtt()
        fetchGroups()
    }
    
    private func conncectMqtt() {
       guard let user = VDOTOKObject<UserResponse>().getData(),
              let host = user.messagingServerMap?.host,
              let serverPort = user.messagingServerMap?.port,
              let port = UInt16(serverPort)
        else {return}
        let userName = user.refID
        let password = user.authorizationToken
        
        let client = Client(port: port,
                            host:host,
                            userName: userName!,
                            password: password!,
                            reConnectivity: true)
       mqttClient = ChatClient(client: client, presense: self, connectivity: self, messageDelegate: self, customPacketDelegate: self,groupNotificationDelagte: self)
        mqttClient?.connect()
        setDelegate()
    }
    
    
    func setDelegate(){
        mqttClient?.setFileDelegate(fileDelegate: self)
    }
    
    func viewModelWillAppear() {
        output?(.reload)
    }
    
    //For all of your viewBindings
    enum Output {
        case reload
        case showProgress
        case hideProgress
        case connected
        case disconnected
        case failure(message: String)
    }
    
    
    func sendGroupNotification(groupModel: CreateGroupResponse, toUsers: [String], action: GroupNotificationAction){
        
        guard let myUser = VDOTOKObject<UserResponse>().getData() else {return}
        
        let model = GroupNotification(action: action.rawValue, groupModel: groupModel)
        let createModel = CreateGroupNotification(from: myUser.refID!, data: model, to: toUsers)
        let jsonData = try! JSONEncoder().encode(createModel)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        self.mqttClient?.sendGroupNotification(data: jsonString)
    }
}

extension GroupsViewModelImpl {
    func fetchGroups() {
        let request = AllGroupRequest()
        //self.output?(.showProgress)
        store.fetchGroups(with: request) { [weak self] (response) in
            guard let self = self else {return}
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
//                self.output?(.hideProgress)
//            })
            
            switch response {
            case .success(let response):
                switch response.status {
                case 503:
                    self.output?(.failure(message: response.message ))
                case 500:
                    self.output?(.failure(message: response.message))
                case 401:
                    self.output?(.failure(message: response.message))
                case 200:
                    if self.mqttClient?.isConnected() ?? false {
                        if response.groups?.count == self.groups.count {
                            self.groups = response.groups ?? []
                        }
                        else {
                            guard let fetchedGroups = response.groups  else { return }
                            let channelKeys = self.groups.map({$0.channelKey})
                            let newGroups = fetchedGroups.filter({!channelKeys.contains($0.channelKey)})
                            self.subscribe(groups: newGroups)
                            self.groups = response.groups ?? []
                        }
                        DispatchQueue.main.async {
                            self.output?(.reload)
                        }
                       
                        
                    }else {
                        self.conncectMqtt()
                        self.groups = response.groups ?? []
                        DispatchQueue.main.async {
                            self.output?(.reload)
                        }
                    }
                    
                default:
                    break
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}

extension GroupsViewModelImpl: GroupsViewModelInput  {
    func filterGroups(with text: String) {
        self.searchGroup = groups.filter({$0.groupTitle.lowercased().prefix(text.count) == text.lowercased()})
        output?(.reload)
    }

}

extension GroupsViewModelImpl: Connectivity {
    func willConnect() {
       
    }
    
    func didConnect() {
        
    }
    
    func didSubscribe(topics: [String]) {
        let channelArray = topics[0].components(separatedBy: "/")
        print(channelArray)
        let presence = Constants.presence
        let availabe = AvailableModel(key: channelArray[0],
                                      channel: channelArray[1] + "/",
                                      changes: true,
                                      status: true)
        mqttClient?.presense(topic: presence, presense: availabe)
    }
    
    func didUnSubscribe(topic: String) {
        
    }
    
    func connectionState(status: ConnectionStatus) {
        print(status)
        switch status {
        case .CONNECTED:
            print("Connected")
            output?(.connected)
            subscribe(groups: groups)
        case .DISCONNECTED:
            output?(.disconnected)
            print("disconncted")
        case .TIMEOUT:
            self.conncectMqtt()
        }
    }
    
    func didFailToConnect(_ erorr: Error) {
    }
    
    func willReconnect() {
        
    }
    
    func didReconnect() {
        
    }
    
  
}

extension GroupsViewModelImpl: CustomPacketDelegate {
    func didRecieveJson(data: Data, topic: String) {
        
    }
    
    func didRecieveCustom(packet: String, topic: String) {
        
    }
    
}

extension GroupsViewModelImpl: PresenceStates, GroupNotificationStates {
    
    func send(presence: [Presence]) {
        self.sendPresence(presence: presence)
    }
    
    func didSend(presence: [Presence]) {
        
    }
    
    func didFailToSend(reason: String) {
        
    }
    
    // GroupNotificationStates callbacks
    func receivedGroupNotificationData(data: String) {
        let decoder = JSONDecoder()
        do {
            let groupNotification = try decoder.decode(ReceivedGroupNotification.self, from: Data(data.utf8))
            print(groupNotification)
            let groupmodel = groupNotification.data.groupModel!
            switch groupNotification.data.action {
                
                case GroupNotificationAction.new.rawValue:
                    handleNewGroupCreated(groupModel: groupmodel)
                case GroupNotificationAction.modify.rawValue:
                    handleGroupModified(groupModel: groupmodel)
                case GroupNotificationAction.delete.rawValue:
                    handleGroupDeleted(groupModel: groupmodel)
                default:
                    break
            }
        } catch {print(error.localizedDescription)}
    }
    
    func handleNewGroupCreated(groupModel: CreateGroupResponse){
        if self.groups.first(where: { $0.id == groupModel.group!.id }) == nil {
            self.groups.insert(groupModel.group!, at: 0)
            subscribe(group: groupModel.group!)
            DispatchQueue.main.async {
                self.output?(.reload)
            }
        }
    }
    
    func handleGroupModified(groupModel: CreateGroupResponse){
        let index = self.groups.firstIndex(where: {$0.id == groupModel.group!.id}) ?? -1
        if(index >= 0){
            self.groups.remove(at: index)
            self.groups.insert(groupModel.group!, at: index)
            DispatchQueue.main.async {
                self.output?(.reload)
            }
        }
    }
    
    func handleGroupDeleted(groupModel: CreateGroupResponse){
        self.groups.removeAll(where: {$0.id == groupModel.group!.id})
        DispatchQueue.main.async {
            self.output?(.reload)
        }
    }
    
}

extension GroupsViewModelImpl: MessageDelegate {
    func onMessageReceive(_ message: Message) {
        guard let user = VDOTOKObject<UserResponse>().getData() else {return}
        var topic = message.to
        if message.to.split(separator: "/").count > 1 {
            topic = message.to.split(separator: "/")[1] + "/"
        }
        
        if message.type == "text" {
        
        var tempMessages: [ChatMessage] = []
        var unreadMessages: [ChatMessage] = []
        
            let receipt = ReceiptModel(type: ReceiptType.delivered.rawValue, key: message.key, date: 1622801248314, messageId: message.id, from: user.refID!, topic: message.to)
            
            self.send(receipt: receipt, status: .delivered, isMyMessage: user.refID == message.from)
            let name = NSNotification.Name(rawValue: "MQTTMessageNotification" + user.fullName!)
            NotificationCenter.default.post(name: name, object: self,
                                            userInfo: [Constants.messageKey: message.content,
                                                       Constants.topicKey: topic,
                                                       Constants.usernameKey: message.from,
                                                       Constants.idKey: message.id,
                                                       Constants.date: message.date
                                            ])
            
            tempMessages = messages[topic] ?? []
            unreadMessages = self.unreadMessages[topic] ?? []
            tempMessages.append(ChatMessage(id: message.id, sender: message.from, content: message.content, status: .delivered, date: message.date ,readCount:0))
            unreadMessages.append(ChatMessage(id: message.id, sender: message.from, content: message.content, status: .delivered, date: message.date ,readCount:0))
            messages[topic] = tempMessages
            self.unreadMessages[topic] = unreadMessages
          
            output?(.reload)
            
        }else if message.type == "ftp"{
            guard let user = VDOTOKObject<UserResponse>().getData() else {return}
            //let data = Data(bytes: file.content, count: .content.count)
            let messageFile = ChatMessage(id: message.id, sender: message.from, content: "", status: .delivered, mediaType:MediaType(rawValue: message.subType!), date:1622801248314, readCount:0)
            messageFile.fileType = URL(string:message.content)
    
            var tempMessages: [ChatMessage] = []
            var unreadMessages: [ChatMessage] = []
            
            unreadMessages = self.unreadMessages[topic ?? ""] ?? []
            tempMessages = messages[topic ?? ""] ?? []
            tempMessages.append(messageFile)
            unreadMessages.append(ChatMessage(id: messageFile.id, sender: messageFile.sender, content: messageFile.content, status: .delivered, date: message.date,readCount:0 ))
            messages[topic ?? ""] = tempMessages
            self.unreadMessages[topic ?? ""] = unreadMessages
            let receipt = ReceiptModel(type: ReceiptType.delivered.rawValue, key: message.key, date: 1622801248314, messageId: message.id, from: user.refID!,  topic: topic ?? "")
            self.send(receipt: receipt, status: .delivered, isMyMessage: user.refID == message.from)
            let name = NSNotification.Name(rawValue: "MQTTMessageNotification" + user.fullName!)
            NotificationCenter.default.post(name: name, object: self,
                                            userInfo: [Constants.messageKey: "",
                                                       Constants.topicKey: topic,
                                                       Constants.usernameKey: message.from,
                                                       Constants.idKey: messageFile.id,
                                                       Constants.fileKey: messageFile.fileType,
                                                       Constants.mediaType: message.subType,
                                                       Constants.date: message.date
                                                       
                                            ])
            output?(.reload)
        }
    }
    
    func onMessagePublish(_ playloadString: String, topic: String) {
        
    }
    
    func didStartTyping(_ message: Message) {
        print(message)
        guard let user = VDOTOKObject<UserResponse>().getData(), let fullName = user.fullName else { return }
        NotificationCenter.default.post(name: NSNotification.Name("didStartTyping" + fullName),
                                        object: self,
                                        userInfo: [Constants.messageKey : message.from,
                                                   "topic": message.to])
    }
    
    func didEndTyping(_ message: Message) {
        print(message)
        guard let user = VDOTOKObject<UserResponse>().getData(), let fullName = user.fullName else { return }
        NotificationCenter.default.post(name: NSNotification.Name("didEndTyping" + fullName),
                                        object: self,
                                        userInfo: [Constants.messageKey : message.from,
                                                   "topic": message.to])
    }
    
    
}


extension GroupsViewModelImpl {
    private func subscribe(groups: [Group]) {
        let topics = groups.map({ $0.channelKey + "/" + $0.channelName})
        for topic in topics {
            mqttClient?.subscribe(topic: topic)
        }
    }
    
    func subscribe(group: Group) {
        subscribe(groups: [group])
    }
    
    func sendPresence(presence: [Presence]) {
        guard let myUser = VDOTOKObject<UserResponse>().getData() else {return}
        
        let filterPresence = removeDuplicateElements(posts: presence)
        let channel = presence.first?.channel ?? ""
        let name = NSNotification.Name(rawValue: "MQTTMessageNotification" + "test")
        for user in filterPresence {
            NotificationCenter.default.post(name: name,
                                            object: self,
                                            userInfo: [Constants.messageKey: "\(user.username) \(user.type ?? "joined")",
                                                       Constants.topicKey: channel,
                                                       Constants.usernameKey: user.username])
            var users: [String] = []
            if user.type == "joined" {
                
                guard presentCandidates[channel]?.filter({$0 == user.username}).count ?? 0 < 1 else {return}
                users = presentCandidates[channel] ?? []
                users.append(user.username)
                users.removeAll(where: {$0 == myUser.refID})
                presentCandidates[channel]?.removeAll()
                presentCandidates[channel] = users
                
            } else if user.type == "left" {
                users = presentCandidates[channel] ?? []
                users.removeAll(where: { $0 == user.username })
                presentCandidates[channel]?.removeAll()
                presentCandidates[channel] = users
            }
            print(presentCandidates.map({ $0.value.map({ $0 })}))
        }
        output?(.reload)
//        actionHandler?(.reload)
    }
}

extension GroupsViewModelImpl {
    func send(receipt: Receipt, status: ReceiptType, isMyMessage: Bool) {
        guard !isMyMessage else {return}
        mqttClient?.publish(receipt: receipt)
        print("send receipt \(status) \(receipt.from)")
    }
    
    
    func itemAt(row: Int) -> TempGroup {
        let channel = groups[row].channelName
        let present = presentCandidates[channel]
        let topic =  messages[channel]
        let unReadmessages = unreadMessages[channel]
        var lastMessage = ""
        if unReadmessages?.count ?? 0 >= 1 {
            lastMessage = "Misread messages"
        }
        
        else {
            if let message = topic?.last?.content {
                lastMessage = message
            }
            if let _ = topic?.last?.fileType {
                lastMessage = "Attachment"
            }
               
        }
        
        let group = TempGroup(group: groups[row], unReadMessageCount: unReadmessages?.count ?? 0, lastMessage: lastMessage, presentParticipant: present?.count ?? 0)
        
        return group
    }
    
}

func removeDuplicateElements(posts: [Presence]) -> [Presence] {
    var uniquePosts = [Presence]()
    for post in posts {
        if !uniquePosts.contains(where: {$0.username == post.username }) {
            uniquePosts.append(post)
        }
    }
    return uniquePosts
}

extension GroupsViewModelImpl: FileDelegate {
    func didReceive(file: FilePart, fileURL: URL, date: UInt64) {
        guard let user = VDOTOKObject<UserResponse>().getData() else {return}
        let data = Data(bytes: file.content, count: file.content.count)
        let message = ChatMessage(id: file.messageId, sender: file.from, content: "", status: .delivered, mediaType: MediaType(rawValue: file.type), date: date,readCount:0)
        message.fileType = fileURL
        var tempMessages: [ChatMessage] = []
        var unreadMessages: [ChatMessage] = []
        
        unreadMessages = self.unreadMessages[file.topic ?? ""] ?? []
        tempMessages = messages[file.topic ?? ""] ?? []
        tempMessages.append(message)
        unreadMessages.append(ChatMessage(id: message.id, sender: message.sender, content: message.content, status: .delivered, date: message.date,readCount:0 ))
        messages[file.topic ?? ""] = tempMessages
        self.unreadMessages[file.topic ?? ""] = unreadMessages
        let receipt = ReceiptModel(type: ReceiptType.delivered.rawValue, key: file.key, date: 1622801248314, messageId: file.messageId, from: user.refID!, topic: file.topic ?? "")
        
        self.send(receipt: receipt, status: .delivered, isMyMessage: user.refID == file.from)
           
            
        let name = NSNotification.Name(rawValue: "MQTTMessageNotification" + user.fullName!)
        NotificationCenter.default.post(name: name, object: self,
                                        userInfo: [Constants.messageKey: "",
                                                   Constants.topicKey: file.topic,
                                                   Constants.usernameKey: file.from,
                                                   Constants.idKey: message.id,
                                                   Constants.fileKey: message.fileType,
                                                   Constants.mediaType: file.type,
                                                   Constants.date: date
                                                   
                                        ])
        output?(.reload)
    }
    
    func didReceive(header: Header) {
        
    }

}

extension GroupsViewModelImpl {
    func deleteGroup(with id: Int) {
        output?(.showProgress)
        let request = DeleteGroupRequest(group_id: groups[id].id)
        deleteStore.delete(with: request) { [weak self] response in
            self?.output?(.hideProgress)
            switch response {
            case .success(let response):
                DispatchQueue.main.async {
                    switch response.status {
                    case 503:
                        self?.output?(.failure(message: response.message))
                    case 500:
                        self?.output?(.failure(message: response.message))
                    case 401:
                        self?.output?(.failure(message: response.message))
                    case 600:
                        self?.output?(.failure(message: response.message))
                    case 200:
                    guard let deletedGroup = self?.groups[id] else {return}
                        let groupModel = CreateGroupResponse(group: self?.groups[id], message: response.message, processTime: response.processTime, status:response.status, isalreadyCreated: true)
                    self?.sendGroupNotification(groupModel: groupModel, toUsers: deletedGroup.getParticipantsIds(), action: GroupNotificationAction.delete)
                    self?.groups.remove(at: id)
                    self?.output?(.reload)
                    default:
                    break
                    }
                }
                
                print("\(response)")
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func editGroup(with title: String, id: Int) {
        guard  groups[id].participants.count != 1 else {
            output?(.failure(message: "one to one group name cannot be updated"))
            return
        }
        output?(.showProgress)
        let request = EditGroupRequest(group_title: title, group_id: groups[id].id)
        editStore.editGroup(with: request) { [weak self] result in
            
            self?.output?(.hideProgress)
            switch result {
            case .success(let result):
                self?.groups[id].groupTitle = title
                guard let editedGroup = self?.groups[id] else {return}
                let groupModel = CreateGroupResponse(group: self?.groups[id], message: result.message, processTime: result.processTime, status:result.status, isalreadyCreated: true)
                self?.sendGroupNotification(groupModel: groupModel, toUsers: editedGroup.getParticipantsIds(), action: GroupNotificationAction.modify)
                DispatchQueue.main.async {
                    self?.output?(.reload)
                }
               
            case .failure(let error):
                print(error)
                
            }
        }
    }
}
