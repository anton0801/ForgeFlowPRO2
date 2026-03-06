import Foundation
import Combine

@MainActor
final class Program: ObservableObject {
    
    @Published private(set) var model: Model
    @Published var viewModel: ViewModel
    
    private let runtime: Runtime
    
    init() {
        self.model = .initial
        self.viewModel = .initial
        self.runtime = Runtime()
        
        runtime.sendMsg = { [weak self] msg in
            self?.send(msg)
        }
    }
    
    func send(_ msg: Msg) {
    
        let (newModel, cmd) = update(msg: msg, model: model)
        
        model = newModel
        viewModel = ViewModel.from(newModel)
        
        runtime.execute(cmd)
    }
}
