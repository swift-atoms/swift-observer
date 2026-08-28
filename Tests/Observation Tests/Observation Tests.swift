import Tagged
import Testing

@testable import Observation

extension Observation {
    @Suite("Observation")
    struct Test {
        @Suite struct ProtocolConformance {}
        @Suite struct PropertyID {}
        @Suite struct SubscriptionID {}
    }
}

extension Observation.Test.ProtocolConformance {

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
    func `Observable typealias resolves to Observation dot Protocol`() {

        struct Foo: Observation.`Protocol` {
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

extension Observation.Test.PropertyID {

    @Test
    func `PropertyID wraps UInt32 raw value`() {
        let id: Observation.Property.ID = .init(42)
        #expect(id.underlying == 42)
    }

    @Test
    func `PropertyID is Hashable`() {
        let a: Observation.Property.ID = .init(1)
        let b: Observation.Property.ID = .init(1)
        let c: Observation.Property.ID = .init(2)
        #expect(a == b)
        #expect(a != c)
        #expect(a.hashValue == b.hashValue)
    }

    @Test
    func `PropertyID is usable as Set / Dictionary key`() {
        let set: Set<Observation.Property.ID> = [.init(0), .init(1), .init(2), .init(0)]
        #expect(set.count == 3)

        let dict: [Observation.Property.ID: String] = [
            .init(0): "zero",
            .init(42): "answer",
        ]
        #expect(dict[.init(42)] == "answer")
    }

    @Test
    func `PropertyID Tag is Observation.Property — type-system disambiguates`() {

        let id: Observation.Property.ID = .init(0)
        #expect(id.underlying == 0)
    }
}

extension Observation.Test.SubscriptionID {

    @Test
    func `SubscriptionID wraps UInt64 raw value`() {
        let id: Observation.Subscription.ID = .init(42)
        #expect(id.underlying == 42)
    }

    @Test
    func `SubscriptionID is Hashable`() {
        let a: Observation.Subscription.ID = .init(1)
        let b: Observation.Subscription.ID = .init(1)
        let c: Observation.Subscription.ID = .init(2)
        #expect(a == b)
        #expect(a != c)
        #expect(a.hashValue == b.hashValue)
    }

    @Test
    func `SubscriptionID is usable as Set / Dictionary key`() {
        let set: Set<Observation.Subscription.ID> = [.init(0), .init(1), .init(2), .init(0)]
        #expect(set.count == 3)

        let dict: [Observation.Subscription.ID: String] = [
            .init(0): "zero",
            .init(42): "answer",
        ]
        #expect(dict[.init(42)] == "answer")
    }

    @Test
    func `Registrar.subscribe vends typed Subscription.ID`() {
        let registrar = Observation.Registrar()
        let id: Observation.Subscription.ID = registrar.subscribe(to: [.init(0)])

        #expect(id.underlying >= 0)
        registrar.unsubscribe(id)
    }
}
