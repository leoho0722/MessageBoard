 import UIKit
import RealmSwift
import IQKeyboardManagerSwift

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var messagePeopleLabel:UILabel!
    @IBOutlet weak var messagePeopleTextField:UITextField!
    @IBOutlet weak var messageContent:UITextView!
    @IBOutlet weak var lastestMessageLabel:UILabel!
    @IBOutlet weak var messageTableView:UITableView!
    @IBOutlet weak var sendMessageButton:UIButton!
    @IBOutlet weak var emptyView:UIView!
    
    var messageEditIng:Bool = false //用來判斷是否正在更新留言
    var people:String? = nil
    var content:String? = nil
    var messageIndexPathRow:Int = 0 //用來取得滑動的那一個 Row 的 IndexPath.row
    var messagePrimaryKey:String? = nil //用來取得滑動的那一個 Row 的資料 Primary Key
    var messagePeopleTmp = [String]() //用來暫存留言人的名稱
    var messageContentTmp = [String]() //用來暫存留言內容
        
    override func viewDidLoad() {
        super.viewDidLoad()
        messageTableView.backgroundView = emptyView
        messageTableView.backgroundView?.isHidden = true
        messageTableView.delegate = self
        messageTableView.dataSource = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func alert(message:String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "關閉", style: .cancel, handler: nil)
        alertController.addAction(closeAction)
        present(alertController,animated: true)
    }
    
    // MARK: - TableView DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let realm = try! Realm()
        let messageInfo = realm.objects(Message.self)
        if (messageInfo.count > 0) {
            tableView.backgroundView?.isHidden = true
            tableView.separatorStyle = .singleLine
            return messageInfo.count
        } else {
            tableView.backgroundView?.isHidden = false
            tableView.separatorStyle = .none
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = messageTableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageInfoTableViewCell
        let realm = try! Realm()
        let message = realm.objects(Message.self).sorted(byKeyPath: "updateTime", ascending: true)
        for messageInfo in message {
            self.messagePeopleTmp.append(messageInfo.messagePeople)
            self.messageContentTmp.append(messageInfo.messageContent)
        }
        if (message.count > 0) {
            cell.messagePeople.text = messagePeopleTmp[indexPath.row]
            cell.messageContent.text = messageContentTmp[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal, title: "編輯") { (action, sourceView, completeHandler) in
            self.messageIndexPathRow = indexPath.row
            self.messageEditIng = true
            self.messagePeopleTextField.isEnabled = false
            self.sendMessageButton.setTitle("更新留言", for: .normal)
            let realm = try! Realm()
            let updateMessage = realm.objects(Message.self).sorted(byKeyPath: "updateTime", ascending: true)
            self.messagePeopleTextField.text = updateMessage[self.messageIndexPathRow].messagePeople
            self.messageContent.text = updateMessage[self.messageIndexPathRow].messageContent
            self.messagePrimaryKey = updateMessage[self.messageIndexPathRow].messageID
            completeHandler(true)
        }
        editAction.backgroundColor = UIColor(red: 0.0/255.0, green: 127.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        let leadingSwipeConfiguration = UISwipeActionsConfiguration(actions: [editAction])
        return leadingSwipeConfiguration
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "刪除") { (action, sourceView, completeHandler) in
            self.messageIndexPathRow = indexPath.row
            self.getMessagePrimaryKey()
            let realm = try! Realm()
            let deleteMessage = realm.objects(Message.self).filter("messageID = '\(self.messagePrimaryKey!)'").first
            try! realm.write {
                realm.delete(deleteMessage!)
                self.messageAfterReLoadData(keyPath: "updateTime",ascending: true)
            }
            completeHandler(true)
        }
        let trailingSwipeConfiguration = UISwipeActionsConfiguration(actions: [deleteAction])
        return trailingSwipeConfiguration
    }
    
    // MARK: - 留言處理
    
    //取得該留言的 Primary Key
    func getMessagePrimaryKey() {
        let realm = try! Realm()
        let id = realm.objects(Message.self)
        if (id.count > 0) {
            self.messagePrimaryKey = id[self.messageIndexPathRow].messageID
        }
    }

    //取得送出留言時的當下時間
    func getSystemTime() -> String {
        let currectDate = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale.ReferenceType.system
        dateFormatter.timeZone = TimeZone.ReferenceType.system
        return dateFormatter.string(from: currectDate)
    }
    
    func saveMessage() {
        people = messagePeopleTextField.text!
        content = messageContent.text!
        let realm:Realm = try! Realm()
        let messageSave:Message = Message()
        messageSave.messagePeople = people!
        messageSave.messageContent = content!
        messageSave.updateTime = getSystemTime()
        try! realm.write {
            realm.add(messageSave)
        }
        print(realm.configuration.fileURL!)
    }

    func updateMessage() {
        let realm = try! Realm()
        let updateMessageInfo = Message()
        updateMessageInfo.messageID = self.messagePrimaryKey!
        updateMessageInfo.messagePeople = self.messagePeopleTextField.text!
        updateMessageInfo.messageContent = self.messageContent.text
        updateMessageInfo.updateTime = getSystemTime()
        try! realm.write {
            realm.add(updateMessageInfo,update: .all)
        }
    }
    
    func messageAfterReLoadData(keyPath: String, ascending: Bool) {
        let realm:Realm = try! Realm()
        let sort = realm.objects(Message.self).sorted(byKeyPath: keyPath, ascending: ascending)
        //將留言暫存陣列清空 ↓
        self.messagePeopleTmp.removeAll()
        self.messageContentTmp.removeAll()
        //將排序完的留言，放入留言暫存陣列 ↓
        for messageInfo in sort {
            self.messagePeopleTmp.append(messageInfo.messagePeople)
            self.messageContentTmp.append(messageInfo.messageContent)
        }
        self.messageTableView.reloadData()
    }
    
    @IBAction func sendMessageBtn(_ sender:Any) {
        self.view.endEditing(true)
        DispatchQueue.main.async {
            if (self.messageEditIng) {
                self.updateMessage()
                self.alert(message: "留言已更新成功！")
                self.messageEditIng = false
                self.messagePeopleTextField.isEnabled = true
                self.sendMessageButton.setTitle("送出留言", for: .normal)
            } else {
                self.saveMessage()
                self.alert(message: "已送出留言！")
            }
            self.messageAfterReLoadData(keyPath: "updateTime",ascending: true)
        }
    }
    
    @IBAction func sortMessage(_ sender:Any) {
        let alertController = UIAlertController(title: "", message: "請選擇留言的排序方式", preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: "預設排序", style: .default) { (action) in
            DispatchQueue.main.async {
                self.messageAfterReLoadData(keyPath: "updateTime", ascending: true)
            }
        }
        let messageTimeFromEarlyToLate = UIAlertAction(title: "留言時間 (最早 → 最晚)", style: .default) { (action) in
            DispatchQueue.main.async {
                self.messageAfterReLoadData(keyPath: "updateTime", ascending: true)
            }
        }
        let messageTimeFromLateToEarly = UIAlertAction(title: "留言時間 (最晚 → 最早)", style: .default) { (action) in
            DispatchQueue.main.async {
                self.messageAfterReLoadData(keyPath: "updateTime", ascending: false)
            }
        }
        let closeAction = UIAlertAction(title: "關閉", style: .cancel, handler: nil)
        alertController.addAction(defaultAction)
        alertController.addAction(messageTimeFromEarlyToLate)
        alertController.addAction(messageTimeFromLateToEarly)
        alertController.addAction(closeAction)
        present(alertController,animated: true)
    }
}
