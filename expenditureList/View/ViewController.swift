//
//  ViewController.swift
//  expenditureList
//
//  Created by Giulio Gola on 10/10/2019.
//  Copyright © 2019 Giulio Gola. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    //MARK: - External onjects
    private let networkingManager = NetworkingManager()
    private let activityView = UIActivityIndicatorView(style: .gray)
    private var imagePicker: UIImagePickerController!
    
    //MARK: - Expenses properties
    private var expenditureOffset = 0
    private var expenditureLimit = 25
    private var expenditureShownCount = 0
    private var expenditureCount: Int?
    private var expenditureId: String?
    private var expenses = [Expenditure]()
    
    //MARK: - Search properties
    private var isSearchActive = false
    private var isFilteredExpenses = false
    private var savedQuery = ""
    private var expensesAll = [Expenditure]()  // Used when filtering on client-side
    private var expensesAllFiltered = [Expenditure]()
    private var savedPartialLabelText = ""
    private var savedPrev25ButtonStatus = (isEnabled: false, alpha: 0.7)
    private var savedNext25ButtonStatus = (isEnabled: true, alpha: 1.0)

    //MARK: - Outlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var expensesTableView: UITableView!
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var partialExpendituresLabel: UILabel!
    @IBOutlet weak var prev25Button: UIButton!
    @IBOutlet weak var next25Button: UIButton!
    
    //MARK: - Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Table view
        expensesTableView.dataSource = self
        expensesTableView.delegate = self
        expensesTableView.register(UINib(nibName: "ExpenseTableViewCell", bundle: nil), forCellReuseIdentifier: "expenseCell")
        // Activity view
        activityView.center = self.view.center
        // Update expenditure shown count
        expenditureShownCount = expenditureLimit
        // Image Picker Controller
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        // Search Bar
        searchBar.delegate = self
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        // Load data
        let url = "\(YourBaseURL.baseURL)/expenses"
        loadData(from: url)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.title = LocalizedStrings.expendituresTitle
    }
    
    //MARK: - Data loading
    private func loadData(from url: String) {
        showActivityIndicator()
        networkingManager.getData(from: url) { (expensesTotalCount, expenses) in
            DispatchQueue.main.async {
                self.removeActivityIndicator()
            }
            if let totalExpenses = expensesTotalCount {
                DispatchQueue.main.async {
                    self.updateLabels(withTotalExpenses: totalExpenses)
                }
                self.loadAllData(withTotalExpenses: totalExpenses)
            }
            if let loadedExpenses = expenses {
                // Update table view
                self.expenses = loadedExpenses
                if !self.isFilteredExpenses {
                    DispatchQueue.main.async {
                        self.expensesTableView.reloadData()
                    }
                }
            }
        }
    }
    
    private func reloadData(withLimit limit: Int, andOffset offset: Int) {
        let url = "\(YourBaseURL.baseURL)/expenses?limit=\(limit)&offset=\(offset)"
        expenses.removeAll()
        loadData(from: url)
    }
    
    // Load all data. This is need when client filters data
    private func loadAllData(withTotalExpenses totalExpenses: Int) {
        let url = "\(YourBaseURL.baseURL)/expenses?limit=\(totalExpenses)&offset=0"
        networkingManager.getData(from: url) { (expensesTotalCount, expenses) in
            if let loadedExpenses = expenses {
                self.expensesAll = loadedExpenses
                if self.isFilteredExpenses {
                    self.expensesAllFiltered = Expenditure.filterExpenses(from: self.expensesAll, withQuery: self.savedQuery)
                    DispatchQueue.main.async {
                        self.reloadExpenses(isFilteredData: true)
                    }
                }
            }
        }
    }
    
    //MARK: - Support methods
    private func updateLabels(withTotalExpenses totalExpenses: Int) {
        self.expenditureCount = totalExpenses
        if self.expenditureShownCount > totalExpenses {
            self.partialExpendituresLabel.text = "\(self.expenditureOffset + 1)-\(totalExpenses) " + LocalizedStrings.of + " \(totalExpenses) " + LocalizedStrings.expenditures
        } else {
            self.partialExpendituresLabel.text = "\(self.expenditureOffset + 1)-\(self.expenditureShownCount) " + LocalizedStrings.of + " \(totalExpenses) " + LocalizedStrings.expenditures
        }
        self.updateButtons()
    }
    
    private func updateButtons() {
        prev25Button.isEnabled = expenditureOffset == 0 ? false : true
        prev25Button.alpha = expenditureOffset == 0 ? 0.7 : 1.0
        next25Button.isEnabled = (expenditureShownCount > expenditureCount!) ? false : true
        next25Button.alpha = (expenditureShownCount > expenditureCount!) ? 0.7 : 1.0
    }
    
    private func showActivityIndicator() {
        self.view.addSubview(activityView)
        activityView.startAnimating()
    }
    
    private func removeActivityIndicator() {
        activityView.removeFromSuperview()
        activityView.stopAnimating()
    }
    
    //MARK: - Add comment and receipt
    // Add comment
    private func addComment() {
        var textField = UITextField()
        let alert = UIAlertController(title: LocalizedStrings.addComment, message: nil, preferredStyle: .alert)
        alert.addTextField { (textFieldAlert) in
            textFieldAlert.placeholder = LocalizedStrings.yourComment
            textField = textFieldAlert
        }
        alert.addAction(UIAlertAction(title: LocalizedStrings.done, style: .default, handler: { (action) in
            if let comment = textField.text, !comment.isEmpty {
                self.postComment(withText: comment)
                alert.dismiss(animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: LocalizedStrings.cancel, style: .cancel, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // Post comment
    private func postComment(withText comment: String) {
        if let id = expenditureId {
            // Post comment to API
            let url = "\(YourBaseURL.baseURL)/expenses/\(id)"
            self.networkingManager.post(comment: comment, withURL: url) { (success) in
                self.handleResponse(forObject: LocalizedStrings.comment, withSuccess: success)
            }
        }
    }
    
    // Add receipt
    private func addReceipt() {
        let alert = UIAlertController(title: LocalizedStrings.addReceiptFrom, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: LocalizedStrings.camera, style: .default, handler: { (action) in
            self.imagePicker.sourceType = .camera
            self.imagePicker.cameraCaptureMode = .photo
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: LocalizedStrings.photoLibrary, style: .default, handler: { (action) in
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: LocalizedStrings.cancel, style: .cancel, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    //Post Receipt
    private func postReceipt(withImage image: UIImage) {
        if let id = expenditureId {
            let url = "\(YourBaseURL.baseURL)/expenses/\(id)/receipts"
            self.networkingManager.post(receipt: image, withURL: url) { (success) in
                self.handleResponse(forObject: LocalizedStrings.receipt, withSuccess: success)
            }
        }
    }
    
    //Handle network response
    private func handleResponse(forObject object: String, withSuccess success: Bool) {
        if success {
            DispatchQueue.main.async {
                self.showSuccessAlert(for: object)
                self.reloadData(withLimit: self.expenditureLimit, andOffset: self.expenditureOffset)
            }
        } else {
            DispatchQueue.main.async {
                self.showFailAlert()
            }
        }
    }
    
    // Success and fail alerts
    private func showSuccessAlert(for object: String) {
        let alert = UIAlertController(title: object + " " + LocalizedStrings.added, message: nil, preferredStyle: .alert)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true, completion: nil)
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showFailAlert() {
        let alert = UIAlertController(title: LocalizedStrings.errorAdding, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizedStrings.retry, style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Client-side filtering
    // Reload original data after clearing search text and after new comment or receipts are added to the expenditure shown as filtered expenses.
    private func reloadExpenses(isFilteredData: Bool) {
        isFilteredExpenses = isFilteredData
        updateLabelsAndButtonsDuringSearch()
        expensesTableView.reloadData()
    }
    
    // Updates status of bottom labels when client starts filtering
    private func updateLabelsAndButtonsDuringSearch() {
        prev25Button.isEnabled = isFilteredExpenses ? false : savedPrev25ButtonStatus.isEnabled
        prev25Button.alpha = isFilteredExpenses ? 0.7 : CGFloat(savedPrev25ButtonStatus.alpha)
        next25Button.isEnabled = isFilteredExpenses ? false : savedNext25ButtonStatus.isEnabled
        next25Button.alpha = isFilteredExpenses ? 0.7 : CGFloat(savedNext25ButtonStatus.alpha)
        partialExpendituresLabel.text = isFilteredExpenses ? LocalizedStrings.filteredResults : savedPartialLabelText
    }
    
    // Saves bottom labels status to re-set it back to its value when client side filtering is over
    private func saveCurrentButtonsAndLabelsStatus() {
        savedPartialLabelText = partialExpendituresLabel.text!
        savedPrev25ButtonStatus.isEnabled = prev25Button.isEnabled
        savedPrev25ButtonStatus.alpha = Double(prev25Button.alpha)
        savedNext25ButtonStatus.isEnabled = next25Button.isEnabled
        savedNext25ButtonStatus.alpha = Double(next25Button.alpha)
    }
    
    // Reloads filtered results
    @objc private func reload(_ searchBar: UISearchBar) {
        // Save partial label text only if client has not filtered expenses yet
        if isFilteredExpenses == false {
            saveCurrentButtonsAndLabelsStatus()
        }
        guard let query = searchBar.text, query.trimmingCharacters(in: .whitespaces) != "" else { return }
        savedQuery = query
        expensesAllFiltered = Expenditure.filterExpenses(from: expensesAll, withQuery: query)
        reloadExpenses(isFilteredData: true)
    }
    
    //MARK: - IBActions
    //Show/hide search bar
    @IBAction func searchBarButtonItemPressed(_ sender: UIBarButtonItem) {
        if !isSearchActive {
            UIView.animate(withDuration: 0.2) {
                self.tableViewTopConstraint.constant += self.searchBar.frame.height
                self.view.layoutIfNeeded()
                self.isSearchActive = true
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.tableViewTopConstraint.constant -= self.searchBar.frame.height
                self.view.layoutIfNeeded()
                self.isSearchActive = false
            }
        }
    }
    
    @IBAction func prev25ButtonPressed(_ sender: UIButton) {
        expenditureOffset = expenditureOffset - expenditureLimit
        expenditureShownCount = expenditureShownCount - expenditureLimit
        self.reloadData(withLimit: self.expenditureLimit, andOffset: self.expenditureOffset)
    }
    
    @IBAction func next25ButtonPressed(_ sender: UIButton) {
        expenditureOffset = expenditureOffset + expenditureLimit
        expenditureShownCount = expenditureShownCount + expenditureLimit
        self.reloadData(withLimit: self.expenditureLimit, andOffset: self.expenditureOffset)
    }
    
}

//MARK: - Table View Data Source
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFilteredExpenses ? expensesAllFiltered.count : expenses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let expense = isFilteredExpenses ? expensesAllFiltered[indexPath.row] : expenses[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "expenseCell", for: indexPath) as! ExpenseTableViewCell
        cell.setupCell(
            index: expense.index + 1,
            dateTime: expense.date,
            merchantName: expense.merchant,
            amountValue: expense.amount.value,
            amountCurrency: expense.amount.currency,
            numberOfReceipts: expense.receipts.count,
            userFirst: expense.user.first,
            userLast: expense.user.last,
            userEmail: expense.user.email,
            comment: expense.comment
        )
        return cell
    }
}

//MARK: - Table View Delegates
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    // Swipe right to left to add comment and receipt
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        expenditureId = isFilteredExpenses ? self.expensesAllFiltered[indexPath.row].id : self.expenses[indexPath.row].id
        // Add comment
        let addCommentAction = UIContextualAction(style: .normal, title:  "+") { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            // Open alert controller with text field
            self.addComment()
            success(true)
        }
        addCommentAction.backgroundColor = UIColor(red: 93/255, green: 20/255, blue: 81/255, alpha: 1.0)
        addCommentAction.image = UIImage(named: "Comment")?.scaleImage(toSize: CGSize(width: 12, height: 12))
        
        // Add receipt
        let addReceiptAction = UIContextualAction(style: .normal, title:  "+") { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            // Open image picker controller
            self.addReceipt()
            success(true)
        }
        addReceiptAction.backgroundColor = UIColor(red: 59/255, green: 18/255, blue: 52/255, alpha: 1.0)
        addReceiptAction.image = UIImage(named: "Receipt")?.scaleImage(toSize: CGSize(width: 12, height: 12))
        
        return UISwipeActionsConfiguration(actions: [addCommentAction, addReceiptAction])
    }
}

//MARK: - Image Picker Controller Delegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Post image to API
        if let image = info[.editedImage] as? UIImage {
            postReceipt(withImage: image)
        } else {
            print("Could not cast image as UIImage")
            showFailAlert()
        }
        self.imagePicker.dismiss(animated: true, completion: nil)
    }
}

//MARK: - Search bar delegates
extension ViewController: UISearchBarDelegate, UISearchControllerDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.becomeFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        reloadExpenses(isFilteredData: false)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            // User has cleared the text with the X
            reloadExpenses(isFilteredData: false)
        } else {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.reload(_:)), object: searchBar)
            perform(#selector(self.reload(_:)), with: searchBar, afterDelay: 0.8)
        }
    }
}

