import Synchronization

extension Observer.Registrar {

    /// The registrar's shared, mutually exclusive state.
    ///
    /// Hosted platforms guard the state with `Mutex`. Embedded Swift's
    /// `Synchronization` module ships `Atomic` on every target but `Mutex`
    /// only on some (none on `wasm32-unknown-wasip1` or bare-metal ARM), so
    /// embedded builds guard it with an `Atomic<Bool>` spin lock instead.
    /// The registrar never calls out while holding the lock, so it is held
    /// only for short dictionary updates.
    final class Lock: Sendable {
        #if hasFeature(Embedded)
            private let locked = Atomic<Bool>(false)
            private nonisolated(unsafe) var state = State()
        #else
            private let mutex = Mutex(State())
        #endif

        init() {}
    }
}

extension Observer.Registrar.Lock {

    func withLock<R: Sendable>(_ body: (inout Observer.Registrar.State) -> R) -> R {
        #if hasFeature(Embedded)
            while !locked.compareExchange(
                expected: false,
                desired: true,
                successOrdering: .acquiring,
                failureOrdering: .relaxed
            ).exchanged {}
            defer { locked.store(false, ordering: .releasing) }
            return unsafe body(&state)
        #else
            return mutex.withLock { state in body(&state) }
        #endif
    }
}
