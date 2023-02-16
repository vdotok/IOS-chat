//  
//  ChatScreenViewModel.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 18/05/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import Foundation
import iOSSDKConnect

enum CellType {
    case incomingText
    case outGoingText
    case incomingAttachment
    case outgoingAttachment
    case incomingAudio
    case outgoingAudio
    case incomingImage
    case outGoingImage
}

enum MediaType: Int {
    case image
    case audio
    case video
    case file
}

class ReceiptModel: Receipt,Codable {
    var receiptType: Int
    var key: String
    var date: Double
    var messageId: String
    var from: String
    var to: String
    
    init(type: Int, key: String, date: Double, messageId: String, from: String, topic: String) {
        self.receiptType = type
        self.key = key
        self.date = date
        self.messageId = messageId
        self.from = from
        self.to = topic
    }
}

extension ReceiptType {
    func toImage() -> String? {
        switch self {
        case .sent:
            return ""
        case .delivered:
            return ""
        case .seen:
            return "Read"
        }
    }
}

struct Message2 {
    var data: String
    var cellType: CellType
}
typealias ChatScreenViewModelOutput = (ChatScreenViewModelImpl.Output) -> Void

protocol ChatScreenViewModelInput {
    
}

protocol ChatScreenViewModel: ChatScreenViewModelInput {
    var output: ChatScreenViewModelOutput? { get set}
    var messages: [ChatMessage] {get set}
    var group: Group {get set}
    var user: UserResponse {get set}
    var mqtt: ChatClient {get set}
    func viewModelDidLoad()
    func viewModelWillAppear()
    func messageCount() -> Int
    func sendMessage(text: String,subtype: Int?,type: String)
    func itemAt(row: Int) -> (ChatMessage, CellType)
    func receivedMessage(userInfo: [String: AnyObject])
    func dispatchPackage(start: Bool)
    func sendSeenMessage(message: ChatMessage, row: Int)
    func publish(file data: Data, with ext: String, type: Int)
    func uploadFileApi(with uploadData: Data?,type:String,fileExtension:String)
}

class ChatScreenViewModelImpl: ChatScreenViewModel, ChatScreenViewModelInput {
    
    private let router: ChatScreenRouter
    var mqtt: ChatClient
    var group: Group
    var output: ChatScreenViewModelOutput?
    var messages: [ChatMessage] = []
    var user: UserResponse
    
    init(router: ChatScreenRouter, client: ChatClient, group: Group, user: UserResponse, messages: [ChatMessage]){
        self.router = router
        self.mqtt = client
        self.group = group
        self.user = user
        self.messages = messages
        setupDelegate()
    }
    
    func viewModelDidLoad() {
        
    }
    
    func viewModelWillAppear() {
        
    }
    
    //For all of your viewBindings
    enum Output {
        case reload
        case showProgress
        case hideProgress
        case success
        case failure(message: String)
        case reloadCell(indexPath: IndexPath)
    }
    
    func sendMessage(text: String,subtype: Int?,type: String) {
        let now = Date()
        let timeInterval = now.millisecondsSince1970
        let message = MessageModel(id: UUID().uuidString,
                                   to: group.channelName,
                                   key: group.channelKey,
                                   from: user.refID!,
                                   type: type,
                                   content: text.prefix(400).description,
                                   size: 0,
                                   isGroupMessage: false,
                                   status: 0,
                                   subtype: subtype,
                                   date: timeInterval)
        mqtt.publish(message: message)
        dispatchPackage(start: false)
    }
    
    func setupDelegate() {
        mqtt.setReceiptAcknowledge(receiptAcknowledge: self)
        mqtt.setReceiptDelegate(receiptDelegate: self)
    }
    
    func receivedMessage(userInfo: [String: AnyObject]) {
        let content = userInfo[Constants.messageKey] as! String
        let username = userInfo[Constants.usernameKey] as! String
        let id = userInfo[Constants.idKey] as? String ?? UUID().uuidString
        let fileType = userInfo[Constants.fileKey] as? URL
        let mediaType = userInfo[Constants.mediaType] as? Int
        let date = userInfo[Constants.date] as! UInt64
        
        guard let topic = userInfo[Constants.topicKey] as? String,
              topic == group.channelName
        else { return }

        if content.contains("left") {
//            onlineUsers.removeAll(where: { $0 == username })
//            actionHandler?(.reloadOnlineUser)
//            actionHandler?(.reload)
            return
        } else if content.contains("joined"){
//            onlineUsers.append(username)
//            actionHandler?(.reload)
//            actionHandler?(.reloadOnlineUser)
            return
        }
        if content.isEmpty {
//            KRProgressHUD.dismiss()
            if let mediaType = mediaType {
                messages.append(ChatMessage(id: id, sender: username, content: "", status: user.refID == username ? .sent : .delivered, fileType: fileType, mediaType: MediaType(rawValue: mediaType), date: date))
            } else {
                messages.append(ChatMessage(id: id, sender: username, content: "", status: .delivered, fileType: fileType, date: date))
            }
           
            output?(.reload)
            
            return
        }

        let chatMessage = ChatMessage(id: id,sender: username, content: content, status: user.refID == username ? .sent :.delivered, date: date)
        messages.append(chatMessage)
       
        self.output?(.reload)
        
    }
    
