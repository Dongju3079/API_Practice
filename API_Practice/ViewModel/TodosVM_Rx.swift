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

class TodosVM_Rx: ObservableObject {
    
    // 1. Observable : 데이터 전달 1회 후 완료
    // 2. BehaviorRelay - 지속적인 사용 가능 (마지막에 받은 데이터 .value 로 접근 가능)
    // 3. PublishRelay
    
    private var disposeBag = DisposeBag()
    
    // VC -> VM
    var searchTerm: BehaviorRelay<String> = .init(value: "")
    
    // 값을 가지고 여러곳에서 사용되고 있음
    private var todos: BehaviorRelay<[Todo]> = .init(value: [])
    private var completedTodos: BehaviorRelay<Set<Int>> = .init(value: Set())
    private var pageInfo : BehaviorRelay<Meta?> = .init(value: nil)
    private var currentPage : BehaviorRelay<Int> = .init(value: 1)
    private var isLoading: BehaviorRelay<Bool> = .init(value: false)
    
    // 값을 가질 필요가 없음 VM -> VC
    var notifyTodos: Observable<[Todo]>
    var notifyPage : Observable<String>
    var notifyHasNextPage : Observable<Bool>
    var notifyIsLoading : Observable<Bool>
    var notifyCompletedTodo : Observable<String>
    
    
    // 값을 가질 필요가 없으나 VM에서 이벤트 또는 값을 받을 수 있어야 함 VM -> VC
    var notifyTodosAdded = PublishSubject<Void>()
    var notifyRefresh = PublishSubject<Void>()
    var notifyNoContent = PublishSubject<Bool>()
    var notifyError = PublishSubject<String>()
    
    init() {
        // VM에서 처리해서 보내주는 형식
        self.notifyTodos = todos.map({ $0 })
        self.notifyPage = currentPage.map({ "페이지 : \($0)" })
        self.notifyHasNextPage = pageInfo.skip(1).map({ $0?.hasNext() ?? false })
        self.notifyIsLoading = isLoading.map({ $0 })
        self.notifyCompletedTodo = completedTodos.map({ $0.map { "\($0)" }.joined(separator: ", ") })
        
        self.todos
            .map {
                let completedTodos = $0.filter { $0.isDone == true }.compactMap { $0.id }
                let setCompletedTodos = Set(completedTodos)
                return setCompletedTodos }
            .withUnretained(self)
            .subscribe(onNext: { vm, completedTodo in
                vm.completedTodos.accept(completedTodo)
            }).disposed(by: disposeBag)
        
        self.pageInfo
            .compactMap{ $0 }
            .map{
                if let currentPage = $0.currentPage {
                    return currentPage
                } else {
                    return 1
                }
            }
            .withUnretained(self)
            .bind(onNext: { vm, page in
                vm.currentPage.accept(page)
            })
            .disposed(by: disposeBag)
        
        self.searchTerm
            .debug("searchTerm debug")
            .withUnretained(self)
            .do(onNext: { vm, _ in
                vm.todos.accept([])
                vm.notifyNoContent.onNext(false)
            })
            .debounce(.milliseconds(700), scheduler: MainScheduler.instance)
            .subscribe { vm, searchTerm in
                if searchTerm.count > 0 {
                    self.pageInfo.accept(nil)
                    self.currentPage.accept(1)
                    self.searchTodo(term: searchTerm, page: vm.currentPage.value)
                } else {
                    self.fetchTodos(page: 1)
                }
            }
            .disposed(by: disposeBag)

    }
    
    private func handleError(_ err: Error) {
        
        guard let apiError = err as? TodosAPI_Rx.ApiError else {
            let unknownError = TodosAPI_Rx.ApiError.unknown(err)
            notifyError.onNext(unknownError.info)
            return
        }
        
        switch apiError {
        case .noContent:
            notifyNoContent.onNext((true))
        case .errResponseFromServer(let errorResponse):
            notifyError.onNext(errorResponse?.message ?? "알 수 없는 에러")
        default:
            notifyError.onNext(apiError.info)
        }
    }
    
}

// MARK: - fetch Data
extension TodosVM_Rx {
    
//    func getCompletedTodo() -> [Int] {
//        return Array(self.completedTodos.value)
//    }
    
    func fetchRefresh() {
        self.fetchTodos(page: 1)
    }
    
