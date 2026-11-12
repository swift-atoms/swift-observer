#if Tracking
    internal import Synchronization

    extension Observer.Tracking {

        final class Pending: Sendable {

            private let state: Mutex<[(Observer.Registrar.Lock, Observer.Subscription.ID)]>

            init() {
                self.state = Mutex([])
            }
        }
    }

    extension Observer.Tracking.Pending {

        var subscriptions: [(Observer.Registrar.Lock, Observer.Subscription.ID)] {
            state.withLock { $0 }
        }

        func append(_ extent: Observer.Registrar.Lock, _ id: Observer.Subscription.ID) {
            state.withLock { $0.append((extent, id)) }
        }
    }
#endif
