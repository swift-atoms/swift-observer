public import Tagged

extension Observer {

    public enum Subscription {}
}

extension Observer.Subscription {

    public typealias ID = Tagged<Observer.Subscription, UInt64>
}
