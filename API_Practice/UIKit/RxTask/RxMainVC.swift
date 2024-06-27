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
        setAddTodoBtnAction()
    }
    
    // MARK: - UI Setup
    private func setTableview() {
        myTableView.register(RxTodoCell.uinib, forCellReuseIdentifier: RxTodoCell.reuseIdentifier)
        myTableView.refreshControl = refreshControl
    }
    
    private func setAddTodoBtnAction() {
        print("테스트 55 : tap 등록")
        
    }
    
   
}

// MARK: - ReactoreKit
extension RxMainVC {
    func bind(reactor: TodosReactor) {
        print(#fileID, #function, #line, "-vc bind ")
        // input
        self.refreshControl.rx.controlEvent(.valueChanged)
            .map { _ in Reactor.Action.fetchRefresh }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.myTableView.rx.isBottomNeared
            .map { _ in Reactor.Action.fetchMore }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        self.searchBar.searchTextField.rx.text.orEmpty
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
        
        
        // output
        
        // Pulse란?
        // 해당 프로퍼티가 변경될 때만 감지
        // state로 접근하면 state의 변경사항이 발생하라 때 마다 실행됨
        // pulse로 접근하면 특정 프로퍼티가 변경됐을 때만 실행됨
        
        reactor.pulse(\.$todos)
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
        
        reactor.pulse(\.$refreshEnded)
            .asDriver(onErrorJustReturn: ())
            .drive(with: self, onNext: { vc, _ in
                vc.refreshControl.endRefreshing()
                vc.searchBar.searchTextField.text = nil
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$isLoading)
            .asDriver(onErrorJustReturn: false)
            .drive(with: self, onNext: { vc, isLoading in
                vc.myTableView.tableFooterView = isLoading ? vc.indicatorInTableFooterView : nil
                isLoading ? vc.loadingIndicator.startAnimating() : vc.loadingIndicator.stopAnimating()
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$pageInfo)
            .compactMap { $0?.hasNext() }
            .asDriver(onErrorJustReturn: false)
            .drive(with: self, onNext: { vc, hasNext in
                vc.myTableView.tableFooterView = hasNext ? nil : vc.noPageView
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$hasContent)
            .asDriver(onErrorJustReturn: false)
            .drive(with: self, onNext: { vc, isEmpty in
                vc.myTableView.backgroundView = isEmpty ? nil : vc.noContentView
            })
            .disposed(by: disposeBag)
        
        reactor.pulse(\.$errorMessage)
            .asDriver(onErrorJustReturn: "오류가 발생했습니다.")
            .drive(with: self, onNext: { vc, input in
                vc.presentGuideAlert(message: input)
            }).disposed(by: disposeBag)
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
//        alert.addAction(UIAlertAction(title: NSLocalizedString("추가", comment: "Default action"), style: .default, handler: { [weak self, weak alert] _ in
//            guard let alert = alert,
//                  let self = self,
//                  let userInput = alert.textFields?.first?.text else { return }
//            self.addTodoAction.accept(userInput)
//        }))
        
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










    




