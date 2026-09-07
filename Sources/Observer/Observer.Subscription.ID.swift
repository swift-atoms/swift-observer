public import Tagged

extension Observer.Subscription {

    public typealias ID = Tagged<Observer.Subscription, UInt64>
}

extension Tagged where Tag == Observer.Subscription, Underlying == UInt64 {

    @inlinable
    public init(_ rawValue: UInt64) {
        self.init(_unchecked: rawValue)
    }
}