    func dispatchPackage(start: Bool = false) {
        if start {
            let messageModel = MessageModel(id: UUID().uuidString,
                                            to: group.channelName,
                                            key: group.channelKey,
                                            from: user.refID!,
                                            type: "typing",
                                            content: "1",
                                            size: 0,
                                            isGroupMessage: false,
                                            status: 0,
                                            subtype: nil,
                                            date: 1622801248314)
            self.mqtt.publish(message: messageModel)
        } else {
            let messageModel = MessageModel(id: UUID().uuidString,
                                            to: group.channelName,
                                            key: group.channelKey,
                                            from: user.refID!,
                                            type: "typing",
                                            content: "0",
                                            size: 0,
                                            isGroupMessage: false,
                                            status: 0,
                                            subtype: nil,
                                            date: 1622801248314)
            self.mqtt.publish(message: messageModel)
        }
        
    }
    
    func sendSeenMessage(message: ChatMessage, row: Int) {
        
        if message.status == .delivered  {
            let receipt = ReceiptModel(type: ReceiptType.seen.rawValue,
                                       key: group.channelKey, date: 1622801248314,
                                       messageId: message.id,
                                       from: user.fullName!,
                                       topic: group.channelName)
            if user.fullName != message.sender {
                self.messages[row].status = .seen
            }
    
                self.send(receipt: receipt, status: .seen, isMyMessage: user.fullName == message.sender)
        }
        
        
    }
    
}

extension ChatScreenViewModelImpl {
    func itemAt(row: Int) -> (ChatMessage,CellType) {
        
        if messages[row].sender != user.refID && messages[row].content == "" {
            
            switch messages[row].mediaType {
            case .image:
                return (messages[row], .incomingImage)
            case .file:
                return (messages[row], .incomingAttachment)
            case .video:
                return (messages[row], .incomingAttachment)
            case .audio:
                return (messages[row], .incomingAttachment)
            default:
                break
            }
           
        } else if messages[row].sender == user.refID && messages[row].content == ""  {
            
            switch messages[row].mediaType {
            case .image:
                return (messages[row], .outGoingImage)
            case .file:
                return (messages[row], .outgoingAttachment)
            case .video:
                return (messages[row], .outgoingAttachment)
            case .audio:
                return (messages[row], .outgoingAttachment)
            default:
                break
            }
        }
        if messages[row].sender == user.refID {
            return (messages[row], .outGoingText)
        }else {
            return (messages[row], .incomingText)
        }
    }
    
    func messageCount() -> Int {
        return messages.count
    }
}

extension ChatScreenViewModelImpl: ReceiptDelegate, ReceiptAcknowledge {
    
    func send(receipt: Receipt, status: ReceiptType, isMyMessage: Bool) {
        guard !isMyMessage else {return}
        mqtt.publish(receipt: receipt)
        print("send receipt \(status) \(receipt.from)")
    }
    
    func didReceive(receipt: Receipt, status: ReceiptType) {
        print("didReceive receipt \(status) \(receipt.from)")
        guard user.fullName != receipt.from, let messageIndex = self.messages.firstIndex(where: {$0.id == receipt.messageId}) else {return}
        if  user.refID != receipt.from {
            messages[messageIndex].status = status
            self.output?(.reloadCell(indexPath: IndexPath(row: messageIndex, section: 0)))
        }
       
    }
    
}

extension ChatScreenViewModelImpl {
    func publish(file data: Data, with ext: String, type: Int) {
        let now = Date()
        let timeInterval = now.millisecondsSince1970
        mqtt.publish(file: data, fileExt: ext, topic: group.channelName, key: group.channelKey, from: user.refID!, type: type, date: timeInterval)
    }
    
    func uploadFileApi(with uploadData: Data?,type:String,fileExtension:String) {
        output?(.showProgress)
        guard let user = VDOTOKObject<UserResponse>().getData() else {return}
        var param = [String : String] ()
        param["auth_token"] = user.authToken?.description
        param["type"] = "ftp"
        param["extension"] = fileExtension
        let url = "https://q-tenant.vdotok.dev/s3upload/"
        let request = MultipartFormDataRequest(url: URL(string: url)!,param: param,filePathKey: "uploadFile",imageDataKey: uploadData!,boundary: generateBoundaryString(),type:type)
        let task =  URLSession.shared.dataTask(with: request.asURLRequest()) { [self] data, response, error in
                guard let data = data, error == nil else {
                    print(error?.localizedDescription)
                    return
                }
                do {
                    output?(.hideProgress)
                    let res = try JSONDecoder().decode(UploadFileResponse.self, from: data)
                    var fileExtension = res.filetype?.split(separator: "/")
                    var subtype:Int = 0
                    if fileExtension?.last == "mp4" || fileExtension?.last == "mov" {
                       subtype = 2
                    }else if fileExtension?.last == "png" || fileExtension?.last == "jpeg" || fileExtension?.last == "jpg" {
                       subtype = 0
                    }else {
                       subtype = 3
                    }
                    self.sendMessage(text:res.file_name!.description,subtype:subtype,type:"ftp")
                    
                    
                } catch let parseError {
                    print("JSON Error \(parseError.localizedDescription)")
                }
            }
            
            task.resume()
    }
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
}
