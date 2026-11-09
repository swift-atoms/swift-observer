public import Tagged

extension Observer {

    public enum Property {}
}

extension Observer.Property {

    public typealias ID = Tagged<Observer.Property, UInt32>
}
