import Tagged
import Testing

@testable import Observer

extension Observer {
    @Suite
    struct `Observer markers accept subjects and identifiers preserve their values` {
        @Suite struct `Subjects can opt into observation` {}
        @Suite struct `Property identifiers distinguish observed fields` {}
        @Suite struct `Subscription identifiers select registrations` {}
    }
}

extension Observer.`Observer markers accept subjects and identifiers preserve their values`.`Subjects can opt into observation` {

    @Test
    func `Copyable subjects can adopt the observable marker`() {
        struct Counter: Observable {
            var raw: Int = 0
        }
        let c = Counter()
        #expect(c.raw == 0)
    }

    @Test
    func `Noncopyable subjects can adopt the observable marker`() {
        struct UniqueCounter: ~Copyable, Observable {
            var raw: Int = 0
        }
        let u = UniqueCounter()
        #expect(u.raw == 0)
    }

    @Test
    func `Both marker spellings accept the same subjects`() {

        struct Foo: Observer.`Protocol` {
            var x: Int = 0
        }
        struct Bar: Observable {
            var y: Int = 0
        }
        func accept<T: Observable>(_ value: T) -> T { value }
        let f = accept(Foo())
        let b = accept(Bar())
        #expect(f.x == b.y)
    }
}

extension Observer.`Observer markers accept subjects and identifiers preserve their values`.`Property identifiers distinguish observed fields` {

    @Test
    func `Property identifiers preserve their underlying values`() {
        let id: Observer.Property.ID = .init(42)
        #expect(id.underlying == 42)
    }

    @Test
    func `Equal property identifiers have equal hashes`() {
        let a: Observer.Property.ID = .init(1)
        let b: Observer.Property.ID = .init(1)
        let c: Observer.Property.ID = .init(2)
        #expect(a == b)
        #expect(a != c)
        #expect(a.hashValue == b.hashValue)
    }

    @Test
    func `Property identifiers can index sets and dictionaries`() {
        let set: Set<Observer.Property.ID> = [.init(0), .init(1), .init(2), .init(0)]
        #expect(set.count == 3)

        let dict: [Observer.Property.ID: String] = [
            .init(0): "zero",
            .init(42): "answer",
        ]
        #expect(dict[.init(42)] == "answer")
    }

}

extension Observer.`Observer markers accept subjects and identifiers preserve their values`.`Subscription identifiers select registrations` {

    @Test
    func `Subscription identifiers preserve their underlying values`() {
        let id: Observer.Subscription.ID = .init(42)
        #expect(id.underlying == 42)
    }

    @Test
    func `Equal subscription identifiers have equal hashes`() {
        let a: Observer.Subscription.ID = .init(1)
        let b: Observer.Subscription.ID = .init(1)
        let c: Observer.Subscription.ID = .init(2)
        #expect(a == b)
        #expect(a != c)
        #expect(a.hashValue == b.hashValue)
    }

    @Test
    func `Subscription identifiers can index sets and dictionaries`() {
        let set: Set<Observer.Subscription.ID> = [.init(0), .init(1), .init(2), .init(0)]
        #expect(set.count == 3)

        let dict: [Observer.Subscription.ID: String] = [
            .init(0): "zero",
            .init(42): "answer",
        ]
        #expect(dict[.init(42)] == "answer")
    }

}
