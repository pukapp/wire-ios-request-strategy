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
import Promise

extension ZMTransportResponse: Error {}

public final class PromiseRequestStrategy: AbstractRequestStrategy {

    private struct RequestPromise {
        let request: ZMTransportRequest
        let promise: Promise<ZMTransportResponse>
    }
    
    private var requestPromises = [RequestPromise]()
    
    private func next() -> RequestPromise? {
        guard !requestPromises.isEmpty else { return nil }
        return requestPromises.removeFirst()
    }

    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        guard let requestPromise = next() else { return nil }
        requestPromise.request.add(ZMCompletionHandler(on: managedObjectContext) { response in
            if case .success = response.result {
                requestPromise.promise.fulfill(response)
            } else {
                requestPromise.promise.reject(response)
            }
        })
        return requestPromise.request
    }
    
    public func promise(for request: ZMTransportRequest) -> Promise<ZMTransportResponse> {
        let requestPromise = RequestPromise(request: request, promise: .init())
        requestPromises.append(requestPromise)
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
        return requestPromise.promise
    }
    
}

extension ZMTransportRequest {
    func promise(on queue: ZMSGroupQueue) -> Promise<ZMTransportResponse> {
        let promise = Promise<ZMTransportResponse>()
        add(ZMCompletionHandler(on: queue) { response in
            if case .success = response.result {
                promise.fulfill(response)
            } else {
                promise.reject(response)
            }
        })
        return promise
    }
}


public extension ZMTransportSession {
    func enqueue(_ request: ZMTransportRequest, on queue: ZMSGroupQueue) -> Promise<ZMTransportResponse> {
        let promise = request.promise(on: queue)
        enqueueOneTime(request)
        return promise
    }
}
