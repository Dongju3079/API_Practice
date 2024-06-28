//
//  TodosVM+Closure.swift
//  API_Practice
//
//  Created by CatSlave on 6/4/24.
//

import Foundation
import RxSwift
import RxCocoa
import RxRelay
import RxCombine

// 1. Observable : 데이터 전달 1회 후 완료
// 2. BehaviorRelay - 지속적인 사용 가능 (마지막에 받은 데이터 .value 로 접근 가능)
// 3. PublishRelay

class TodosVM_Rx: ObservableObject, ViewModelType {
    
    private var disposeBag = DisposeBag()
    
    struct Input {
        let fetchRefresh : Observable<Void>
        let fetchMoreTodos : Observable<Void>
        let addTodo : Observable<String>
        let completedTodosDelete : Observable<Void>
        let deleteTodo : Observable<Int>
        let editTodo : Observable<(Todo, String?, Bool?)>
        let searchTerm : Observable<String>
    }
    
    struct Output {
        let todos : Observable<[Todo]>
        let notifyPage : Observable<String>
        let notifyHasNextPage : Observable<Bool>
        let notifyIsLoading : Observable<Bool>
        let notifyCompletedTodo : Observable<String>
        let notifyTodosAdded : Observable<Void>
        let notifyRefresh : Observable<Void>
        let notifyNoContent : Observable<Bool>
        let notifyError : Observable<String>
    }
    
    func transform(input: Input) -> Output {

        input.fetchRefresh
            .bind(with: self) { vm, _ in
                vm.fetchRefresh()
            }.disposed(by: disposeBag)
        
        input.fetchMoreTodos
            .bind(with: self) { vm, _ in
                vm.fetchMoreTodos()
            }.disposed(by: disposeBag)
        
        input.addTodo
            .bind(with: self, onNext: { vm, content in
                vm.addTodo(content)
            })
            .disposed(by: disposeBag)
        
        input.completedTodosDelete
            .bind(with: self, onNext: { vm, _ in
                vm.completedTodosDelete()
            })
            .disposed(by: disposeBag)
        
        input.deleteTodo
            .bind(with: self, onNext: { vm, id in
                vm.deleteTodo(id)
            })
            .disposed(by: disposeBag)
        
        input.editTodo
            .bind(with: self, onNext: { vm, editTodo in
                vm.editTodo(editTodo: editTodo)
            })
            .disposed(by: disposeBag)
        
        input.searchTerm
            .withUnretained(self)
            .do(onNext: { vm, _ in
                vm.todos.accept([])
                vm.notifyNoContent.accept(false)
            })
            .debounce(.milliseconds(700), scheduler: MainScheduler.instance)
            .subscribe { vm, searchTerm in
                vm.searchTerm.accept(searchTerm)
                
                if searchTerm.count > 0 {
                    self.pageInfo.accept(nil)
                    self.currentPage.accept(1)
                    self.searchTodo(term: searchTerm, page: vm.currentPage.value)
                } else {
                    self.fetchTodos(page: 1)
                }
            }
            .disposed(by: disposeBag)
        
        let notifyPage = currentPage.map({ "페이지 : \($0)" })
        let notifyHasNextPage = pageInfo.skip(1).map({ $0?.hasNext() ?? false })
        let notifyCompletedTodos = completedTodos.map({ $0.map { "\($0)" }.joined(separator: ", ") })
        
        return Output(todos: self.todos.asObservable(),
                      notifyPage: notifyPage,
                      notifyHasNextPage: notifyHasNextPage,
                      notifyIsLoading: self.isLoading.asObservable(),
                      notifyCompletedTodo: notifyCompletedTodos,
                      notifyTodosAdded: self.todoAdded.asObservable(),
                      notifyRefresh: self.refreshCompleted.asObservable(),
                      notifyNoContent: self.notifyNoContent.asObservable(),
                      notifyError: self.errorAccrued.asObservable())
    }
    
