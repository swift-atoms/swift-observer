public import Ownership
import Synchronization
public import Tagged

extension Observer {

    public struct Registrar: Sendable {
        let _extent: Ownership.Immutable<Mutex<State>>

        public init() {
            self._extent = Ownership.Immutable(Mutex(State()))
        }
    }
}

extension Observer.Registrar {

    public func willSet(_ propertyID: Observer.Property.ID) {
        let callbacks: [@Sendable (Observer.Property.ID) -> Void] =
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

    public func didSet(_ propertyID: Observer.Property.ID) {
        let callbacks: [@Sendable (Observer.Property.ID) -> Void] =
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
        of propertyID: Observer.Property.ID,
        _ body: () throws(E) -> R
    ) throws(E) -> R {
        willSet(propertyID)
        defer { didSet(propertyID) }
        return try body()
    }
}

extension Observer.Registrar {

    public func subscribe(
        to properties: Set<Observer.Property.ID>,
        willSet: (@Sendable (Observer.Property.ID) -> Void)? = nil,
        didSet: (@Sendable (Observer.Property.ID) -> Void)? = nil
    ) -> Observer.Subscription.ID {
        _extent.value.withLock { state in
            guard let rawValue = state.nextSubscriptionID else {
                preconditionFailure("Observer subscription identifiers exhausted")
            }
            let id = Observer.Subscription.ID(rawValue)
            state.nextSubscriptionID = rawValue == UInt64.max ? nil : rawValue + 1

            state.observers[id] = Registration(
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

    public func unsubscribe(_ subscriptionID: Observer.Subscription.ID) {
        let removed = _extent.value.withLock { state -> Registration? in
            guard let observer = state.observers.removeValue(forKey: subscriptionID) else {
                return nil
            }
            for propertyID in observer.properties {
                state.lookups[propertyID]?.remove(subscriptionID)
                if state.lookups[propertyID]?.isEmpty == true {
                    state.lookups[propertyID] = nil
                }
            }
            return observer
        }
        withExtendedLifetime(removed) {}
    }
}
