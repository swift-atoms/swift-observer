#if Tracking
    internal import Synchronization

    extension Observer.Tracking {

        final class Frame: Sendable {

            private let state: Mutex<Accesses>

            init() {
                self.state = Mutex([:])
            }
        }
    }

    extension Observer.Tracking.Frame {

        typealias Accesses = [ObjectIdentifier: (
            registrar: Observer.Registrar, properties: Set<Observer.Property.ID>
        )]
    }

    extension Observer.Tracking.Frame {

        var accesses: Accesses {
            state.withLock { $0 }
        }

        func record(_ registrar: Observer.Registrar, _ propertyID: Observer.Property.ID) {
            let key = registrar.id
            state.withLock { accesses in
                if var existing = accesses[key] {
                    existing.properties.insert(propertyID)
                    accesses[key] = existing
                } else {
                    accesses[key] = (registrar, [propertyID])
                }
            }
        }
    }
#endif
