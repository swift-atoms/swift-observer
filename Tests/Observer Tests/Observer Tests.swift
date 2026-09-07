import Tagged
import Testing

@testable import Observer

extension Observer {
    @Suite("Observer")
    struct Test {
        @Suite struct ProtocolConformance {}
        @Suite struct PropertyID {}
        @Suite struct SubscriptionID {}
    }
}

extension Observer.Test.ProtocolConformance {

    @Test
    func `Copyable struct can conform to Observable via marker`() {
        struct Counter: Observable {
            var raw: Int = 0
        }
        let c = Counter()
        #expect(c.raw == 0)
    }

    @Test
    func `~Copyable struct can conform to Observable`() {
        struct UniqueCounter: ~Copyable, Observable {
            var raw: Int = 0
        }
        let u = UniqueCounter()
        #expect(u.raw == 0)
    }

    @Test
    func `Observable typealias resolves to Observer dot Protocol`() {

        struct Foo: Observer.`Protocol` {
            var x: Int = 0
        }
        struct Bar: Observable {
            var y: Int = 0
        }
        let f = Foo()
        let b = Bar()
        #expect(f.x == b.y)
    }
}

extension Observer.Test.PropertyID {

    @Test
    func `PropertyID wraps UInt32 raw value`() {
        let id: Observer.Property.ID = .init(42)
        #expect(id.underlying == 42)
    }

    @Test
    func `PropertyID is Hashable`() {
        let a: Observer.Property.ID = .init(1)
        let b: Observer.Property.ID = .init(1)
        let c: Observer.Property.ID = .init(2)
        #expect(a == b)
        #expect(a != c)
        #expect(a.hashValue == b.hashValue)
    }

    @Test
    func `PropertyID is usable as Set / Dictionary key`() {
        let set: Set<Observer.Property.ID> = [.init(0), .init(1), .init(2), .init(0)]
        #expect(set.count == 3)

        let dict: [Observer.Property.ID: String] = [
            .init(0): "zero",
            .init(42): "answer",
        ]
        #expect(dict[.init(42)] == "answer")
    }

    @Test
    func `PropertyID Tag is Observer.Property — type-system disambiguates`() {

        let id: Observer.Property.ID = .init(0)
        #expect(id.underlying == 0)
    }
}

extension Observer.Test.SubscriptionID {

    @Test
    func `SubscriptionID wraps UInt64 raw value`() {
        let id: Observer.Subscription.ID = .init(42)
        #expect(id.underlying == 42)
    }

    @Test
    func `SubscriptionID is Hashable`() {
        let a: Observer.Subscription.ID = .init(1)
        let b: Observer.Subscription.ID = .init(1)
        let c: Observer.Subscription.ID = .init(2)
        #expect(a == b)
        #expect(a != c)
        #expect(a.hashValue == b.hashValue)
    }

    @Test
    func `SubscriptionID is usable as Set / Dictionary key`() {
        let set: Set<Observer.Subscription.ID> = [.init(0), .init(1), .init(2), .init(0)]
        #expect(set.count == 3)

        let dict: [Observer.Subscription.ID: String] = [
            .init(0): "zero",
            .init(42): "answer",
        ]
        #expect(dict[.init(42)] == "answer")
    }

    @Test
    func `Registrar.subscribe vends typed Subscription.ID`() {
        let registrar = Observer.Registrar()
        let id: Observer.Subscription.ID = registrar.subscribe(to: [.init(0)])

        #expect(id.underlying >= 0)
        registrar.unsubscribe(id)
    }
}
