import UIKit
import RealmSwift

class MessageInfoTableViewCell: UITableViewCell {

    @IBOutlet weak var messagePeople:UILabel!
    @IBOutlet weak var messageContent:UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
