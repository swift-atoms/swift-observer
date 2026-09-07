public import Tagged

extension Observer.Property {

    public typealias ID = Tagged<Observer.Property, UInt32>
}

extension Tagged where Tag == Observer.Property, Underlying == UInt32 {

    @inlinable
    public init(_ rawValue: UInt32) {
        self.init(_unchecked: rawValue)
    }
}
