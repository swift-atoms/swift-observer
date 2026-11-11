#if Tracking
    import Synchronization
    import Testing

    @testable import Observer

    @Observable
    struct Counter {
        var x: Int = 0
        var y: Int = 0
    }

    enum `Observer.Tracking Tests` {}

    extension `Observer.Tracking Tests` {
        @Suite
        struct Test {
        }
    }

    extension `Observer.Tracking Tests` {
        final class Box<Value: Sendable>: Sendable {
            private let state: Mutex<Value>

            init(_ value: Value) {
                self.state = Mutex(value)
            }

            func withLock<Result>(_ body: (inout Value) -> Result) -> Result {
                state.withLock { body(&$0) }
            }
        }
    }

    extension `Observer.Tracking Tests`.Test {
        @Suite struct `Context Capture` {}

        @Suite struct `With Observer Tracking` {}

        @Suite struct `Token` {}
    }

    extension `Observer.Tracking Tests`.Test.`Context Capture` {

        @Test
        func `access outside withObservationTracking is a no-op`() {

            let counter = Counter()
            Observer.Tracking.access(counter._$registrar, .init(0))

        }

        @Test
        func `currentFrame is nil outside withObservationTracking`() {
            #expect(Observer.Tracking.currentFrame() == nil)
        }
    }

    extension `Observer.Tracking Tests`.Test.`With Observer Tracking` {

        @Test
        func `onChange fires when a tracked property mutates`() {
            var counter = Counter()
            let fired = `Observer.Tracking Tests`.Box(false)

            let value = withObservationTracking {
                counter.x
            } onChange: {
                fired.withLock { $0 = true }
            }
            #expect(value == 0)
            #expect(fired.withLock { $0 } == false)

            counter.x = 1
            #expect(fired.withLock { $0 } == true)
        }

        @Test
        func `onChange does NOT fire for untracked property mutation`() {
            var counter = Counter()
            let fired = `Observer.Tracking Tests`.Box(false)

            _ = withObservationTracking {
                counter.x
            } onChange: {
                fired.withLock { $0 = true }
            }

            counter.y = 1
            #expect(fired.withLock { $0 } == false)
        }

        @Test
        func `onChange fires once even with multiple tracked mutations`() {
            var counter = Counter()
            let fireCount = `Observer.Tracking Tests`.Box(0)

            withObservationTracking {
                _ = counter.x
                _ = counter.y
            } onChange: {
                fireCount.withLock { $0 += 1 }
            }

            counter.x = 1
            counter.y = 2
            counter.x = 3
            #expect(fireCount.withLock { $0 } == 1)
        }

        @Test
        func `repeated reads of same property dedupe to one subscription`() {
            var counter = Counter()
            let fireCount = `Observer.Tracking Tests`.Box(0)

            withObservationTracking {
                _ = counter.x
                _ = counter.x
                _ = counter.x
            } onChange: {
                fireCount.withLock { $0 += 1 }
            }

            counter.x = 99
            #expect(fireCount.withLock { $0 } == 1)
        }

        @Test
        func `body return value is propagated`() {
            var counter = Counter()
            counter.x = 42

            let result = withObservationTracking {
                counter.x * 2
            } onChange: {

            }
            #expect(result == 84)
        }

        @Test
        func `nested withObservationTracking — only inner records`() {
            var counter = Counter()
            let outerFired = `Observer.Tracking Tests`.Box(false)
            let innerFired = `Observer.Tracking Tests`.Box(false)

            _ = withObservationTracking {

                return withObservationTracking {
                    counter.x
                } onChange: {
                    innerFired.withLock { $0 = true }
                }
            } onChange: {
                outerFired.withLock { $0 = true }
            }

            counter.x = 1
            #expect(innerFired.withLock { $0 } == true)
            #expect(outerFired.withLock { $0 } == false)
        }

        @Test
        func `multiple registrars in one body`() {
            let a = Counter()
            var b = Counter()
            let fired = `Observer.Tracking Tests`.Box(false)

            withObservationTracking {
                _ = a.x
                _ = b.y
            } onChange: {
                fired.withLock { $0 = true }
            }

            b.y = 1
            #expect(fired.withLock { $0 } == true)
        }
    }

    extension `Observer.Tracking Tests`.Test.Token {

        @Test
        func `Token unsubscribes on deinit`() {
            let registrar = Observer.Registrar()
            let fireCount = `Observer.Tracking Tests`.Box(0)

            do {
                let id = registrar.subscribe(
                    to: [.init(0)],
                    didSet: { _ in fireCount.withLock { $0 += 1 } }
                )
                _ = Observer.Subscription.Token(registrar, id)
            }

            registrar.didSet(.init(0))
            #expect(fireCount.withLock { $0 } == 0)
        }

        @Test
        func `Token detach disarms the deinit`() {
            let registrar = Observer.Registrar()
            let fireCount = `Observer.Tracking Tests`.Box(0)

            let detached: (Observer.Registrar, Observer.Subscription.ID)?
            do {
                let id = registrar.subscribe(
                    to: [.init(0)],
                    didSet: { _ in fireCount.withLock { $0 += 1 } }
                )
                var token = Observer.Subscription.Token(registrar, id)
                detached = token.detach()
            }

            registrar.didSet(.init(0))
            #expect(fireCount.withLock { $0 } == 1)

            if let (r, id) = detached { r.unsubscribe(id) }
        }

        @Test
        func `Token detach twice returns nil the second time`() {
            let registrar = Observer.Registrar()
            let id = registrar.subscribe(to: [.init(0)])
            var token = Observer.Subscription.Token(registrar, id)

            let first = token.detach()
            let second = token.detach()
            #expect(first != nil)
            #expect(second == nil)

            if let (r, id) = first { r.unsubscribe(id) }
        }
    }
#endif
