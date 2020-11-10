//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

/// Holds a list of received event IDs
@objc
public protocol PreviouslyReceivedEventIDsCollection: NSObjectProtocol {
    func discardListOfAlreadyReceivedPushEventIDs()
}

@objc
public protocol UpdateEventProcessor: class {
    @objc(decryptUpdateEventsAndGenerateNotification:)
    func decryptUpdateEventsAndGenerateNotification(_ updateEvents: [ZMUpdateEvent])
    
    @objc(processUpdateEvents:)
    func processUpdateEvents(_ updateEvents: [ZMUpdateEvent])
}

public protocol NotificationStreamSyncDelegate: class {
    func fetchedEvents(_ events: [ZMUpdateEvent])
    func failedFetchingEvents()
}

public class NotificationStreamSync: NSObject, ZMRequestGenerator, ZMSingleRequestTranscoder {
    
    public var fetchNotificationSync: ZMSingleRequestSync!
    private unowned var managedObjectContext: NSManagedObjectContext!
    private weak var notificationStreamSyncDelegate: NotificationStreamSyncDelegate?
    
    deinit {
        print("NotificationStreamSync deinit")
    }

    public init(moc: NSManagedObjectContext,
                notificationsTracker: NotificationsTracker? = nil,
                delegate: NotificationStreamSyncDelegate) {
        super.init()
        managedObjectContext = moc
        fetchNotificationSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: moc)
        fetchNotificationSync.readyForNextRequest()
        notificationStreamSyncDelegate = delegate
    }
    
    public func nextRequest() -> ZMTransportRequest? {
        return fetchNotificationSync.nextRequest()
    }
    
    public func request(for sync: ZMSingleRequestSync) -> ZMTransportRequest? {
        let clientIdentifier = ZMUser.selfUser(in: self.managedObjectContext).selfClient()?.remoteIdentifier
        guard let cid = clientIdentifier else {return nil}
        var queryItems = [URLQueryItem]()
        let sizeItem = URLQueryItem(name: "size", value: "50")
        var startKeyItem: URLQueryItem?
        if let lastid = self.managedObjectContext.zm_lastNotificationID?.transportString() {
            startKeyItem = URLQueryItem(name: "since", value:lastid)
        }
        let cidItem = URLQueryItem(name: "client", value: cid)
        if let startItem = startKeyItem {
            queryItems.append(startItem)
        }
        queryItems.append(sizeItem)
        queryItems.append(cidItem)
        var components = URLComponents(string: "/notifications/user")
        components?.queryItems = queryItems
        guard let compString = components?.string else {return nil}
        let request = ZMTransportRequest(getFromPath: compString)
        return request
    }
    
    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        if let timestamp = response.payload?.asDictionary()?["time"] {
            updateServerTimeDeltaWith(timestamp: timestamp as! String)
        }
        processUpdateEvents(from: response.payload)
    }
    
    @objc(processUpdateEventsFromPayload:)
    func processUpdateEvents(from payload: ZMTransportData?) {
        let source = ZMUpdateEventSource.pushNotification
        guard let eventsDictionaries = eventDictionariesFrom(payload: payload) else {
            return
        }
        var pEvents: [ZMUpdateEvent] = []
        for eventDictionary in eventsDictionaries {
            guard let events = ZMUpdateEvent.eventsArray(from: eventDictionary as ZMTransportData, source: source) else {
                return
            }
            pEvents.append(contentsOf: events)
        }
        notificationStreamSyncDelegate?.fetchedEvents(pEvents)
    }
}

// MARK: Private

extension NotificationStreamSync {
    private func updateServerTimeDeltaWith(timestamp: String) {
        let serverTime = NSDate(transport: timestamp)
        guard let serverTimeDelta = serverTime?.timeIntervalSinceNow else {
            return
        }
        self.managedObjectContext.serverTimeDelta = serverTimeDelta
    }
    
    private func eventDictionariesFrom(payload: ZMTransportData?) -> [[String: Any]]? {
        return payload?.asDictionary()?["notifications"] as? [[String: Any]]
    }
}
