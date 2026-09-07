import Synchronization
import Testing

@testable import Observer

@Suite struct `Subscription identities are never reused` {
    @Test func `Retired identifiers never cancel later subscriptions`() {
        let registrar = Observer.Registrar()
        let calls = `Registrar callbacks permit reentrancy`.State(0)
        let retired = registrar.subscribe(to: [.init(0)])
        registrar.unsubscribe(retired)
        let active = registrar.subscribe(to: [.init(0)], didSet: { _ in
            calls.update { $0 += 1 }
        })

        #expect(retired != active)
        registrar.unsubscribe(retired)
        registrar.unsubscribe(.init(UInt64.max))
        registrar.didSet(.init(0))
        #expect(calls.value == 1)
        registrar.unsubscribe(active)
        #expect(registrar._extent.value.withLock { $0.observers.isEmpty && $0.lookups.isEmpty })
    }

    @Test func `Fresh registrars isolate identical property and subscription numbers`() {
        let first = Observer.Registrar()
        let second = Observer.Registrar()
        let calls = `Registrar callbacks permit reentrancy`.State<[String]>([])
        let firstID = first.subscribe(to: [.init(0)], didSet: { _ in
            calls.update { $0.append("first") }
        })
        let secondID = second.subscribe(to: [.init(0)], didSet: { _ in
            calls.update { $0.append("second") }
        })

        #expect(first.id != second.id)
        #expect(firstID == secondID)
        first.didSet(.init(0))
        #expect(calls.value == ["first"])
        first.unsubscribe(firstID)
        second.didSet(.init(0))
        #expect(calls.value == ["first", "second"])
        second.unsubscribe(secondID)
    }

    @Test func `The final identifiers preserve existing registrations and property indexes`() {
        let registrar = Observer.Registrar()
        let calls = `Registrar callbacks permit reentrancy`.State<[UInt32]>([])
        let first = registrar.subscribe(to: [.init(0)], didSet: { property in
            calls.update { $0.append(property.underlying) }
        })
        registrar._extent.value.withLock { $0.nextSubscriptionID = UInt64.max - 1 }

        let penultimate = registrar.subscribe(to: [.init(1)])
        let last = registrar.subscribe(to: [.init(2)], didSet: { property in
            calls.update { $0.append(property.underlying) }
        })

        #expect(first.underlying == 0)
        #expect(penultimate.underlying == UInt64.max - 1)
        #expect(last.underlying == UInt64.max)
        registrar.didSet(.init(0))
        registrar.didSet(.init(2))
        #expect(calls.value == [0, 2])
        registrar.unsubscribe(first)
        registrar.unsubscribe(penultimate)
        registrar.unsubscribe(last)
        #expect(registrar._extent.value.withLock { $0.observers.isEmpty && $0.lookups.isEmpty })
    }

    @Test func `Exhaustion fails instead of recycling a retired subscription identifier`() async {
        await #expect(processExitsWith: .failure) {
            let registrar = Observer.Registrar()
            let first = registrar.subscribe(to: [.init(0)])
            registrar.unsubscribe(first)
            registrar._extent.value.withLock { $0.nextSubscriptionID = UInt64.max }
            let last = registrar.subscribe(to: [.init(1)])
            precondition(last.underlying == UInt64.max)
            registrar.unsubscribe(last)
            _ = registrar.subscribe(to: [.init(2)])
        }
    }
}
