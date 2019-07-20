//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireLinkPreview
import WireDataModel
import WireUtilities

public final class LinkAttachmentDetectorHelper : NSObject {
    fileprivate static var _test_debug_linkAttachmentDetector : LinkAttachmentDetectorType? = nil

    public class func defaultDetector() -> LinkAttachmentDetectorType {
        return test_debug_linkAttachmentDetector() ?? LinkAttachmentDetector()
    }

    public class func test_debug_linkAttachmentDetector() -> LinkAttachmentDetectorType? {
        return _test_debug_linkAttachmentDetector
    }

    public class func setTest_debug_linkAttachmentDetector(_ detectorType: LinkAttachmentDetectorType?) {
        _test_debug_linkAttachmentDetector = detectorType
    }

    public class func tearDown() {
        _test_debug_linkAttachmentDetector = nil
    }

}

@objcMembers public final class LinkAttachmentsPreprocessor : LinkPreprocessor<LinkAttachment> {

    fileprivate let linkAttachmentDetector: LinkAttachmentDetectorType

    public init(linkAttachmentDetector: LinkAttachmentDetectorType, managedObjectContext: NSManagedObjectContext) {
        self.linkAttachmentDetector = linkAttachmentDetector
        let log = ZMSLog(tag: "link-attachments")
        super.init(managedObjectContext: managedObjectContext, zmLog: log)
    }

    public override func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        let predicate = ZMMessage.predicateForMessagesThatNeedToUpdateLinkAttachments()
        return ZMClientMessage.sortedFetchRequest(with: predicate)
    }

    override func objectsToPreprocess(_ object: NSObject) -> ZMClientMessage? {
        guard let message = object as? ZMClientMessage else { return nil }
        return message.needsLinkAttachmentsUpdate ? message : nil
    }

    override func processLinks(in message: ZMClientMessage, text: String, excluding excludedRanges: [NSRange]) {
        linkAttachmentDetector.downloadLinkAttachments(inText: text, excluding: excludedRanges) { [weak self] linkAttachments in
            self?.managedObjectContext.performGroupedBlock {
                self?.zmLog.debug("\(linkAttachments.count) attachments for: \(message.nonce?.uuidString ?? "nil")\n\(linkAttachments)")
                self?.didProcessMessage(message, result: linkAttachments)
            }
        }
    }

    override func didProcessMessage(_ message: ZMClientMessage, result linkAttachments: [LinkAttachment]) {
        finishProcessing(message)
        
//        if !message.isObfuscated {
//            message.linkAttachments = linkAttachments
//        } else {
//            message.linkAttachments = []
//        }
            
        ///这里在显示消息的时候会针对每个文字消息进行解析，判断是否存在链接等特殊文字，并且修改数据库
        if linkAttachments.count > 0 && message.linkAttachments != nil {
            ///由于linkAttachments默认值为nil，所以这里增加了判断，只有当真的存在特殊链接的时候，才会对linkAttachments赋值，从而触发messageChangeInfo,刷新页面
            if !message.isObfuscated {
                message.linkAttachments = linkAttachments
            } else {
                message.linkAttachments = []
            }
        }
        
        message.needsLinkAttachmentsUpdate = false

        // The change processor is called as a response to a context save,
        // which is why we need to enque a save maually here
        managedObjectContext.enqueueDelayedSave()
    }

}
