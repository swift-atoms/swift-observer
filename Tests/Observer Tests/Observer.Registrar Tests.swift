import Synchronization
import Tagged
import Testing

@testable import Observer

extension Observer.Registrar {
    @Suite
    struct `Registrars manage property subscriptions` {
        final class Box<T: Sendable>: Sendable {
            private let _storage: Mutex<T>

            init(_ initial: T) { self._storage = Mutex(initial) }

            var value: T {
                _storage.withLock { $0 }
            }

            func mutate(_ body: (inout T) -> Void) {
                _storage.withLock { body(&$0) }
            }
        }


        @Suite struct `Subscriptions can be added and removed` {}
        @Suite struct `Notifications precede mutation` {}
        @Suite struct `Notifications follow mutation` {}
        @Suite struct `Mutations preserve effects and results` {}
        @Suite struct `Copies share registrar identity` {}
        @Suite struct `Noncopyable subjects publish mutations` {}
    }
}

extension Observer.Registrar.`Registrars manage property subscriptions`.`Subscriptions can be added and removed` {

    @Test
    func `Subscribing returns distinct identifiers`() {
        let registrar = Observer.Registrar()
        let id1 = registrar.subscribe(to: [.init(0)])
        let id2 = registrar.subscribe(to: [.init(0)])
        let id3 = registrar.subscribe(to: [.init(1)])
        #expect(id1 != id2)
        #expect(id2 != id3)
        #expect(id1 != id3)
    }

    @Test
    func `One subscription can observe multiple properties`() {
        let registrar = Observer.Registrar()
        let firedFor = Observer.Registrar.`Registrars manage property subscriptions`.Box<Set<UInt32>>([])
        let id = registrar.subscribe(
            to: [.init(0), .init(1), .init(2)],
            willSet: { propertyID in
                firedFor.mutate { $0.insert(propertyID.underlying) }
            }
        )
        registrar.willSet(.init(0))
        registrar.willSet(.init(1))
        registrar.willSet(.init(2))
        #expect(firedFor.value == [0, 1, 2])
        registrar.unsubscribe(id)
    }

    @Test
    func `Unsubscribing removes the registration`() {
        let registrar = Observer.Registrar()
        let fireCount = Observer.Registrar.`Registrars manage property subscriptions`.Box(0)
        let id = registrar.subscribe(
            to: [.init(0)],
            didSet: { _ in fireCount.mutate { $0 += 1 } }
        )
        registrar.didSet(.init(0))
        #expect(fireCount.value == 1)
        registrar.unsubscribe(id)
        registrar.didSet(.init(0))
        #expect(fireCount.value == 1)
    }
}

extension Observer.Registrar.`Registrars manage property subscriptions`.`Notifications precede mutation` {

    @Test
    func `Matching properties receive notifications before mutation`() {
        let registrar = Observer.Registrar()
        let fired = Observer.Registrar.`Registrars manage property subscriptions`.Box(false)
        let id = registrar.subscribe(
            to: [.init(0)],
            willSet: { _ in fired.mutate { $0 = true } }
        )
        registrar.willSet(.init(0))
        #expect(fired.value == true)
        registrar.unsubscribe(id)
    }

    @Test
    func `Unrelated properties do not receive notifications`() {
        let registrar = Observer.Registrar()
        let fired = Observer.Registrar.`Registrars manage property subscriptions`.Box(false)
        let id = registrar.subscribe(
            to: [.init(0)],
            willSet: { _ in fired.mutate { $0 = true } }
        )
        registrar.willSet(.init(1))
        #expect(fired.value == false)
        registrar.unsubscribe(id)
    }

    @Test
    func `Mutation notifications preserve their phase order`() {
        let registrar = Observer.Registrar()
        let order = Observer.Registrar.`Registrars manage property subscriptions`.Box<[String]>([])
        let id = registrar.subscribe(
            to: [.init(0)],
            willSet: { _ in order.mutate { $0.append("will") } },
            didSet: { _ in order.mutate { $0.append("did") } }
        )
        registrar.willSet(.init(0))
        registrar.didSet(.init(0))
        #expect(order.value == ["will", "did"])
        registrar.unsubscribe(id)
    }
}

extension Observer.Registrar.`Registrars manage property subscriptions`.`Notifications follow mutation` {

    @Test
    func `Matching properties receive notifications after mutation`() {
        let registrar = Observer.Registrar()
        let captured = Observer.Registrar.`Registrars manage property subscriptions`.Box<UInt32?>(nil)
        let id = registrar.subscribe(
            to: [.init(42)],
            didSet: { propertyID in captured.mutate { $0 = propertyID.underlying } }
        )
        registrar.didSet(.init(42))
        #expect(captured.value == 42)
        registrar.unsubscribe(id)
    }

