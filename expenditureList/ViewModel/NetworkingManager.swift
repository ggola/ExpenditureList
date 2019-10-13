//
//  NetworkingManager.swift
//  expenditureList
//
//  Created by Giulio Gola on 11/10/2019.
//  Copyright © 2019 Giulio Gola. All rights reserved.
//

import UIKit

struct NetworkingManager {
    
    let parsingManager = ParsingManager()
    
    func getData(from url: String, completion: @escaping((NSInteger?, [Expenditure]?)->())) {
        let url = URL(string: url)!
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let expensesData = data else { return }
            let expensesTotalCount = self.parsingManager.getExpensesTotalCount(from: expensesData)
            let expenses = self.parsingManager.getExpenses(from: expensesData)
            completion(expensesTotalCount, expenses)
        }
        task.resume()
    }
    
    func post(comment: String, withURL url: String , completion: @escaping ((Bool)->())) {
        if let urlFromString = URL(string: url) {
            var request = URLRequest(url: urlFromString)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.timeoutInterval = 30.0
            
            let parameters: [String: String] = [
                "comment": comment
            ]
            request.httpBody = parameters.percentEscaped().data(using: .utf8)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response as? HTTPURLResponse, error == nil else {
                    // Networking error
                    print("error", error ?? "Unknown error")
                    completion(false)
                    return
                }
                guard (200 ... 299) ~= response.statusCode else {
                    // If status code is not between 200 and 299 print response
                    print("statusCode should be 2xx, but is \(response.statusCode)")
                    print("response = \(response)")
                    completion(false)
                    return
                }
                if let responseString = String(data: data, encoding: .utf8) {
                    print("responseString = \(responseString)")
                    completion(true)
                }
            }
            task.resume()
        } else {
            completion(false)
        }
    }
    
    func post(receipt: UIImage, withURL url: String , completion: @escaping ((Bool)->())) {
        guard let receiptData = receipt.jpegData(compressionQuality: 0.8) else { return }
        if let urlFromString = URL(string: url) {
            var request = URLRequest(url: urlFromString)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.timeoutInterval = 30.0
            
            let uuid = UUID().uuidString
            let CRLF = "\r\n"
            let filename = uuid + ".jpg"
            let formName = "receipt"
            let type = "image/jpeg"     // file type
            let boundary = String(format: "----iOSURLSessionBoundary.%08x%08x", arc4random(), arc4random())
            var body = Data()
            
            // file data //
            body.append(("--\(boundary)" + CRLF).data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(formName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append(("Content-Type: \(type)" + CRLF + CRLF).data(using: .utf8)!)
            body.append(receiptData)
            body.append(CRLF.data(using: .utf8)!)
            
            // footer //
            body.append(("--\(boundary)--" + CRLF).data(using: .utf8)!)
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            request.httpBody = body
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response as? HTTPURLResponse, error == nil else {
                    // Networking error
                    print("error", error ?? "Unknown error")
                    completion(false)
                    return
                }
                guard (200 ... 299) ~= response.statusCode else {
                    // If status code is not between 200 and 299 print response
                    print("statusCode should be 2xx, but is \(response.statusCode)")
                    print("response = \(response)")
                    completion(false)
                    return
                }
                if let responseString = String(data: data, encoding: .utf8) {
                    print("responseString = \(responseString)")
                    completion(true)
                }
            }
            task.resume()
        }
    }
    
}
