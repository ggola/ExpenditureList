//
//  ExpenseTableViewCell.swift
//  expenditureList
//
//  Created by Giulio Gola on 11/10/2019.
//  Copyright © 2019 Giulio Gola. All rights reserved.
//

import UIKit

class ExpenseTableViewCell: UITableViewCell {
    
    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var merchantLabel: UILabel!
    @IBOutlet weak var amountValueCurrencyLabel: UILabel!
    @IBOutlet weak var numberOfReceiptsLabel: UILabel!
    @IBOutlet weak var userFirstLastLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // Turn UIContextualAction title color to white
    override func layoutSubviews() {
        super.layoutSubviews()
        for subview in self.subviews {
            for subview2 in subview.subviews {
                if let button = subview2 as? UIButton {
                    button.tintColor = UIColor.white
                }
            }
        }
    }
    
    func setupCell(index: Int, dateTime: String, merchantName: String, amountValue: String, amountCurrency: String, numberOfReceipts: Int, userFirst: String, userLast: String, userEmail: String, comment: String) {
        self.indexLabel.text = String(index)
        self.dateTimeLabel.text = getDateTime(from: dateTime)
        self.merchantLabel.text = "\(merchantName)"
        self.amountValueCurrencyLabel.text = "\(amountValue) \(amountCurrency)"
        self.numberOfReceiptsLabel.text = numberOfReceipts == 0 ? LocalizedStrings.noReceipts : numberOfReceipts == 1 ? LocalizedStrings.oneReceipt : "\(numberOfReceipts) " + LocalizedStrings.receipts
        self.userFirstLastLabel.text = "\(userFirst) \(userLast)"
        self.userEmailLabel.text = userEmail
        self.commentLabel.text = comment
    }
    
    private func getDateTime(from dateTime: String) -> String {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = LocalizedStrings.date
        if let date = dateFormatterGet.date(from: dateTime) {
            return dateFormatterPrint.string(from: date)
        } else {
            return LocalizedStrings.dateNotAvailable
        }
    }

}
