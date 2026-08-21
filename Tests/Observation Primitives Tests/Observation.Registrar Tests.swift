import Synchronization
import Tagged_Primitives
import Testing

@testable import Observation_Primitives

final class Box<T: Sendable>: @unchecked Sendable {
    private let _storage: Mutex<T>

    init(_ initial: T) { self._storage = Mutex(initial) }

    var value: T {
        _storage.withLock { $0 }
    }

    func mutate(_ body: (inout T) -> Void) {
        _storage.withLock { body(&$0) }
    }
}

extension Observation.Registrar {
    @Suite("Observation.Registrar")
    struct Test {
        @Suite struct Subscribe {}
        @Suite struct WillSet {}
        @Suite struct DidSet {}
        @Suite struct WithMutation {}
        @Suite struct Lifetime {}
        @Suite struct NoncopyableSubject {}
    }
}

extension Observation.Registrar.Test.Subscribe {

    @Test
    func `subscribe returns unique subscription IDs`() {
        let registrar = Observation.Registrar()
        let id1 = registrar.subscribe(to: [.init(0)])
        let id2 = registrar.subscribe(to: [.init(0)])
        let id3 = registrar.subscribe(to: [.init(1)])
        #expect(id1 != id2)
        #expect(id2 != id3)
        #expect(id1 != id3)
    }

    @Test
    func `subscribe accepts multiple properties`() {
        let registrar = Observation.Registrar()
        let firedFor = Box<Set<UInt32>>([])
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
    func `unsubscribe removes the observer`() {
        let registrar = Observation.Registrar()
        let fireCount = Box(0)
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

extension Observation.Registrar.Test.WillSet {

    @Test
    func `willSet fires registered observer for matching property`() {
        let registrar = Observation.Registrar()
        let fired = Box(false)
        let id = registrar.subscribe(
            to: [.init(0)],
            willSet: { _ in fired.mutate { $0 = true } }
        )
        registrar.willSet(.init(0))
        #expect(fired.value == true)
        registrar.unsubscribe(id)
    }

    @Test
    func `willSet does NOT fire for non-matching property`() {
        let registrar = Observation.Registrar()
        let fired = Box(false)
        let id = registrar.subscribe(
            to: [.init(0)],
            willSet: { _ in fired.mutate { $0 = true } }
        )
        registrar.willSet(.init(1))
        #expect(fired.value == false)
        registrar.unsubscribe(id)
    }

    @Test
    func `willSet fires before didSet for the same property`() {
        let registrar = Observation.Registrar()
        let order = Box<[String]>([])
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

extension Observation.Registrar.Test.DidSet {

    @Test
    func `didSet fires registered observer for matching property`() {
        let registrar = Observation.Registrar()
        let captured = Box<UInt32?>(nil)
        let id = registrar.subscribe(
            to: [.init(42)],
            didSet: { propertyID in captured.mutate { $0 = propertyID.underlying } }
        )
        registrar.didSet(.init(42))
        #expect(captured.value == 42)
        registrar.unsubscribe(id)
    }

    @Test
    func `didSet fires multiple observers for the same property`() {
        let registrar = Observation.Registrar()
        let aFired = Box(false)
        let bFired = Box(false)
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

extension Observation.Registrar.Test.WithMutation {

    @Test
    func `withMutation fires willSet then body then didSet`() {
        let registrar = Observation.Registrar()
        let order = Box<[String]>([])
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
    func `withMutation propagates errors and still fires didSet`() {
        let registrar = Observation.Registrar()
        struct TestError: Swift.Error {}
        let didSetFired = Box(false)
        let id = registrar.subscribe(
            to: [.init(0)],
            didSet: { _ in didSetFired.mutate { $0 = true } }
        )

        do throws(TestError) {
            try registrar.withMutation(of: .init(0)) { () throws(TestError) in
                throw TestError()
            }
            Issue.record("Expected error to propagate")
        } catch {

        }
        #expect(didSetFired.value == true)
        registrar.unsubscribe(id)
    }
}

extension Observation.Registrar.Test.Lifetime {

    @Test
    func `Registrar copies share the same Extent (CoW handle)`() {
        let r1 = Observation.Registrar()
        let r2 = r1
        let fired = Box(false)
        let id = r1.subscribe(
            to: [.init(0)],
            didSet: { _ in fired.mutate { $0 = true } }
        )

        r2.didSet(.init(0))
        #expect(fired.value == true)
        r1.unsubscribe(id)
    }
}

extension Observation.Registrar.Test.NoncopyableSubject.Counter {
    var raw: Int {
        _read {
            _$registrar.access(.init(0))
            yield _raw
        }
        _modify {
            _$registrar.willSet(.init(0))
            yield &_raw
            _$registrar.didSet(.init(0))
        }
    }
}

extension Observation.Registrar.Test.NoncopyableSubject {

    struct Counter: ~Copyable, Observable {
        let _$registrar: Observation.Registrar
        var _raw: Int

        init() {
            self._$registrar = Observation.Registrar()
            self._raw = 0
        }
    }

    @Test
    func `~Copyable Subject can conform to Observable`() {
        var counter = Counter()
        let fired = Box(false)
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
    func `~Copyable Subject increments through _modify accessor`() {
        var counter = Counter()
        let fireCount = Box(0)
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
