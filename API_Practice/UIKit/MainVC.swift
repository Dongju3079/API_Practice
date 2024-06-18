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
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    lazy var indicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.color = .systemBlue
        view.startAnimating()
        view.frame = CGRect(x: 0, y: 0, width: myTableView.bounds.width, height: 50)
        return view
    }()
    
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
        configureRefreshControl()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
    }
    
    
    
    
    private func setTableview() {
        myTableView.register(TodoCell.uinib, forCellReuseIdentifier: TodoCell.reuseIdentifier)
        myTableView.dataSource = self
        myTableView.delegate = self
        myTableView.tableFooterView = self.indicatorView
    }
    
    private func setupData() {
        self.TodosVM.notifyTodosChanged = { [weak self] todos in
            guard let self = self else { return }
            self.todos = todos
            DispatchQueue.main.async {
                self.myTableView.reloadData()
            }
        }
        
        self.TodosVM.notifyCurrentPage = { [weak self] page in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.pageInfoLabel.text = "현재 페이지 \(page)"
            }
        }
        
        self.TodosVM.notifyIsLoading = { [weak self] isLoading in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.myTableView.tableFooterView = isLoading ? self.indicatorView : nil
                if isLoading {
                    self.myTableView.refreshControl?.beginRefreshing()
                } else {
                    self.myTableView.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
    private func configureRefreshControl () {
        myTableView.refreshControl = UIRefreshControl()
        myTableView.refreshControl?.addTarget(self, action:
                                                #selector(handleRefreshControl),
                                              for: .valueChanged)
    }
        
    @objc func handleRefreshControl() {
        TodosVM.fetchTodos(page: 1)
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


