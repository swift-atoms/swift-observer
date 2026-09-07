import Tagged

extension Observer.Registrar {

    struct Registration: Sendable {

        var properties: Set<Observer.Property.ID>

        var willSet: (@Sendable (Observer.Property.ID) -> Void)?

        var didSet: (@Sendable (Observer.Property.ID) -> Void)?
    }
}
