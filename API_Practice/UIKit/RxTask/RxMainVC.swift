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
    @IBOutlet weak var completedTodosDeleteBtn: UIButton!
    @IBOutlet weak var addTodoBtn: UIButton!
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
    
    let refreshControl = UIRefreshControl()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setTableview()
        setOutputFromViewModel()
        setOutputFromUI()
    }
    
    // MARK: - UI Setup

    private func setTableview() {
        myTableView.register(RxTodoCell.uinib, forCellReuseIdentifier: RxTodoCell.reuseIdentifier)
        
        myTableView.refreshControl = refreshControl
    }
    
    private func setOutputFromUI() {
        self.myTableView
            .rx.isBottomNeared
            .bind(onNext: todosVM.fetchMoreTodos)
            .disposed(by: disposeBag)
        
        self.refreshControl.rx.controlEvent(.valueChanged)
            .withUnretained(self)
            .subscribe(onNext: { vc, _ in
                vc.todosVM.fetchRefresh()
            }).disposed(by: disposeBag)
        
        self.searchBar.searchTextField.rx.text.orEmpty
            .withUnretained(self)
            .subscribe(onNext: { (vc, input) in
                vc.todosVM.searchTerm.accept(input)
            })
            .disposed(by: disposeBag)
        
        self.completedTodosDeleteBtn.rx.tap
            .withUnretained(self)
            .subscribe { vc, _ in
                vc.todosVM.completedTodosDelete()
            }
            .disposed(by: disposeBag)
        
        self.addTodoBtn.rx.tap
            .withUnretained(self)
            .subscribe { vc, _ in
                vc.presentNewTodoAlert()
            }
            .disposed(by: disposeBag)
    }
    
    private func setOutputFromViewModel() {
        todosVM.notifyTodos
        // observe(on:), catchAndReture(), strong self
            .asDriver(onErrorJustReturn: [])
            .drive(myTableView.rx.items(cellIdentifier: RxTodoCell.reuseIdentifier, cellType: RxTodoCell.self)) { [weak self] index, item, cell in
                
                guard let self = self else { return }
                
                cell.setTodo(todo: item)
                
                cell.tappedSwitch = self.tappedSwitch(id:isOn:)
            }
            .disposed(by: disposeBag)
         
        todosVM.notifyPage
            .asDriver(onErrorJustReturn: "페이지 정보가 없습니다.")
            .drive(pageInfoLabel.rx.text)
            .disposed(by: disposeBag)
        
        todosVM.notifyIsLoading
            .withUnretained(self)
            .map({ vc, isLoading -> UIView? in
                isLoading ? vc.indicatorInTableFooterView : nil
            })
            .asDriver(onErrorJustReturn: nil)
            .drive(myTableView.rx.tableFooterView)
            .disposed(by: disposeBag)
        
        todosVM.notifyRefresh
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { vc, _ in
                vc.refreshControl.endRefreshing()
            }).disposed(by: disposeBag)
        
        todosVM.notifyHasNextPage
            .withUnretained(self)
            .map({ vc, isLoading -> UIView? in
                isLoading ? vc.indicatorInTableFooterView : nil
            })
            .asDriver(onErrorJustReturn: nil)
            .drive(myTableView.rx.tableFooterView)
            .disposed(by: disposeBag)
        
        todosVM.notifyCompletedTodo
            .map({ "완료된 일 : \($0)" })
            .asDriver(onErrorJustReturn: "완료된 일 :")
            .drive(completedTodosLabel.rx.text)
            .disposed(by: disposeBag)
        
        todosVM.notifyTodosAdded
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] in
                guard let self = self else { return }
                self.myTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            })
            .disposed(by: disposeBag)
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








