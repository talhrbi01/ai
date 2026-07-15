import Foundation

enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)

    var value: Value? {
        guard case .loaded(let value) = self else { return nil }
        return value
    }
}
