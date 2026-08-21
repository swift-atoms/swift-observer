public import Tagged_Primitives

extension Observation.Property {

    public typealias ID = Tagged<Observation.Property, UInt32>
}

extension Tagged where Tag == Observation.Property, Underlying == UInt32 {

    @inlinable
    public init(_ rawValue: UInt32) {
        self.init(_unchecked: rawValue)
    }
}
