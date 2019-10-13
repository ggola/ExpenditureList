//
//  ParsingManager.swift
//  expenditureList
//
//  Created by Giulio Gola on 11/10/2019.
//  Copyright © 2019 Giulio Gola. All rights reserved.
//

import Foundation

struct ParsingManager {
    
    // Returns array of Expenditures
    func getExpenses(from data: Data) -> [Expenditure]? {
        do {
            let dataJSON = try JSONSerialization.jsonObject(with: data) as? NSDictionary
            if let expenses = dataJSON?["expenses"] as? NSArray {
                // Array of expenditures objects to return
                var expenditures = [Expenditure]()
                for expense in expenses {
                    if let expenseDict = expense as? [String : AnyObject] {
                        let expenditureAmount = ExpenditureAmount(
                            value: expenseDict["amount"]?["value"] as! String,
                            currency: expenseDict["amount"]?["currency"] as! String
                        )
                        let expenditureUser = ExpenditureUser(
                            first: expenseDict["user"]?["first"] as! String,
                            last: expenseDict["user"]?["last"] as! String,
                            email: expenseDict["user"]?["email"] as! String
                        )
                        let expenditure = Expenditure(
                            id: expenseDict["id"] as! String,
                            amount: expenditureAmount,
                            date: expenseDict["date"] as! String,
                            merchant: expenseDict["merchant"] as! String,
                            receipts: expenseDict["receipts"] as! [[String:String]],
                            comment: expenseDict["comment"] as! String,
                            category: expenseDict["category"] as! String,
                            user: expenditureUser,
                            index: expenseDict["index"] as! Int
                        )
                        expenditures.append(expenditure)
                    }
                }
                return expenditures
            }
        } catch let error {
            print("Error extracting data as JSON object: \(error.localizedDescription)")
        }
        return nil
    }
    
    // Returns total number of expenditures
    func getExpensesTotalCount(from data: Data) -> Int? {
        do {
            let dataJSON = try JSONSerialization.jsonObject(with: data) as? NSDictionary
            if let expensesTotalCount = dataJSON?["total"] as? NSInteger {
                return expensesTotalCount
            }
        } catch let error {
            print("Error extracting data as JSON object: \(error.localizedDescription)")
        }
        return nil
    }
    
}
