//
//  MainVC.swift
//  API_Practice
//
//  Created by CatSlave on 5/29/24.
//

import UIKit
import RxSwift
import RxCocoa
import RxRelay
import ReactorKit

class RxMainVC: UIViewController, StoryboardView {
    typealias Reactor = TodosReactor
    
    // MARK: - Variables
    private lazy var todos: [Todo] = []
    
    private var todosVM = TodosVM_Rx()
    var disposeBag = DisposeBag()
    
    // MARK: - Output Action Variables
    private var addTodoAction = PublishRelay<String>()
    private var deleteTodoAction = PublishRelay<Int>()
    private var editTodoAction = PublishRelay<(Todo, String?, Bool?)>()
    
    // MARK: - UI components
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var pageInfoLabel: UILabel!
    @IBOutlet weak var completedTodosLabel: UILabel!
    @IBOutlet weak var completedTodosDeleteBtn: UIButton!
    @IBOutlet weak var addTodoBtn: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var noContentLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    private lazy var indicatorInTableFooterView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.color = .systemBlue
        view.startAnimating()
        view.frame = CGRect(x: 0, y: 0, width: myTableView.bounds.width, height: 50)
        return view
    }()
    
    private lazy var noContentView: UIView = {
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
    
    private lazy var noPageView: UIView = {
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
        reactor = TodosReactor()
        setTableview()
    }
    
    // MARK: - UI Setup
    private func setTableview() {
        myTableView.register(RxTodoCell.uinib, forCellReuseIdentifier: RxTodoCell.reuseIdentifier)
        myTableView.refreshControl = refreshControl
    }
}

