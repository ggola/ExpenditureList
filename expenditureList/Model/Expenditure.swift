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
        let queryContent: (isNameOrEmailInQuery: Bool, isNumberInQuery: Bool, isCurrencyInQuery: Bool) = findWhatQueryContains(withQueryArray: queryArray)
        var filteredExpenses = [Expenditure]()
        filteredExpenses = expensesAll.filter({ (element) -> Bool in
            let expense = element as Expenditure
            let queryMatches: (isFirstName: Bool, isLastName: Bool, isEmail: Bool, isMinAmount: Bool, isCurrency: Bool) = getQueryMatches(withQueryArray: queryArray, andExpense: expense)
            return isInFilteredExpenses(givenContent: queryContent, andMatches: queryMatches)
        })
        return filteredExpenses
    }
    
    static private func findWhatQueryContains(withQueryArray queryArray: [String]) -> (Bool, Bool, Bool) {
        //Find what the query contains
        var isNumberInQuery = false
        var isNameOrEmailInQuery = false
        var isCurrencyInQuery = false
        for q in queryArray {
            let Q = q.uppercased()
            if !q.isEmpty {
                if Double(q) != nil {
                    isNumberInQuery = true
                } else if Q == "GBP" || Q == "EUR" || Q == "DKK" {
                    isCurrencyInQuery = true
                } else {
                    isNameOrEmailInQuery = true
                }
            }
        }
        return (isNameOrEmailInQuery, isNumberInQuery, isCurrencyInQuery)
    }
    
    
    static private func getQueryMatches(withQueryArray queryArray: [String], andExpense expense: Expenditure) -> (Bool, Bool, Bool, Bool, Bool){
        var queryMatches = (isFirstName: false, isLastName: false, isEmail: false, isMinAmount: false, isCurrency: false)
        
        for q in queryArray {
            let Q = q.uppercased()
            if let minAmount = Double(q) {
                if Double(expense.amount.value)! >= minAmount {
                    queryMatches.isMinAmount = true
                }
            } else if expense.user.first.contains(q) {
                queryMatches.isFirstName = true
            } else if expense.user.last.contains(q) {
                queryMatches.isLastName = true
            } else if expense.user.email.contains(q) {
                queryMatches.isEmail = true
            } else if expense.amount.currency == Q {
                queryMatches.isCurrency = true
            }
        }
        return queryMatches
    }
    
    
    static private func isInFilteredExpenses(givenContent queryContent: (Bool, Bool, Bool), andMatches queryMatches: (Bool, Bool, Bool, Bool, Bool)) -> Bool {
        
        let isNameOrEmailInQuery = queryContent.0
        let isNumberInQuery = queryContent.1
        let isCurrencyInQuery = queryContent.2
        let isFirstName = queryMatches.0
        let isLastName = queryMatches.1
        let isEmail = queryMatches.2
        let isMinAmount = queryMatches.3
        let isCurrency = queryMatches.4
        
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
    }
    
}