    func fetchMoreTodos() {
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
                    vm.notifyRefresh.onNext(())
                    vm.isLoading.accept(false)
                    vm.pageInfo.accept(response.0)
                },onError: { [weak self] err in
                    guard let self = self else { return }
                    self.isLoading.accept(false)
                    self.handleError(err)
                })
            .disposed(by: disposeBag)
    }
    
    private func searchTodo(term: String, page: Int) {
        
        guard checkIsLoading() else { return }
        
        TodosAPI_Rx.searchTodosRx(searchTerm: term, page: page)
            .delay(.milliseconds(700), scheduler: MainScheduler.instance)
            .compactMap { Optional(tuple: ($0.meta, $0.data)) }
            .subscribe(
                onNext: { (meta, fetchTodos) in

                    if page == 1 {
                        self.todos.accept(fetchTodos)
                    } else {
                        let existingTodos = self.todos.value
                        self.todos.accept(existingTodos + fetchTodos)
                    }
                    self.isLoading.accept(false)
                    self.pageInfo.accept(meta)
                },onError: { err in
                    self.isLoading.accept(false)
                    self.handleError(err)
                }
            )
            .disposed(by: disposeBag)
    }
    
    func addTodo(content: String) {
        guard checkIsLoading() else { return }
        
        TodosAPI_Rx.addTodoAndFetchTodos(content: content)
            .delay(.milliseconds(700), scheduler: MainScheduler.instance)
            .compactMap { Optional(tuple: ($0.meta, $0.data)) }
            .withUnretained(self)
            .subscribe(onNext: { vm, response in
                vm.todos.accept(response.1)
                
                vm.isLoading.accept(false)
                vm.pageInfo.accept(response.0)
                vm.notifyTodosAdded.onNext(())
                
            },onError: { [weak self] err in
                guard let self = self else { return }
                self.isLoading.accept(false)
                self.handleError(err)
            })
            .disposed(by: disposeBag)
    }
    
    func handleTodoSelection(id : Int, isDone: Bool) {
        
        var selectionTodo = self.completedTodos.value
        
        if isDone {
            selectionTodo.insert(id)
            self.completedTodos.accept(selectionTodo)
            
        } else {
            selectionTodo.remove(id)
            self.completedTodos.accept(selectionTodo)
        }
        
    }
    
    func completedTodosDelete() {
        
        guard !self.completedTodos.value.isEmpty else { return }
        guard checkIsLoading() else { return }
        
        TodosAPI_Rx.deleteTodosRxZip(selectedTodos: Array(self.completedTodos.value))
            .delay(.milliseconds(700), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe (onNext: { vm, completedTodosId in
                let existingTodosList = vm.todos.value
                let existingCompletedTodos = vm.completedTodos.value

                let afterTaskTodosList = existingTodosList.filter { !completedTodosId.contains($0.id ?? 0)}
                
                let afterTaskCompletedTodos = existingCompletedTodos.filter { !completedTodosId.contains($0)}
                
                vm.completedTodos.accept(afterTaskCompletedTodos)
                vm.todos.accept(afterTaskTodosList)
                vm.isLoading.accept(false)
            }, onError: { [weak self] err in
                guard let self = self else { return }
                self.handleError(err)
                self.isLoading.accept(false)
            })
            .disposed(by: disposeBag)
    }
    
    func deleteTodo(_ id: Int) {
        guard checkIsLoading() else { return }
        
        TodosAPI_Rx.deleteTodoRx(id: id)
            .withUnretained(self)
            .subscribe(onNext: { vm, response in
                guard let deleteTodo = response.data else { return }
                let existingTodosList = vm.todos.value
                let afterTaskTodosList = existingTodosList.filter { $0.id != deleteTodo.id }
                vm.todos.accept(afterTaskTodosList)
                vm.isLoading.accept(false)
            }, onError: { [weak self] err in
                guard let self = self else { return }
                self.handleError(err)
                self.isLoading.accept(false)
            }).disposed(by: disposeBag)
    }
    
    func editTodo(todo: Todo, editContent: String? = nil, changeIsDone: Bool? = nil) {
        
        guard checkIsLoading() else { return }
        
        guard let id = todo.id,
              let existingContent = todo.title,
              let existingIsDone = todo.isDone,
              let index = self.todos.value.firstIndex(where: { $0.id == id }) else { return }
        
        let content = editContent ?? existingContent
        let isDone = changeIsDone ?? existingIsDone
        
        TodosAPI_Rx.editTodoRxEncoded(id: id, content: content, isDone: isDone)
            .withUnretained(self)
            .subscribe(onNext: { vm, response in
                guard let todo = response.data else { return }
                var todosList = vm.todos.value
                todosList[index] = todo
                vm.todos.accept(todosList)
                self.isLoading.accept(false)
            }, onError: { [weak self] err in
                guard let self = self else { return }
                self.handleError(err)
                self.isLoading.accept(false)
            }).disposed(by: disposeBag)
            
        
    }
//    private func deleteTodosZip() {
//        TodosAPI_Rx.deleteTodosRxZip(selectedTodos: [5149, 5169, 5163, 5162, 5160, 5159, 5158, 5156, 5154, 5153])
//            .observe(on: MainScheduler.instance)
//            .subscribe(onNext: { todos in
//                print("테스트 할 일 목록 : \(todos)")
//            })
//            .disposed(by: disposeBag)
//    }
//    
//    private func deleteTodosMerge() {
//        TodosAPI_Rx.deleteTodosRxMerge(selectedTodos: [2664, 2682])
//            .observe(on: MainScheduler.instance)
//            .subscribe(onNext: { todos in
//                print("테스트 할 일 목록 : \(todos)")
//            })
//            .disposed(by: disposeBag)
//    }
//    
//    private func addTodoAndFetchTodos() {
//        TodosAPI_Rx.addTodoAndFetchTodos(content: "add And Fetch", isDone: true)
//            .observe(on: MainScheduler.instance)
//            .subscribe(onNext: { todos in
//                print("테스트 할 일 목록 : \(todos)")
//            })
//            .disposed(by: disposeBag)
//    }
//    
//    private func fetchTodos() {
//        TodosAPI_Rx.fetchTodosRx()
//            .observe(on: MainScheduler.instance)
//            .subscribe(onNext: { [weak self] result in
//                guard let self = self else { return }
//                switch result {
//                case .success(let todos):
//                    print("테스트 할 일 : \(todos)")
//                case .failure(let err):
//                    self.handleError(err)
//                }
//            }).disposed(by: disposeBag)
//    }
//    
//    private func fetchTodosAddErrorTask() {
//        TodosAPI_Rx.fetchTodosRxAddErrorTask()
//            .observe(on: MainScheduler.instance)
//            .compactMap { $0.data }
//            .catchAndReturn([])
//            .subscribe(onNext: { todoList in
//                print("테스트 todoList : \(todoList)")
//
//            }).disposed(by: disposeBag)
//    }
//    
//    private func addTodoMultipart() {
//        TodosAPI_Rx.addTodoRxByMultipart(content: "Rx 추가완료", isDone: false)
//            .observe(on: MainScheduler.instance)
//            .subscribe(onNext: { [weak self] result in
//                guard let self = self else { return }
//                switch result {
//                case .success(let todos):
//                    print("테스트 할 일 : \(todos)")
//                case .failure(let err):
//                    self.handleError(err)
//                }
//            }).disposed(by: disposeBag)
//    }
//    
//    private func searchTodo() {
//        TodosAPI_Closure.addTodoClosureByMultipart(content: "테스트합니다 1234",
//                                           isDone: true) { result in
//            switch result {
//            case .success(let todoList):
//                print("테스트 success : \(todoList)")
//
//            case .failure(let failure):
//                self.handleError(failure)
//            }
//        }
//    }
//    
//    private func addTodoJson() {
//            
//        TodosAPI_Rx.addTodoRxByJson(content: "Json(Rx) 추가완료", isDone: false)
//            .observe(on: MainScheduler.instance)
//            .subscribe(onNext: { [weak self] result in
//                guard let self = self else { return }
//                switch result {
//                case .success(let todos):
//                    print("테스트 할 일 : \(todos)")
//                case .failure(let err):
//                    self.handleError(err)
//                }
//            }).disposed(by: disposeBag)
//    }
//    
////    private func searchTodo() {
////        TodosAPI_Closure.searchTodoClosure(id: 5168) { result in
////            switch result {
////            case .success(let todoList):
////                print("테스트 success : \(todoList)")
////
////            case .failure(let failure):
////                self.handleError(failure)
////            }
////        }
////    }
//    
//    private func editTodoEncoded() {
//        TodosAPI_Closure.editTodoClosureEncoded(id: 5168,
//                                 content: "5168 Edit",
//                                 isDone: true) { result in
//            switch result {
//            case .success(let todo):
//                print("테스트 todo : \(todo)")
//            case .failure(let err):
//                self.handleError(err)
//
//            }
//        }
//    }
//    
//    private func deleteTodo() {
//        TodosAPI_Rx.deleteTodoRx(id: 4613)
//            .observe(on: MainScheduler.instance)
//            .subscribe(onNext: { todo in
//                print(#fileID, #function, #line, "-delete todo : \(todo) ")
//            }, onError: { [weak self] err in
//                guard let self = self else { return }
//                self.handleError(err)
//            })
//            .disposed(by: disposeBag)
//    }
//    
//    private func editTodoJson() {
//        TodosAPI_Closure.editTodoClosureByJson(id: 5166,
//                                 content: "수정된 5166",
//                                 isDone: true) { result in
//            switch result {
//            case .success(let todo):
//                print("테스트 todo : \(todo)")
//            case .failure(let err):
//                self.handleError(err)
//
//            }
//        }
//    }
}

// MARK: - Rx to Async
//extension TodosVM_Rx {
//    
//    private func fetchTodoRxToAsync() {
//        Task {
//            do {
//                let _ = try await TodosAPI_Rx.fetchTodosRxAddErrorTask().toAsync()
//            } catch {
//                self.handleError(error)
//            }
//        }
//    }
//}
//
//// MARK: - Rx to Combine
//extension TodosVM_Rx {
//    private func fetchTodoRxToCombine() {
//        TodosAPI_Rx.fetchTodosRxAddErrorTask()
//            .publisher
//            .sink {[weak self] completion in
//                guard let self = self else { return }
//                switch completion {
//                case .finished:
//                    print("테스트 finished")
//                case .failure(let err):
//                    self.handleError(err)
//                }
//            } receiveValue: { listResponse in
//                print("테스트 listData : \(listResponse)")
//            }
//            .store(in: &subscriptions)
//    }
//}

// MARK: - Helper
extension TodosVM_Rx {
    private func checkIsLoading() -> Bool {
        
        if isLoading.value {
            return false
        } else {
            isLoading.accept(true)
            return true
        }
    }
}



