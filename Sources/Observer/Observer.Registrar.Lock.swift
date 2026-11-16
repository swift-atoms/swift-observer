import Lock

extension Observer.Registrar {
    typealias Lock = Lock::Lock<State>
}
