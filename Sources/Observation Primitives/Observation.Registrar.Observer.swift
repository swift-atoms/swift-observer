import Tagged_Primitives

extension Observation.Registrar {

    struct Observer {

        var properties: Set<Observation.Property.ID>

        var willSet: (@Sendable (Observation.Property.ID) -> Void)?

        var didSet: (@Sendable (Observation.Property.ID) -> Void)?
    }
}
