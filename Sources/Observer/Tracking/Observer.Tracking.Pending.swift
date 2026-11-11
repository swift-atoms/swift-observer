#if Tracking
    internal import Synchronization

    extension Observer.Tracking {

        final class Pending: Sendable {

            private let state: Mutex<[(Observer.Registrar, Observer.Subscription.ID)]>

            init() {
                self.state = Mutex([])
            }
        }
    }

    extension Observer.Tracking.Pending {

        var subscriptions: [(Observer.Registrar, Observer.Subscription.ID)] {
            state.withLock { $0 }
        }

        func append(_ registrar: Observer.Registrar, _ id: Observer.Subscription.ID) {
            state.withLock { $0.append((registrar, id)) }
        }
    }
#endif
