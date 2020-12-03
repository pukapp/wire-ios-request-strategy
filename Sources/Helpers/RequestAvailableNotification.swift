//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation


private let RequestsAvailableNotificationName = "RequestAvailableNotification"
private let MsgRequestsAvailableNotificationName = "UIRequestAvailableNotification"
private let ExtensionStreamRequestsAvailableNotificationName = "ExtensionStreamRequestsAvailableNotificationName"
private let ExtensionSingleRequestsAvailableNotificationName = "ExtensionSingleRequestsAvailableNotificationName"

@objc(ZMRequestAvailableObserver) public protocol RequestAvailableObserver : NSObjectProtocol {
    
    func newRequestsAvailable()
    
    func newMsgRequestsAvailable()
    
    func newExtensionStreamRequestsAvailable()
    
    func newExtensionSingleRequestsAvailable()
    
}

/// ZMRequestAvailableNotification is used by request strategies to signal the operation loop that
/// there are new potential requests available to process.
@objc(ZMRequestAvailableNotification) public class RequestAvailableNotification : NSObject {
    
    @objc public static func notifyNewRequestsAvailable(_ sender: NSObjectProtocol?) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: RequestsAvailableNotificationName), object: nil)
    }
    
    @objc public static func extensionStreamNotifyNewRequestsAvailable(_ sender: NSObjectProtocol?) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: ExtensionStreamRequestsAvailableNotificationName), object: nil)
    }
    
    @objc public static func extensionSingleNotifyNewRequestsAvailable(_ sender: NSObjectProtocol?) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: ExtensionSingleRequestsAvailableNotificationName), object: nil)
    }
    
    @objc public static func msgNotifyNewRequestsAvailable(_ sender: NSObjectProtocol?) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: MsgRequestsAvailableNotificationName), object: nil)
    }
    
    @objc public static func addObserver(_ observer: RequestAvailableObserver) {
        NotificationCenter.default.addObserver(observer, selector: #selector(RequestAvailableObserver.newRequestsAvailable), name: NSNotification.Name(rawValue: RequestsAvailableNotificationName), object: nil)
    }
    
    @objc public static func removeObserver(_ observer: RequestAvailableObserver) {
        NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: RequestsAvailableNotificationName), object: nil)
    }
    
    @objc public static func addMsgObserver(_ observer: RequestAvailableObserver) {
        NotificationCenter.default.addObserver(observer, selector: #selector(RequestAvailableObserver.newMsgRequestsAvailable), name: NSNotification.Name(rawValue: MsgRequestsAvailableNotificationName), object: nil)
    }
    
    @objc public static func removeUIObserver(_ observer: RequestAvailableObserver) {
        NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: MsgRequestsAvailableNotificationName), object: nil)
    }
    
    @objc public static func addExtensionStreamObserver(_ observer: RequestAvailableObserver) {
        NotificationCenter.default.addObserver(observer, selector: #selector(RequestAvailableObserver.newExtensionStreamRequestsAvailable), name: NSNotification.Name(rawValue: ExtensionStreamRequestsAvailableNotificationName), object: nil)
    }
    
    @objc public static func removeExtensionStreamObserver(_ observer: RequestAvailableObserver) {
        NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: ExtensionStreamRequestsAvailableNotificationName), object: nil)
    }
    
    @objc public static func addExtensionSingleObserver(_ observer: RequestAvailableObserver) {
        NotificationCenter.default.addObserver(observer, selector: #selector(RequestAvailableObserver.newExtensionSingleRequestsAvailable), name: NSNotification.Name(rawValue: ExtensionSingleRequestsAvailableNotificationName), object: nil)
    }
    
    @objc public static func removeExtensionSingleObserver(_ observer: RequestAvailableObserver) {
        NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: ExtensionSingleRequestsAvailableNotificationName), object: nil)
    }
    
    
    
}