    @Test
    func `Every matching subscriber receives the notification`() {
        let registrar = Observer.Registrar()
        let aFired = Observer.Registrar.`Registrars manage property subscriptions`.Box(false)
        let bFired = Observer.Registrar.`Registrars manage property subscriptions`.Box(false)
        let idA = registrar.subscribe(
            to: [.init(0)],
            didSet: { _ in aFired.mutate { $0 = true } }
        )
        let idB = registrar.subscribe(
            to: [.init(0)],
            didSet: { _ in bFired.mutate { $0 = true } }
        )
        registrar.didSet(.init(0))
        #expect(aFired.value == true)
        #expect(bFired.value == true)
        registrar.unsubscribe(idA)
        registrar.unsubscribe(idB)
    }
}

extension Observer.Registrar.`Registrars manage property subscriptions`.`Mutations preserve effects and results` {

    @Test
    func `Mutation bodies run between the notification phases`() {
        let registrar = Observer.Registrar()
        let order = Observer.Registrar.`Registrars manage property subscriptions`.Box<[String]>([])
        let id = registrar.subscribe(
            to: [.init(0)],
            willSet: { _ in order.mutate { $0.append("will") } },
            didSet: { _ in order.mutate { $0.append("did") } }
        )
        let result = registrar.withMutation(of: .init(0)) {
            order.mutate { $0.append("body") }
            return 42
        }
        #expect(result == 42)
        #expect(order.value == ["will", "body", "did"])
        registrar.unsubscribe(id)
    }

    @Test
    func `Mutation failures preserve their type and finish notifications`() {
        let registrar = Observer.Registrar()
        enum Failure: Swift.Error, Equatable { case stopped }
        let order = Observer.Registrar.`Registrars manage property subscriptions`.Box<[String]>([])
        let id = registrar.subscribe(
            to: [.init(0)],
            willSet: { _ in order.mutate { $0.append("will") } },
            didSet: { _ in order.mutate { $0.append("did") } }
        )

        do throws(Failure) {
            try registrar.withMutation(of: .init(0)) { () throws(Failure) in
                order.mutate { $0.append("body") }
                throw .stopped
            }
            Issue.record("Expected the mutation failure")
        } catch {
            #expect(error == .stopped)
        }
        #expect(order.value == ["will", "body", "did"])
        registrar.unsubscribe(id)
    }
}

extension Observer.Registrar.`Registrars manage property subscriptions`.`Copies share registrar identity` {

    @Test
    func `Registrar copies share subscriptions and identity`() {
        let r1 = Observer.Registrar()
        let r2 = r1
        #expect(r1.id == r2.id)
        let fired = Observer.Registrar.`Registrars manage property subscriptions`.Box(false)
        let id = r1.subscribe(
            to: [.init(0)],
            didSet: { _ in fired.mutate { $0 = true } }
        )

        r2.didSet(.init(0))
        #expect(fired.value == true)
        r2.unsubscribe(id)
        fired.mutate { $0 = false }
        r1.didSet(.init(0))
        #expect(!fired.value)
    }
}

extension Observer.Registrar.`Registrars manage property subscriptions`.`Noncopyable subjects publish mutations`.Counter {
    var raw: Int {
        _read {
            yield _raw
        }
        _modify {
            _$registrar.willSet(.init(0))
            yield &_raw
            _$registrar.didSet(.init(0))
        }
    }
}

extension Observer.Registrar.`Registrars manage property subscriptions`.`Noncopyable subjects publish mutations` {

    struct Counter: ~Copyable, Observable {
        let _$registrar: Observer.Registrar
        var _raw: Int

        init() {
            self._$registrar = Observer.Registrar()
            self._raw = 0
        }
    }

    @Test
    func `Noncopyable subjects can publish observed assignments`() {
        var counter = Observer.Registrar.`Registrars manage property subscriptions`.`Noncopyable subjects publish mutations`.Counter()
        let fired = Observer.Registrar.`Registrars manage property subscriptions`.Box(false)
        let id = counter._$registrar.subscribe(
            to: [.init(0)],
            didSet: { _ in fired.mutate { $0 = true } }
        )

        counter.raw = 42
        #expect(counter.raw == 42)
        #expect(fired.value == true)

        counter._$registrar.unsubscribe(id)
    }

    @Test
    func `Noncopyable subjects publish changes through mutable accessors`() {
        var counter = Observer.Registrar.`Registrars manage property subscriptions`.`Noncopyable subjects publish mutations`.Counter()
        let fireCount = Observer.Registrar.`Registrars manage property subscriptions`.Box(0)
        let id = counter._$registrar.subscribe(
            to: [.init(0)],
            didSet: { _ in fireCount.mutate { $0 += 1 } }
        )

        counter.raw += 1
        counter.raw += 1
        counter.raw += 1
        #expect(counter.raw == 3)
        #expect(fireCount.value == 3)

        counter._$registrar.unsubscribe(id)
    }
}
