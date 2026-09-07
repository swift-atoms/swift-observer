import Tagged

extension Observer.Registrar {

    struct State {

        var lookups: [Observer.Property.ID: Set<Observer.Subscription.ID>] = [:]

        var observers: [Observer.Subscription.ID: Registration] = [:]

        var nextSubscriptionID: UInt64 = 0
    }
}
