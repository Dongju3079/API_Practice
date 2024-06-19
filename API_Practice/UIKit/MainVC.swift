//
//  MainVC.swift
//  API_Practice
//
//  Created by CatSlave on 5/29/24.
//

import UIKit
import SwiftUI

class MainVC: UIViewController {
    // MARK: - Variables
    private lazy var todos: [Todo] = []
    
    private var todosVM = TodosVM_Closure()
    
    private var searchTermInputWorkItem: DispatchWorkItem?
    
    // MARK: - UI components
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var pageInfoLabel: UILabel!
    @IBOutlet weak var completedTodosLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var noContentLabel: UILabel!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    lazy var indicatorInTableFooterView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.color = .systemBlue
        view.startAnimating()
        view.frame = CGRect(x: 0, y: 0, width: myTableView.bounds.width, height: 50)
        return view
    }()
    
    lazy var noContentView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0,
                                        width: myTableView.bounds.width,
                                        height: 300))
        let label = UILabel()
        label.text = "검색결과를 찾을 수 없습니다."
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return view
    }()
    
    lazy var noPageView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0,
                                        width: myTableView.bounds.width,
                                        height: 50))
        let label = UILabel()
        label.text = "마지막 페이지"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return view
    }()
    
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setTableview()
        setupData()
        configureRefreshControl()
        setupSearchBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.todosVM.fetchTodos(page: 1)
    }
    
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
    }
    
    private func setupSearchBar() {
        self.searchBar.delegate = self
    }
    
    
    private func setTableview() {
        myTableView.register(TodoCell.uinib, forCellReuseIdentifier: TodoCell.reuseIdentifier)
        myTableView.dataSource = self
        myTableView.delegate = self
    }
    
    // MARK: - Selectors
    @IBAction func tappedNewTodoBtn(_ sender: UIButton) {
        presentNewTodoAlert()
    }
    
    
    @IBAction func tappedDeleteTodos(_ sender: UIButton) {
        self.todosVM.deleteCompletedTodos()
    }
    
    
    // ViewModel To VC
    private func setupData() {
        
        // 데이터 주입
        self.todosVM.notifyTodosChanged = { [weak self] todos in
            guard let self = self else { return }
            self.todos = todos
            DispatchQueue.main.async {
                print("테스트 reload : 새로고침")
                self.myTableView.reloadData()
            }
        }
        
        // 데이터 없을 때
        self.todosVM.notifyNoContent = { [weak self] isEmpty in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.myTableView.backgroundView = isEmpty ? self.noContentView : nil
            }
        }
    
        // 현재 데이터 페이지 (Int)
        self.todosVM.notifyCurrentPage = { [weak self] page in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.pageInfoLabel.text = "현재 페이지 \(page)"
            }
        }
        
        // 추가로 데이터를 받아오는 중인지
        self.todosVM.notifyMoreDataIsLoading = { [weak self] isLoading in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.myTableView.tableFooterView = isLoading ? self.indicatorInTableFooterView : nil
            }
        }
        
        // 아래로 당겨서 새로고침이 끝나는 시점
        self.todosVM.notifyRefresh = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.myTableView.refreshControl?.endRefreshing()
            }
        }
        
        // 다음 페이지가 있는지
        self.todosVM.notifyHasNext = { [weak self] hasNext in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.myTableView.tableFooterView = !hasNext ? self.noPageView : nil
            }
        }
        
        // 새로운 할 일 추가 후 스크롤 올려주기
        self.todosVM.notifyUploadCompleted = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.myTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
        
        // 에러 발생 시 얼럿창 표시하기
        self.todosVM.notifyErrResponse = { [weak self] message in
            
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.presentGuideAlert(message: message)
            }
        }
        
        // 완료된 할 일 추가하기
        self.todosVM.notifyCompletedTodos = { [weak self] todos in
            guard let self = self else { return }
                        
            let stringRepresentation = todos.map { "\($0)" }.joined(separator: ", ")
            
            DispatchQueue.main.async {
                self.completedTodosLabel.text = "완료된 할 일 : \(stringRepresentation)"
            }
        }
        
        // 완료된 일 삭제 로딩
        self.todosVM.notifyIsLoading = { [weak self] isLoading in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if isLoading {
                    self.loadingIndicator.startAnimating()
                } else {
                    self.loadingIndicator.stopAnimating()
                }
            }
        }
        
        self.todosVM.notifyCompletedIsEmpty = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.presentGuideAlert(message: "선택된 목록이 없습니다.")
            }
        }
    }
    
    // MARK: - Refresh
    private func configureRefreshControl () {
        myTableView.refreshControl = UIRefreshControl()
        myTableView.refreshControl?.addTarget(self, action:
                                                #selector(handleRefreshControl),
                                              for: .valueChanged)
    }
        
    @objc func handleRefreshControl() {
        self.searchBar.searchTextField.text = nil
        todosVM.fetchRefresh()
    }
    
    // MARK: - Alert
    private func presentGuideAlert(message: String?) {
        let alert = UIAlertController(title: "안내", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("닫기", comment: "Default action"), style: .cancel))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func presentNewTodoAlert() {
        let alert = UIAlertController(title: "할 일 추가", message: "할 일을 입력하세요.", preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: NSLocalizedString("취소", comment: "Default action"), style: .destructive))
        alert.addAction(UIAlertAction(title: NSLocalizedString("추가", comment: "Default action"), style: .default, handler: { [weak self, weak alert] _ in
            guard let alert = alert,
                  let self = self,
                  let userInput = alert.textFields?.first?.text else { return }
            
            self.todosVM.addTodoFetchTodo(content: userInput)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func presentEditTodoAlert(todo: Todo) {
        let alert = UIAlertController(title: "수정", message: "수정할 내용을 입력하세요.", preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: NSLocalizedString("취소", comment: "Default action"), style: .destructive))
        alert.addAction(UIAlertAction(title: NSLocalizedString("완료", comment: "Default action"), style: .default, handler: { [weak self, weak alert] _ in
            guard let alert = alert,
                  let self = self,
                  let userInput = alert.textFields?.first?.text else { return }
            
            self.todosVM.editTodoEncoded(todo: todo, editContent: userInput)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func presentDeleteTodoAlert(todo : Todo) {
        let alert = UIAlertController(title: "삭제", message: "할 일을 삭제합니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("취소", comment: "Default action"), style: .destructive))
        alert.addAction(UIAlertAction(title: NSLocalizedString("확인", comment: "Default action"), style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            
            self.todosVM.deleteTodo(todo: todo)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Cell Event
extension MainVC {
    private func tappedEditBtn(todo: Todo) {
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.presentEditTodoAlert(todo: todo)
        }
    }
    
    private func tappedDeleteBtn(todo: Todo) {
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.presentDeleteTodoAlert(todo: todo)
        }
    }
    
    private func tappedSwitch(todo: Todo, isOn: Bool) {
        
        self.todosVM.editTodoEncoded(todo: todo, changeIsDone: isOn) { [weak self] in
            guard let self = self,
                  let id = todo.id else { return }
            
            self.todosVM.changeCompleted(todoId: id, isOn: isOn)
        }
    }
    
    
}

extension MainVC : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TodoCell.reuseIdentifier, for: indexPath) as? TodoCell else { return UITableViewCell() }
        
        let todo = todos[indexPath.row]
        
        cell.setTodo(todo: todo, isCompleted: self.todosVM.completedTodosId)
        
        cell.tappedEditBtn = tappedEditBtn(todo:)
    
        cell.tappedDeleteBtn = tappedDeleteBtn(todo:) 
        
        cell.tappedSwitch = tappedSwitch(todo:isOn:)
        
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
            
            print("테스트 스크롤 : 스크롤됩니다")
            self.todosVM.fetchMore()
        }
    }
}

extension MainVC: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchTermInputWorkItem?.cancel()
        
        let dispatchWorkItem = DispatchWorkItem {
            self.todosVM.searchTerm = searchText
        }
        
        self.searchTermInputWorkItem = dispatchWorkItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: dispatchWorkItem)
    }
}




