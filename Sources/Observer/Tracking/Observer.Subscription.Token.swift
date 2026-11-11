#if Tracking
    extension Observer.Subscription {

        public struct Token: ~Copyable, Sendable {
            @usableFromInline
            var _registrar: Observer.Registrar?

            @usableFromInline
            var _id: Observer.Subscription.ID?

            @inlinable
            public init(_ registrar: Observer.Registrar, _ id: Observer.Subscription.ID) {
                self._registrar = registrar
                self._id = id
            }

            deinit {
                if let registrar = _registrar, let id = _id {
                    registrar.unsubscribe(id)
                }
            }
        }
    }

    extension Observer.Subscription.Token {

        @inlinable
        public mutating func detach() -> (Observer.Registrar, Observer.Subscription.ID)? {
            guard let registrar = _registrar, let id = _id else { return nil }
            _registrar = nil
            _id = nil
            return (registrar, id)
        }
    }
#endif
