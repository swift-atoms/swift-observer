public import Tagged

extension Observation.Subscription {

    public typealias ID = Tagged<Observation.Subscription, UInt64>
}

extension Tagged where Tag == Observation.Subscription, Underlying == UInt64 {

    @inlinable
    public init(_ rawValue: UInt64) {
        self.init(_unchecked: rawValue)
    }
}
