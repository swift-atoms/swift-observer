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
            extent: Observer.Registrar.Lock, properties: Set<Observer.Property.ID>
        )]
    }

    extension Observer.Tracking.Frame {

        var accesses: Accesses {
            state.withLock { $0 }
        }

        func record(_ registrar: Observer.Registrar, _ propertyID: Observer.Property.ID) {
            let key = registrar.id
            let extent = registrar._extent
            state.withLock { accesses in
                if var existing = accesses[key] {
                    existing.properties.insert(propertyID)
                    accesses[key] = existing
                } else {
                    accesses[key] = (extent, [propertyID])
                }
            }
        }

        func merge(_ other: Accesses) {
            state.withLock { accesses in
                for (key, value) in other {
                    if var existing = accesses[key] {
                        existing.properties.formUnion(value.properties)
                        accesses[key] = existing
                    } else {
                        accesses[key] = value
                    }
                }
            }
        }
    }
#endif
