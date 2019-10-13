//
//  Expenditure.swift
//  expenditureList
//
//  Created by Giulio Gola on 11/10/2019.
//  Copyright © 2019 Giulio Gola. All rights reserved.
//

import Foundation

struct Expenditure {
    
    var id: String = ""
    var amount: ExpenditureAmount
    var date: String = ""
    var merchant: String = ""
    var receipts: [[String : String]] = [[String : String]]()
    var comment: String = ""
    var category: String = ""
    var user: ExpenditureUser
    var index: Int = 0
    
    // Filter expenses
    static func filterExpenses(from expensesAll: [Expenditure], withQuery query: String) -> [Expenditure] {
        let queryArray = query.components(separatedBy: " ")
        //Find what the query contains
        var isNumberInQuery = false
        var isNameOrEmailInQuery = false
        var isCurrencyInQuery = false
        for q in queryArray {
            if Double(q) != nil {
                isNumberInQuery = true
            } else if q == "GBP" || q == "EUR" || q == "DKK" {
                isCurrencyInQuery = true
            } else {
                isNameOrEmailInQuery = true
            }
        }
        
        var filteredExpenses = [Expenditure]()
        filteredExpenses = expensesAll.filter({ (element) -> Bool in
            
            var isFirstName = false
            var isLastName = false
            var isEmail = false
            var isMinAmount = false
            var isCurrency = false
            
            let expense = element as Expenditure

            for q in queryArray {
                if let minAmount = Double(q) {
                    if Double(expense.amount.value)! >= minAmount {
                        isMinAmount = true
                    }
                } else if expense.user.first.contains(q) {
                    isFirstName = true
                } else if expense.user.last.contains(q) {
                    isLastName = true
                } else if expense.user.email.contains(q) {
                    isEmail = true
                } else if expense.amount.currency == q {
                    isCurrency = true
                }
            }
            
            if isNameOrEmailInQuery {
                if isNumberInQuery {
                    if isCurrencyInQuery {
                        return (isFirstName || isLastName || isEmail) && isMinAmount && isCurrency
                    } else {
                        return (isFirstName || isLastName || isEmail) && isMinAmount
                    }
                } else {
                    if isCurrencyInQuery {
                        return (isFirstName || isLastName || isEmail) && isCurrency
                    } else {
                        return (isFirstName || isLastName || isEmail)
                    }
                }
            } else {
                if isNumberInQuery {
                    if isCurrencyInQuery {
                        return isMinAmount && isCurrency
                    } else {
                        return isMinAmount
                    }
                } else {
                    if isCurrencyInQuery {
                        return isCurrency
                    } else {
                        return false
                    }
                }
            }
           
        })
        return filteredExpenses
    }
}
