import Tagged

extension Observer.Registrar {

    struct Registration {

        var properties: Set<Observer.Property.ID>

        var willSet: (@Sendable (Observer.Property.ID) -> Void)?

        var didSet: (@Sendable (Observer.Property.ID) -> Void)?
    }
}
