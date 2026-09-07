import Synchronization
import Testing

@testable import Observer

@Suite struct `Registrar callbacks permit reentrancy` {
    final class State<Value: Sendable>: Sendable {
        let storage: Mutex<Value>

        init(_ value: Value) { storage = Mutex(value) }

        var value: Value { storage.withLock { $0 } }

        func update(_ body: (inout Value) -> Void) {
            storage.withLock { body(&$0) }
        }
    }

    final class Capture: Sendable {
        let registrar: Observer.Registrar
        let releases: `Registrar callbacks permit reentrancy`.State<Int>

        init(_ registrar: Observer.Registrar, releases: `Registrar callbacks permit reentrancy`.State<Int>) {
            self.registrar = registrar
            self.releases = releases
        }

        deinit {
            let id = registrar.subscribe(to: [.init(1)])
            registrar.unsubscribe(id)
            releases.update { $0 += 1 }
        }
    }

    static func installCapture(
        on registrar: Observer.Registrar,
        releases: `Registrar callbacks permit reentrancy`.State<Int>
    ) -> Observer.Subscription.ID {
        let capture = `Registrar callbacks permit reentrancy`.Capture(registrar, releases: releases)
        return registrar.subscribe(to: [.init(0)], didSet: { [capture] _ in
            withExtendedLifetime(capture) {}
        })
    }

    @Test func `Unsubscribing releases callback captures after unlocking`() async {
        await #expect(processExitsWith: .success) {
            let watchdog = Task.detached {
                try await Task.sleep(for: .seconds(5))
                preconditionFailure("Registrar destructor reentrancy timed out")
            }
            defer { watchdog.cancel() }

            let registrar = Observer.Registrar()
            let releases = `Registrar callbacks permit reentrancy`.State(0)
            let id = `Registrar callbacks permit reentrancy`.installCapture(on: registrar, releases: releases)

            registrar.unsubscribe(id)

            precondition(releases.value == 1)
        }
    }

    @Test func `Unsubscribing during dispatch preserves the captured callback snapshot`() async {
        await #expect(processExitsWith: .success) {
            let watchdog = Task.detached {
                try await Task.sleep(for: .seconds(5))
                preconditionFailure("Registrar callback reentrancy timed out")
            }
            defer { watchdog.cancel() }

            let registrar = Observer.Registrar()
            let ids = `Registrar callbacks permit reentrancy`.State<[Observer.Subscription.ID]>([])
            let calls = `Registrar callbacks permit reentrancy`.State<[Int]>([])
            for index in 0..<2 {
                let id = registrar.subscribe(to: [.init(0)], didSet: { _ in
                    for id in ids.value { registrar.unsubscribe(id) }
                    calls.update { $0.append(index) }
                })
                ids.update { $0.append(id) }
            }

            registrar.didSet(.init(0))
            precondition(calls.value.sorted() == [0, 1])
            registrar.didSet(.init(0))
            precondition(calls.value.count == 2)
        }
    }

    @Test func `Subscriptions added during dispatch begin with the next snapshot`() async {
        await #expect(processExitsWith: .success) {
            let watchdog = Task.detached {
                try await Task.sleep(for: .seconds(5))
                preconditionFailure("Registrar subscription reentrancy timed out")
            }
            defer { watchdog.cancel() }

            let registrar = Observer.Registrar()
            let added = `Registrar callbacks permit reentrancy`.State<Observer.Subscription.ID?>(nil)
            let calls = `Registrar callbacks permit reentrancy`.State(0)
            let first = registrar.subscribe(to: [.init(0)], didSet: { _ in
                if added.value == nil {
                    let id = registrar.subscribe(to: [.init(0)], didSet: { _ in
                        calls.update { $0 += 1 }
                    })
                    added.update { $0 = id }
                }
            })

            registrar.didSet(.init(0))
            precondition(calls.value == 0)
            registrar.didSet(.init(0))
            precondition(calls.value == 1)
            registrar.unsubscribe(first)
            if let id = added.value { registrar.unsubscribe(id) }
        }
    }

    @Test func `Notification phases capture subscriptions independently`() async {
        await #expect(processExitsWith: .success) {
            let watchdog = Task.detached {
                try await Task.sleep(for: .seconds(5))
                preconditionFailure("Registrar phase reentrancy timed out")
            }
            defer { watchdog.cancel() }

            let registrar = Observer.Registrar()
            let original = `Registrar callbacks permit reentrancy`.State<Observer.Subscription.ID?>(nil)
            let replacement = `Registrar callbacks permit reentrancy`.State<Observer.Subscription.ID?>(nil)
            let events = `Registrar callbacks permit reentrancy`.State<[String]>([])
            let id = registrar.subscribe(
                to: [.init(0)],
                willSet: { _ in
                    events.update { $0.append("will") }
                    registrar.unsubscribe(original.value!)
                    let added = registrar.subscribe(to: [.init(0)], didSet: { _ in
                        events.update { $0.append("replacement did") }
                    })
                    replacement.update { $0 = added }
                },
                didSet: { _ in events.update { $0.append("original did") } }
            )
            original.update { $0 = id }

            registrar.withMutation(of: .init(0)) {
                events.update { $0.append("body") }
            }

            precondition(events.value == ["will", "body", "replacement did"])
            if let id = replacement.value { registrar.unsubscribe(id) }
        }
    }

    struct Result: ~Copyable { let value: Int }

    @Test func `Mutation bodies can reenter the registrar and return noncopyable results`() async {
        await #expect(processExitsWith: .success) {
            let watchdog = Task.detached {
                try await Task.sleep(for: .seconds(5))
                preconditionFailure("Registrar mutation reentrancy timed out")
            }
            defer { watchdog.cancel() }

            let registrar = Observer.Registrar()
            let events = `Registrar callbacks permit reentrancy`.State<[String]>([])
            let id = registrar.subscribe(
                to: [.init(0)],
                willSet: { _ in events.update { $0.append("will") } },
                didSet: { _ in events.update { $0.append("did") } }
            )

            let result = registrar.withMutation(of: .init(0)) {
                let transient = registrar.subscribe(to: [.init(1)])
                registrar.unsubscribe(transient)
                events.update { $0.append("body") }
                return `Registrar callbacks permit reentrancy`.Result(value: 42)
            }

            precondition(result.value == 42)
            precondition(events.value == ["will", "body", "did"])
            registrar.unsubscribe(id)
        }
    }
}
