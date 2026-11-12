import Tagged

extension Observer.Registrar {

    final class Lifetime: Sendable {
        let extent: Lock

        init(_ extent: Lock) {
            self.extent = extent
        }

        deinit {
            let removed = extent.withLock { state -> [Observer.Subscription.ID: Registration] in
                let observers = state.observers
                state.observers = [:]
                state.lookups = [:]
                return observers
            }
            withExtendedLifetime(removed) {}
        }
    }
}