    // ViewModel 내부에서 값을 받거나 VC로 값을 보내주는 용도
    private var todos: BehaviorRelay<[Todo]> = .init(value: [])
    private var completedTodos: BehaviorRelay<Set<Int>> = .init(value: Set())
    private var searchTerm: BehaviorRelay<String> = .init(value: "")
    private var pageInfo : BehaviorRelay<Meta?> = .init(value: nil)
    private var currentPage : BehaviorRelay<Int> = .init(value: 1)
    private var isLoading: BehaviorRelay<Bool> = .init(value: false)
    private var notifyNoContent: BehaviorRelay<Bool> = .init(value: false)
    private var todoAdded: PublishRelay<Void> = .init()
    private var refreshCompleted: PublishRelay<Void> = .init()
    private var errorAccrued: PublishRelay<String> = .init()
    
    init() {
        
        self.todos
            .map {
                let completedTodos = $0.filter { $0.isDone == true }.compactMap { $0.id }
                return Set(completedTodos)
            }
            .bind(to: completedTodos)
            .disposed(by: disposeBag)
        
        self.pageInfo
            .compactMap{ $0 }
            .map{ $0.currentPage ?? 1 }
            .bind(to: currentPage)
            .disposed(by: disposeBag)
    }
}

// MARK: - fetch Data
extension TodosVM_Rx {
    
    private func fetchRefresh() {
        self.fetchTodos(page: 1)
    }
    
    private func fetchMoreTodos() {
        guard let pageInfo = self.pageInfo.value,
              pageInfo.hasNext() else { return }
        
        if searchTerm.value.isEmpty {
            self.fetchTodos(page: self.currentPage.value + 1)
        } else {
            let term = searchTerm.value
            let page = currentPage.value + 1
            self.searchTodo(term: term, page: page)
        }
    }
    
    private func addTodo(_ content: String) {
        guard checkIsLoading() else { return }
        
        TodosAPI_Rx.addTodoAndFetchTodos(content: content)
            .delay(.milliseconds(700), scheduler: MainScheduler.instance)
            .compactMap { 
                let test = Optional(tuple: ($0.meta, $0.data))
                return test
            }
            .withUnretained(self)
            .subscribe(
                onNext: { vm, response in
                    vm.todos.accept(response.1)
                    vm.isLoading.accept(false)
                    vm.pageInfo.accept(response.0)
                    vm.todoAdded.accept(())
                },onError: { [weak self] err in
                    guard let self = self else { return }
                    self.isLoading.accept(false)
                    self.handleError(err)
                },onCompleted: { [weak self] in
                    guard let self = self else { return }
                    self.isLoading.accept(false)
                })
            .disposed(by: disposeBag)
    }
    
