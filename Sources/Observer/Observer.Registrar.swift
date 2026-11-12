public import Tagged

extension Observer {

    public struct Registrar: Sendable {
        let _extent: Lock
        let _lifetime: Lifetime

        public init() {
            let extent = Lock()
            self._extent = extent
            self._lifetime = Lifetime(extent)
        }
    }
}

extension Observer.Registrar {

    public func willSet(_ propertyID: Observer.Property.ID) {
        let callbacks: [@Sendable (Observer.Property.ID) -> Void] =
            _extent.withLock { state in
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
            _extent.withLock { state in
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

    public func withMutation<R: ~Copyable, E: Swift::Error>(
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
        _extent.subscribe(to: properties, willSet: willSet, didSet: didSet)
    }

    public func unsubscribe(_ subscriptionID: Observer.Subscription.ID) {
        _extent.unsubscribe(subscriptionID)
    }
}

extension Observer.Registrar {

    public var id: ObjectIdentifier {
        ObjectIdentifier(_extent)
    }
}
