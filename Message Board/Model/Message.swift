import Foundation
import RealmSwift

class Message: Object {
    @objc dynamic var messageID = UUID().uuidString
    @objc dynamic var messagePeople:String = ""
    @objc dynamic var messageContent:String = ""
    @objc dynamic var updateTime:String = ""
    
    override static func primaryKey() -> String? {
        return "messageID"
    }
}
