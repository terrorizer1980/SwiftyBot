//
//  Response.swift
//  SwiftyBot
//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 - 2019 Fabrizio Brancati.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import BFKit
import Foundation
import Helper
import Vapor

/// Messenger response.
public struct Response: Content {
    /// Messaging type.
    public private(set) var messagingType: MessagingType
    /// Recipient.
    public private(set) var recipient: Recipient?
    /// Final response message.
    public private(set) var message: MessageResponse
    
    /// Coding keys, used by Codable protocol.
    private enum CodingKeys: String, CodingKey {
        case messagingType = "messaging_type"
        case recipient
        case message
    }
    
    public init() {
        messagingType = .response
        recipient = nil
        message = .text("Unknown error.")
    }
}

// MARK: - Response Extension

/// Response extension.
public extension Response {
    /// Declared in an extension to not override default `init` function.
    ///
    /// - Parameter request: Message request.
    /// - Throws: Decoding errors.
    mutating func create(for request: Request) throws -> Future<(MessageResponse, Vapor.Response)>? {
        /// Decode the request.
        let pageResponse = try request.content.syncDecode(PageRequest.self)
        /// Check that the request comes from a "page".
        guard pageResponse.object == "page" else {
            /// Throw an abort response, with a custom message.
            throw Abort(.badRequest, reason: "Message not generated by a page.")
        }
        
        var messageFuture: Future<MessageResponse>?
        
        /// For each entry in the response.
        for entry in pageResponse.entries {
            /// For each event in the entry.
            for event in entry.messages {
                /// Mark the message as seen.
                SenderAction(id: event.sender.id, action: .markSeen, on: request)
                
                /// If it's a postback action.
                if let postback = event.postback {
                    /// Check if it has a payload.
                    if let payload = postback.payload {
                        /// Check what type of payload it is.
                        switch payload {
                        /// It's a Get Started payload.
                        case GetStarted.defaultPayload:
                            /// Set the response message.
                            messageFuture = try createGreeting(for: event.sender.id, on: request)
                        /// By default it returns the sent payload.
                        default:
                            message = .text(payload)
                        }
                    /// There is no provided payload.
                    } else {
                        message = .text("No payload provided by developer.")
                    }
                /// If it's a normal message.
                } else if let message = event.message {
                    /// Check if the message is empty.
                    if message.text.isEmpty {
                        self.message = .text("I'm sorry but your message is empty 😢")
                    /// Check if the message has greetings.
                    } else if message.text.hasGreetings() {
                        /// Set the response message.
                        messageFuture = try createGreeting(for: event.sender.id, on: request)
                    /// Check if the message has "sell", "buy" or "shop" in its text.
                    } else if message.text.lowercased().contains("sell") || message.text.lowercased().contains("buy") || message.text.lowercased().contains("shop") {
                        /// Creates the payload with all the example elements.
                        let payload = Payload(templateType: .generic, elements: Element.allExamples)
                        /// Creates the attachment.
                        let attachment = Attachment(type: .template, payload: payload)
                        /// Finally creates the structured message.
                        let structuredMessage = StructuredMessage(attachment: attachment)
                        
                        self.message = .structured(structuredMessage)
                    /// It's a normal message, so reverse it.
                    } else {
                        self.message = .text(message.text.reversed(preserveFormat: true))
                    }
                /// If the message doent's exist.
                } else if event.message == nil {
                    message = .text("Webhook received unknown event.")
                }
                
                /// Set the recipient with the sender ID.
                recipient = Recipient(id: event.sender.id)
                
                /// Send the response to the Facebook Messenger APIs.
                guard let responseFuture = try? request.client().post("\(facebookGraphAPI)/\(messengerAPIVersion)/me/messages?access_token=\(messengerToken)", headers: ["Content-Type": "application/json"], beforeSend: { messageRequest in
                    try? messageRequest.content.encode(self)
                }) else {
                    return nil
                }
                
                return messageFuture?.and(responseFuture)
            }
        }
        
        return nil
    }
}

// MARK: - Response Greeting Extension

/// Response extension.
public extension Response {
    /// Create a greeting for a request.
    ///
    /// - Parameters:
    ///   - id: User ID.
    ///   - request: Messenger request.
    /// - Returns: Returns the message response.
    func createGreeting(for id: String, on request: Request) throws -> Future<MessageResponse> {
        /// Try to get the user first name.
        let messageResponse = try UserInfo(id: id).getInfo(on: request).map { userInfo -> MessageResponse in
            return MessageResponse.text("""
            Hi \(userInfo.firstName)!
            This is an example on how to create a bot with Swift.
            If you want to see more, try to send me "buy", "sell" or "shop".
            """)
        }
        
        return messageResponse
    }
}