// MARK: - ReactoreKit
extension RxMainVC {
    func bind(reactor: TodosReactor) {
        setAddTodoBtnAction()
        
        self.refreshControl.rx.controlEvent(.valueChanged)
            .map { _ in Reactor.Action.fetchRefresh }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.myTableView.rx.isBottomNeared
            .map { _ in Reactor.Action.fetchMore }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // 기존 방식 self.searchBar.searchTextField.rx.text.orEmpty
        // 검색창 클릭, 얼럿창 실행 or 종료 등의 이벤트로 포커스가 변경되면서 이벤트가 발생할 수 있음
        // 클릭만 해도 로직 실행, 얼럿창 실행 or 종료만으로도 로직이 실행돼서 불필요한 리소스 발생
        
        // 텍스트필드의 내부 내용이 변경될 때만 실행하도록 변경
        
        self.searchBar.searchTextField.rx.controlEvent(.editingChanged)
            .withUnretained(self)
            .do(onNext: { vc, _ in
                vc.myTableView.tableFooterView = nil
            })
            .compactMap { vc, _ in
                return vc.searchBar.searchTextField.text
            }
            .debounce(RxTimeInterval.milliseconds(700), scheduler: MainScheduler.instance)
            .map {
                if $0.count > 0 {
                    return Reactor.Action.searchTodos(searchTerm: $0)
                } else {
                    return Reactor.Action.fetchRefresh
                }
            }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.searchBar.searchTextField.rx.text.orEmpty
            .skip(1)
            .filter { $0.count > 0 }
            .map { _ in Reactor.Action.clearTodos }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.addTodoAction
            .map { Reactor.Action.addTodo(content: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.editTodoAction
            .map { Reactor.Action.editTodo(todo: $0.0, content: $0.1, isDone: $0.2) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.deleteTodoAction
            .map { Reactor.Action.deleteTodo(id: $0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.completedTodosDeleteBtn.rx.tap
            .map { _ in Reactor.Action.completeTodos }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // output
  
        reactor.pulse(\.$todos)
            .asDriver(onErrorJustReturn: [])
            .drive(self.myTableView.rx.items(cellIdentifier: RxTodoCell.reuseIdentifier, cellType: RxTodoCell.self)) { [weak self]index, item, cell in
                print("테스트 150 : $todos")
            guard let self = self else { return }
        
            cell.setTodo(item)
            cell.tappedSwitch = { todo, isDone in
                self.editTodoAction.accept((todo, nil, isDone))
            }
            cell.tappedEditBtn = self.presentEditTodoAlert(todo:existingContent:)
            cell.tappedDeleteBtn = self.presentDeleteTodoAlert(id:)
        }
        .disposed(by: disposeBag)
        
        reactor.state
            .map({ $0.completedTodos.map { "\($0)" }.joined(separator: ", ") })
            .map({ "완료된 일 : \($0)" })
            .asDriver(onErrorJustReturn: "완료된 일 :")
            .drive(completedTodosLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$addedTodo)
            .skip(1)
            .asDriver(onErrorJustReturn: ())
            .drive(with: self, onNext: { vc, _ in
                vc.myTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$refreshEnded)
            .asDriver(onErrorJustReturn: ())
            .drive(with: self, onNext: { vc, _ in
                print("테스트 150 : $refreshEnded")
                vc.refreshControl.endRefreshing()
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$resetSearchTerm)
            .asDriver(onErrorJustReturn: ())
            .drive(with: self, onNext: { vc, _ in
                vc.searchBar.searchTextField.text = nil
            })
            .disposed(by: disposeBag)
        
        // 요점은 isLoading 호출되는 시점, pageInfo가 호출되는 시점
        // pageInfo는 로직상 concat 중간에 위치함
        // isLoading(false)는 로직상 마지막에 위치해야 함
        // 위 이유는 isLoading(false)가 먼저 호출되면 Url 호출 전에 indicator가 꺼짐
        // 해결방안
        // isLoading(false)가 호출 되었을 때
        // pageInfo의 hasNext를 확인
        // 방향은 두가지 tableFooterView가 nil이거나 마지막 페이지인 noPageView거나
        // hasNext를 확인해서 다음 페이지가 있을 경우 nil 없을 경우 noPageView
        // pageInfo가 없는 경우 noContentView가 표시
        // noContentError 발생 시 pageInfo = nil (noContentError는 isLoading(false) 보다 먼저 호출되기에 pageInfo가 nil인 상태가 됨)
        // pageInfo가 nil인 경우 tableFooterView는 nil
        
        reactor.pulse(\.$isLoading)
            .asDriver(onErrorJustReturn: false)
            .drive(with: self, onNext: { vc, isLoading in
                if isLoading {
                    vc.loadingIndicator.startAnimating()
                    vc.myTableView.tableFooterView = vc.indicatorInTableFooterView
                } else {
                    vc.loadingIndicator.stopAnimating()
                    let hasNext = reactor.currentState.pageInfo?.hasNext()
                    vc.myTableView.tableFooterView = (hasNext ?? true) ? nil : vc.noPageView
                }
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$hasContent)
            .asDriver(onErrorJustReturn: false)
            .drive(with: self, onNext: { vc, hasContent in
                print("테스트 150 : $hasContent")
                vc.myTableView.backgroundView = hasContent ? nil : vc.noContentView
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$errorMessage)
            .asDriver(onErrorJustReturn: "오류가 발생했습니다.")
            .drive(with: self, onNext: { vc, input in
                print("테스트 150 : $errorMessage")
                vc.presentGuideAlert(message: input)
            }).disposed(by: disposeBag)
    }
}

// MARK: - Tap Action
extension RxMainVC {
    private func setAddTodoBtnAction() {
        self.addTodoBtn.rx.tap
            .subscribe(with: self, onNext: { vc, _ in
                vc.presentNewTodoAlert()
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - ViewModel Data Binding (Input, Output)
extension RxMainVC {
    
    
    private func setDataBinding() {
        let output = self.todosVM.transform(input: makeInputAction())
        bindingDataState(output)
    }
    
    private func makeInputAction() -> TodosVM_Rx.Input {
        
        let fetchRefresh = self.refreshControl.rx.controlEvent(.valueChanged).map { _ in }
        
        let fetchMoreAction = self.myTableView.rx.isBottomNeared.map { _ in }
        
        let completedTodosDeleteAction = completedTodosDeleteBtn.rx.tap.map { $0 }
        
        let searchTermAction = self.searchBar.searchTextField.rx.text.orEmpty.map { $0 }
        
        return .init(fetchRefresh: fetchRefresh,
                     fetchMoreTodos: fetchMoreAction,
                     addTodo: self.addTodoAction.asObservable(),
                     completedTodosDelete: completedTodosDeleteAction,
                     deleteTodo: self.deleteTodoAction.asObservable(),
                     editTodo: self.editTodoAction.asObservable(),
                     searchTerm: searchTermAction)
    }
    
    private func bindingDataState(_ output: TodosVM_Rx.Output) {
                
        output.todos
            .asDriver(onErrorJustReturn: [])
            .drive(self.myTableView.rx.items(cellIdentifier: RxTodoCell.reuseIdentifier, cellType: RxTodoCell.self)) { [weak self]index, item, cell in
                
                guard let self = self else { return }
            
                cell.setTodo(item)
                cell.tappedSwitch = { todo, isDone in
                    self.editTodoAction.accept((todo, nil, isDone))
                }
                cell.tappedEditBtn = self.presentEditTodoAlert(todo:existingContent:)
                cell.tappedDeleteBtn = self.presentDeleteTodoAlert(id:)
            }
            .disposed(by: disposeBag)
        
        output.notifyPage
            .asDriver(onErrorJustReturn: "페이지 정보가 없습니다.")
            .drive(pageInfoLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.notifyIsLoading
            .asDriver(onErrorJustReturn: false)
            .drive(with: self, onNext: { vc, isLoading in
                vc.myTableView.tableFooterView = isLoading ? vc.indicatorInTableFooterView : nil
                isLoading ? vc.loadingIndicator.startAnimating() : vc.loadingIndicator.stopAnimating()
            })
            .disposed(by: disposeBag)
        
        output.notifyRefresh
            .asDriver(onErrorJustReturn: ())
            .drive(with: self, onNext: { vc, _ in
                vc.refreshControl.endRefreshing()
            }).disposed(by: disposeBag)
        
        output.notifyHasNextPage
            .asDriver(onErrorJustReturn: false)
            .drive(with: self, onNext: { vc, hasNext in
                vc.myTableView.tableFooterView = hasNext ? nil : vc.noPageView
            })
            .disposed(by: disposeBag)
        
        output.notifyCompletedTodo
            .map({ "완료된 일 : \($0)" })
            .asDriver(onErrorJustReturn: "완료된 일 :")
            .drive(completedTodosLabel.rx.text)
            .disposed(by: disposeBag)
        
        output.notifyTodosAdded
            .asDriver(onErrorJustReturn: ())
            .drive(with: self, onNext: { vc, _ in
                vc.myTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            })
            .disposed(by: disposeBag)
       
        output.notifyNoContent
            .asDriver(onErrorJustReturn: true)
            .drive(with: self, onNext: { vc, isEmpty in
                vc.myTableView.backgroundView = isEmpty ? vc.noContentView : nil
            })
            .disposed(by: disposeBag)
        
        output.notifyError
            .asDriver(onErrorJustReturn: "오류가 발생했습니다.")
            .drive(with: self, onNext: { vc, input in
                vc.presentGuideAlert(message: input)
            }).disposed(by: disposeBag)
    }
}

// MARK: - Alert
extension RxMainVC {
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
            self.addTodoAction.accept(userInput)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func presentEditTodoAlert(todo: Todo, existingContent: String) {
        let alert = UIAlertController(title: "수정", message: "수정할 내용을 입력하세요.", preferredStyle: .alert)
        alert.addTextField()
        alert.textFields?.first?.text = existingContent
        alert.addAction(UIAlertAction(title: NSLocalizedString("취소", comment: "Default action"), style: .destructive))
        alert.addAction(UIAlertAction(title: NSLocalizedString("완료", comment: "Default action"), style: .default, handler: { [weak self, weak alert] _ in
            guard let alert = alert,
                  let self = self,
                  let userInput = alert.textFields?.first?.text else { return }
            self.editTodoAction.accept((todo, userInput, nil))
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func presentDeleteTodoAlert(id : Int) {
        let alert = UIAlertController(title: "삭제", message: "할 일을 삭제합니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("취소", comment: "Default action"), style: .destructive))
        alert.addAction(UIAlertAction(title: NSLocalizedString("확인", comment: "Default action"), style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.deleteTodoAction.accept(id)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
}










    




