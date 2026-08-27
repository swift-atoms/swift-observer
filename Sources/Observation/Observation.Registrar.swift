public import Ownership
import Synchronization
public import Tagged

extension Observation {

    public struct Registrar: Sendable {
        let _extent: Ownership.Immutable<Mutex<State>>

        public init() {
            self._extent = Ownership.Immutable(Mutex(State()))
        }
    }
}

extension Observation.Registrar {

    public func access(_ propertyID: Observation.Property.ID) {

        _ = propertyID
    }

    public func willSet(_ propertyID: Observation.Property.ID) {
        let callbacks: [@Sendable (Observation.Property.ID) -> Void] =
            _extent.value.withLock { state in
                guard let subscriptionIDs = state.lookups[propertyID] else {
                    return []
                }
                return subscriptionIDs.compactMap { id in
                    state.observers[id]?.willSet
                }
            }
        for callback in callbacks {
            callback(propertyID)
        }
    }

    public func didSet(_ propertyID: Observation.Property.ID) {
        let callbacks: [@Sendable (Observation.Property.ID) -> Void] =
            _extent.value.withLock { state in
                guard let subscriptionIDs = state.lookups[propertyID] else {
                    return []
                }
                return subscriptionIDs.compactMap { id in
                    state.observers[id]?.didSet
                }
            }
        for callback in callbacks {
            callback(propertyID)
        }
    }

    public func withMutation<R: ~Copyable, E: Swift.Error>(
        of propertyID: Observation.Property.ID,
        _ body: () throws(E) -> R
    ) throws(E) -> R {
        willSet(propertyID)
        defer { didSet(propertyID) }
        return try body()
    }
}

extension Observation.Registrar {

    public func subscribe(
        to properties: Set<Observation.Property.ID>,
        willSet: (@Sendable (Observation.Property.ID) -> Void)? = nil,
        didSet: (@Sendable (Observation.Property.ID) -> Void)? = nil
    ) -> Observation.Subscription.ID {
        _extent.value.withLock { state in
            let id = Observation.Subscription.ID(state.nextSubscriptionID)
            state.nextSubscriptionID &+= 1

            state.observers[id] = Observer(
                properties: properties,
                willSet: willSet,
                didSet: didSet
            )

            for propertyID in properties {
                state.lookups[propertyID, default: []].insert(id)
            }

            return id
        }
    }

    public func unsubscribe(_ subscriptionID: Observation.Subscription.ID) {
        _extent.value.withLock { state in
            guard let observer = state.observers.removeValue(forKey: subscriptionID) else {
                return
            }
            for propertyID in observer.properties {
                state.lookups[propertyID]?.remove(subscriptionID)
                if state.lookups[propertyID]?.isEmpty == true {
                    state.lookups[propertyID] = nil
                }
            }
        }
    }
}
