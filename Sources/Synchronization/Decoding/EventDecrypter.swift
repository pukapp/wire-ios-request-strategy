//
//  EventDecrypter.swift
//  WireRequestStrategy
//
//  Created by 王杰 on 2020/9/18.
//  Copyright © 2020 Wire GmbH. All rights reserved.
//

import Foundation

@objcMembers public final class EventDecrypter: NSObject {
    
    unowned let syncMOC: NSManagedObjectContext
    let eventMoc: NSManagedObjectContext
    
    public init(syncMOC: NSManagedObjectContext, eventMoc: NSManagedObjectContext) {
        self.syncMOC = syncMOC
        self.eventMoc = eventMoc
        super.init()
    }
        
    /// Decrypted events
    @discardableResult
    public func decryptEvents(_ events: [ZMUpdateEvent]) -> [ZMUpdateEvent] {
        var decryptedEvents: [ZMUpdateEvent] = []
        syncMOC.zm_cryptKeyStore.encryptionContext.perform { [weak self] (sessionsDirectory) -> Void in
            guard let `self` = self else { return }
            decryptedEvents = events.compactMap { event -> ZMUpdateEvent? in
                if event.type == .conversationOtrMessageAdd || event.type == .conversationOtrAssetAdd {
                    return sessionsDirectory.decryptAndAddClient(event, in: self.syncMOC)
                } else {
                    return event
                }
            }
        }
        decryptedEvents.forEach { (event) in
            StoredUpdateEvent.createNSENotification(event, managedObjectContext: self.eventMoc, index: Int64(StoredUpdateEvent.NotificationIndexKey))
        }
        self.eventMoc.saveOrRollback()
        return decryptedEvents
    }
    
    deinit {
        print("EventDecrypter deinit")
    }
    
}