    private func completedTodosDelete() {
        
        guard !self.completedTodos.value.isEmpty else { return }
        guard checkIsLoading() else { return }
        
        TodosAPI_Rx.deleteTodosRxZip(selectedTodos: Array(self.completedTodos.value))
            .delay(.milliseconds(700), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(
                onNext: { vm, completedTodosId in
                    let afterTaskTodosList = vm.todos.value.filter { !completedTodosId.contains($0.id ?? 0)}
                    vm.todos.accept(afterTaskTodosList)
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.handleError(err)
                },onCompleted: { [weak self] in
                    guard let self = self else { return }
                    self.isLoading.accept(false)
                })
            .disposed(by: disposeBag)
    }
    
    private func deleteTodo(_ id: Int) {
        guard checkIsLoading() else { return }
        
        TodosAPI_Rx.deleteTodoRx(id: id)
            .withUnretained(self)
            .subscribe(onNext: { vm, response in
                guard let deleteTodo = response.data else { return }
                let existingTodosList = vm.todos.value
                let afterTaskTodosList = existingTodosList.filter { $0.id != deleteTodo.id }
                vm.todos.accept(afterTaskTodosList)
            }, onError: { [weak self] err in
                guard let self = self else { return }
                self.handleError(err)
            },onCompleted: { [weak self] in
                guard let self = self else { return }
                self.isLoading.accept(false)
            }).disposed(by: disposeBag)
    }
    
    private func editTodo(editTodo: (todo: Todo, content:  String?, isDone: Bool?)) {
        
        guard checkIsLoading() else { return }
        
        guard let id = editTodo.todo.id,
              let existingContent = editTodo.todo.title,
              let existingIsDone = editTodo.todo.isDone,
              let index = self.todos.value.firstIndex(where: { $0.id == id }) else { return }
        
        let content = editTodo.content ?? existingContent
        let isDone = editTodo.isDone ?? existingIsDone
        
        TodosAPI_Rx.editTodoRxEncoded(id: id, content: content, isDone: isDone)
            .withUnretained(self)
            .subscribe(
                onNext: { vm, response in
                    guard let todo = response.data else { return }
                    var todosList = vm.todos.value
                    todosList[index] = todo
                    vm.todos.accept(todosList)
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.handleError(err)
                },onCompleted: { [weak self] in
                    guard let self = self else { return }
                    self.isLoading.accept(false)
                })
            .disposed(by: disposeBag)
    }
    
    // 내부 사용
    private func fetchTodos(page: Int) {
        
        guard checkIsLoading() else { return }
        
        TodosAPI_Rx.fetchTodosRxAddErrorTask(page: page)
            .delay(.milliseconds(700), scheduler: MainScheduler.instance)
            .compactMap { Optional(tuple: ($0.meta, $0.data)) }
            .withUnretained(self)
            .subscribe(
                onNext: { (vm, response) in
                    if page == 1 {
                        vm.todos.accept(response.1)
                    } else {
                        let existingTodos = self.todos.value
                        vm.todos.accept(existingTodos + response.1)
                    }
                    vm.refreshCompleted.accept(())
                    vm.pageInfo.accept(response.0)
                },onError: { [weak self] err in
                    guard let self = self else { return }
                    self.handleError(err)
                },onCompleted: { [weak self] in
                    guard let self = self else { return }
                    self.isLoading.accept(false)
                })
            .disposed(by: disposeBag)
    }
    
    private func searchTodo(term: String, page: Int) {
        guard checkIsLoading() else { return }
        
        TodosAPI_Rx.searchTodosRx(searchTerm: term, page: page)
            .delay(.milliseconds(700), scheduler: MainScheduler.instance)
            .compactMap { Optional(tuple: ($0.meta, $0.data)) }
            .withUnretained(self)
            .subscribe(
                onNext: { vm, response in
                    if page == 1 {
                        self.todos.accept(response.1)
                    } else {
                        let existingTodos = self.todos.value
                        self.todos.accept(existingTodos + response.1)
                    }
                    self.isLoading.accept(false)
                    self.pageInfo.accept(response.0)
                    print("테스트 150 : page has next \(response.0.hasNext())")

                },onError: { [weak self] err in
                    guard let self = self else { return }
                    self.handleError(err)
                },onCompleted: { [weak self] in
                    guard let self = self else { return }
                    print("테스트 150 : load end")
                    
                })
            .disposed(by: disposeBag)
    }
}

// MARK: - Helper
extension TodosVM_Rx {
    private func handleError(_ err: Error) {
        
        self.isLoading.accept(false)
        
        guard let apiError = err as? TodosAPI_Rx.ApiError else {
            let unknownError = TodosAPI_Rx.ApiError.unknown(err)
            self.errorAccrued.accept(unknownError.info)
            return
        }
        
        switch apiError {
        case .noContent:

            notifyNoContent.accept((true))
        case .errResponseFromServer(let errorResponse):
            errorAccrued.accept(errorResponse?.message ?? "알 수 없는 에러")
        default:
            errorAccrued.accept(apiError.info)
        }
    }
    
    private func checkIsLoading() -> Bool {
        
        if isLoading.value {
            return false
        } else {
            isLoading.accept(true)
            return true
        }
    }
}




