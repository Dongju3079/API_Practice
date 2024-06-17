//
//  MainVC.swift
//  API_Practice
//
//  Created by CatSlave on 5/29/24.
//

import UIKit
import SwiftUI

class MainVC: UIViewController {
    
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var pageInfoLabel: UILabel!
    @IBOutlet weak var loadIndicator: UIActivityIndicatorView!
    
    var todos: [Todo] = [] {
        didSet {
            print("테스트 todos Count : \(todos.count)")
        }
    }
    
    var TodosVM = TodosVM_Closure()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setTableview()
        setupData()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
    }
    
    
    private func setTableview() {
        myTableView.register(TodoCell.uinib, forCellReuseIdentifier: TodoCell.reuseIdentifier)
        myTableView.dataSource = self
        myTableView.delegate = self
    }
    
    private func setupData() {
        self.TodosVM.notifyTodosChanged = { todos in
            self.todos = todos
            DispatchQueue.main.async {
                self.myTableView.reloadData()
            }
        }
        
        self.TodosVM.notifyCurrentPage = { page in
            DispatchQueue.main.async {
                self.pageInfoLabel.text = "현재 페이지 \(page)"
            }
        }
        
        self.TodosVM.notifyIsLoading = { isLoading in
            DispatchQueue.main.async {
                self.loadIndicator.isHidden = !isLoading
            }
            
        }
    }
}

extension MainVC : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TodoCell.reuseIdentifier, for: indexPath) as? TodoCell else { return UITableViewCell() }
        
        cell.todo = todos[indexPath.row]
        
        return cell
    }
    
    
}

extension MainVC: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let viewHeight = scrollView.frame.size.height
        let contentHeight = scrollView.contentSize.height
        let offsetY = scrollView.contentOffset.y
        let threshold : CGFloat = contentHeight - (offsetY + 200)
        
        if threshold < viewHeight {
            self.TodosVM.fetchMore()
        }
    }
}


extension MainVC {
    
    private struct VCRepresentable: UIViewControllerRepresentable {
        
        let mainVC: MainVC
        
        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        }
        
        func makeUIViewController(context: Context) -> some UIViewController {
            return mainVC
        }
    }
    
    func getRepresentable() -> some View {
        VCRepresentable(mainVC: self)
    }
}


