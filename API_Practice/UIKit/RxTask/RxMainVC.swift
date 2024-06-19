//
//  MainVC.swift
//  API_Practice
//
//  Created by CatSlave on 5/29/24.
//

import UIKit
import RxSwift
import RxCocoa

class RxMainVC: UIViewController {
    // MARK: - Variables
    private lazy var todos: [Todo] = []
    
    private var todosVM = TodosVM_Rx()
    private let disposeBag = DisposeBag()
    
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
        configureRefreshControl()
        setupSearchBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        self.todosVM.fetchTodos(page: 1)
    }
    
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
    }
    
    private func setupSearchBar() {
        self.searchBar.delegate = self
    }
    
    
    private func setTableview() {
        myTableView.register(RxTodoCell.uinib, forCellReuseIdentifier: RxTodoCell.reuseIdentifier)
        myTableView.delegate = self
        
        todosVM.todosObservable
            .observe(on: MainScheduler.instance)
            .bind(to: myTableView.rx.items(cellIdentifier: RxTodoCell.reuseIdentifier)) { index, item, cell in
                guard let cell = cell as? RxTodoCell else { return }
                cell.setTodo(todo: item)
            }
            .disposed(by: disposeBag)
        
//        self.todosVM.notifyMoreDataIsLoading = { [weak self] isLoading in
//            guard let self = self else { return }
//            DispatchQueue.main.async {
//                self.myTableView.tableFooterView = isLoading ? self.indicatorInTableFooterView : nil
//            }
//        }
        todosVM.isLoading
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe { (vc, isLoading) in
                vc.myTableView.tableFooterView = isLoading ? vc.indicatorInTableFooterView : nil
            }
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Selectors
    
    
    @IBAction func tappedNewTodoBtn(_ sender: UIButton) {
        self.presentNewTodoAlert()
    }
    
    @IBAction func tappedDeleteTodos(_ sender: UIButton) {
//        self.todosVM.deleteCompletedTodos()
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
//        todosVM.fetchRefresh()
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
            
//            self.todosVM.addTodoFetchTodo(content: userInput)
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
            
//            self.todosVM.editTodoEncoded(todo: todo, editContent: userInput)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func presentDeleteTodoAlert(todo : Todo) {
        let alert = UIAlertController(title: "삭제", message: "할 일을 삭제합니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("취소", comment: "Default action"), style: .destructive))
        alert.addAction(UIAlertAction(title: NSLocalizedString("확인", comment: "Default action"), style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            
//            self.todosVM.deleteTodo(todo: todo)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Cell Event
extension RxMainVC {
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
        
//        self.todosVM.editTodoEncoded(todo: todo, changeIsDone: isOn) { [weak self] in
//            guard let self = self,
//                  let id = todo.id else { return }
//            
//            self.todosVM.changeCompleted(todoId: id, isOn: isOn)
//        }
    }
    
    
}

//extension RxMainVC : UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return todos.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: TodoCell.reuseIdentifier, for: indexPath) as? TodoCell else { return UITableViewCell() }
//        
//        let todo = todos[indexPath.row]
//        
//        cell.setTodo(todo: todo, isCompleted: self.todosVM.completedTodosId)
//        
//        cell.tappedEditBtn = tappedEditBtn(todo:)
//    
//        cell.tappedDeleteBtn = tappedDeleteBtn(todo:)
//        
//        cell.tappedSwitch = tappedSwitch(todo:isOn:)
//        
//        return cell
//    }
//    
//    
//}

extension RxMainVC: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let viewHeight = scrollView.frame.size.height
        let contentHeight = scrollView.contentSize.height
        let offsetY = scrollView.contentOffset.y
        let threshold : CGFloat = contentHeight - (offsetY + 200)
        
        if threshold < viewHeight {
            
            self.todosVM.fetchMoreTodos()
        }
    }
}

extension RxMainVC: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchTermInputWorkItem?.cancel()
        
        let dispatchWorkItem = DispatchWorkItem {
//            self.todosVM.searchTerm = searchText
        }
        
        self.searchTermInputWorkItem = dispatchWorkItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: dispatchWorkItem)
    }
}




