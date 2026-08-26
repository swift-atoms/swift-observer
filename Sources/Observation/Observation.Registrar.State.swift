import Tagged

extension Observation.Registrar {

    struct State {

        var lookups: [Observation.Property.ID: Set<Observation.Subscription.ID>] = [:]

        var observers: [Observation.Subscription.ID: Observer] = [:]

        var nextSubscriptionID: UInt64 = 0
    }
}
