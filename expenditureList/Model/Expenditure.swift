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
        var filteredExpenses = [Expenditure]()
        filteredExpenses = expensesAll.filter({ (element) -> Bool in
            let expense = element as Expenditure
            // Filter data: check if user first, last and email contain client query
            return expense.user.first.contains(query) || expense.user.last.contains(query) || expense.user.email.contains(query)
        })
        return filteredExpenses
    }
}
