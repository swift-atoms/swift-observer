import Tagged

extension Observer.Registrar.Lock {

    func subscribe(
        to properties: Set<Observer.Property.ID>,
        willSet: (@Sendable (Observer.Property.ID) -> Void)? = nil,
        didSet: (@Sendable (Observer.Property.ID) -> Void)? = nil
    ) -> Observer.Subscription.ID {
        withLock { state in
            guard let rawValue = state.nextSubscriptionID else {
                preconditionFailure("Observer subscription identifiers exhausted")
            }
            let id = Observer.Subscription.ID(rawValue)
            state.nextSubscriptionID = rawValue == UInt64.max ? nil : rawValue + 1

            state.observers[id] = Observer.Registrar.Registration(
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

    func unsubscribe(_ subscriptionID: Observer.Subscription.ID) {
        let removed = withLock { state -> Observer.Registrar.Registration? in
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
