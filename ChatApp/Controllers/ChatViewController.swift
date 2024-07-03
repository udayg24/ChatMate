//
//  ChatViewController.swift
//  ChatApp
//
//  Created by Uday Gajera on 27/06/24.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType {
    var sender: any MessageKit.SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKit.MessageKind
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
            
        case .attributedText(_):
            return "attributedText"
            
        case .photo(_):
            return "photo"

        case .video(_):
            return "video"

        case .location(_):
            return "location"

        case .emoji(_):
            return "emoji"

        case .audio(_):
            return "audio"

        case .contact(_):
            return "contact"

        case .linkPreview(_):
            return "linkPreview"

        case .custom(_):
            return "custom"

        }
    }
}

struct Sender: SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}

class ChatViewController: MessagesViewController {
    
    public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var isNewConverstion = false
    private let otherUserEmail: String
    public let conversationId: String?

    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") else {
            return nil
        }
        return Sender(photoURL: "", senderId: email as! String, displayName: "John Doe")
    }

    init(with email: String, id: String?) {
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
        if let conversationId = conversationId {
            listenForMessages(id: conversationId)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        // Do any additional setup after loading the view.
    }
    
    private func listenForMessages(id: String) {
        DataBaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                
                
            case .failure(let error):
                print("failed to get messages")
            }
        })
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }

}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: " ").isEmpty,
        let selfSender = self.selfSender,
        let messageId = createMessageId() else {
            return
        }
        
        // send message
        if isNewConverstion {
            //create convo in database
            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
            
            DataBaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message, completion: { [weak self] success in
                if success {
                    print("message sent")
                } else {
                    print("failed to send")
                }
            })
        }
        else {
            //append to existing conversation database
        }
    }
    
    private func createMessageId() -> String? {
        let dateString = Self.dateFormatter.string(from: Date())
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeCurrentEmail = DataBaseManager.safeEmail(emailAddress: currentUserEmail)
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> any MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self sender is nil")
        return Sender(photoURL: "", senderId: "", displayName: "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> any MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        messages.count
    }
    
    
}
