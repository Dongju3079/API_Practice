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
        setTableview()
        setOutputFromViewModel()
        setOutputFromUI()
        configureRefreshControl()
    }
    
    // MARK: - UI Setup

    private func setTableview() {
        myTableView.register(RxTodoCell.uinib, forCellReuseIdentifier: RxTodoCell.reuseIdentifier)
    }
    
    private func setOutputFromUI() {
        self.myTableView
            .rx.isBottomNeared
            .bind(onNext: self.todosVM.fetchMoreTodos)
            .disposed(by: disposeBag)
        
        // text.changed : 값이 변경되면 그대로 보내줌
        // text.orEmpty : 값이 변경되면 언랩핑 후 보내줌
        self.searchBar.searchTextField.rx.text.orEmpty
            .do(onNext: { _ in
                print("테스트 searchBar send)")
            })
            .bind(onNext: self.todosVM.searchTerm.accept(_:))
            .disposed(by: disposeBag)
    }
    
    private func setOutputFromViewModel() {
        todosVM.notifyTodos
        // observe(on:), catchAndReture(), strong self
            .asDriver(onErrorJustReturn: [])
            .drive(myTableView.rx.items(cellIdentifier: RxTodoCell.reuseIdentifier, cellType: RxTodoCell.self)) { [weak self] index, item, cell in
                
                guard let self = self else { return }
                
                cell.setTodo(todo: item)
                
                cell.tappedSwitch = tappedSwitch(id:isOn:)
            }
            .disposed(by: disposeBag)
         
        todosVM.notifyPage
            .asDriver(onErrorJustReturn: "페이지 정보가 없습니다.")
            .drive(self.pageInfoLabel.rx.text)
            .disposed(by: disposeBag)
        
        todosVM.notifyIsLoading
            .asDriver(onErrorJustReturn: false)
            .map({ $0 ? self.indicatorInTableFooterView : nil })
            .drive(self.myTableView.rx.tableFooterView)
            .disposed(by: disposeBag)
        
        todosVM.notifyHasNextPage
            .asDriver(onErrorJustReturn: false)
            .map { !$0 ? self.noPageView : nil }
            .drive(self.myTableView.rx.tableFooterView)
            .disposed(by: disposeBag)
        
        todosVM.notifyCompletedTodo
            .map({ "완료된 일 : \($0)" })
            .asDriver(onErrorJustReturn: "완료된 일 :")
            .drive(self.completedTodosLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - Selectors
    
    
    @IBAction func tappedNewTodoBtn(_ sender: UIButton) {
        self.presentNewTodoAlert()
    }
    
    @IBAction func tappedDeleteTodos(_ sender: UIButton) {
//        self.todosVM.searchTodos()
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
            
            self.todosVM.addTodo(content: userInput)
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
    
    private func tappedSwitch(id: Int, isOn: Bool) {
        self.todosVM.handleTodoSelection(id: id, isDone: isOn)
    }
    
    
}






