#if Tracking
    import Testing

    @testable import Observer

    enum `Observer.Tracking Lifetime Tests` {}

    extension `Observer.Tracking Lifetime Tests` {
        @Suite
        struct Test {}

        final class Sentinel: Sendable {}
    }

    extension `Observer.Tracking Lifetime Tests`.Test {
        @Suite struct `Release` {}
    }

    extension `Observer.Tracking Lifetime Tests`.Test.`Release` {

        @Test
        func `a registrar dropped without a change releases what its tracking captured`() {
            weak var released: `Observer.Tracking Lifetime Tests`.Sentinel?
            do {
                let sentinel = `Observer.Tracking Lifetime Tests`.Sentinel()
                released = sentinel
                let registrar = Observer.Registrar()
                Observer.Tracking.run {
                    Observer.Tracking.access(registrar, .init(0))
                } onChange: {
                    withExtendedLifetime(sentinel) {}
                }
            }
            #expect(released == nil)
        }

        @Test
        func `a registrar dropped without a change does not call onChange`() {
            let fired = `Observer.Tracking Tests`.Box(0)
            do {
                let registrar = Observer.Registrar()
                Observer.Tracking.run {
                    Observer.Tracking.access(registrar, .init(0))
                } onChange: {
                    fired.withLock { $0 += 1 }
                }
            }
            #expect(fired.withLock { $0 } == 0)
        }

        @Test
        func `a tracking of two registrars is released when the one that changes fires`() {
            weak var released: `Observer.Tracking Lifetime Tests`.Sentinel?
            let changing = Observer.Registrar()
            let quiet = Observer.Registrar()
            do {
                let sentinel = `Observer.Tracking Lifetime Tests`.Sentinel()
                released = sentinel
                Observer.Tracking.run {
                    Observer.Tracking.access(changing, .init(0))
                    Observer.Tracking.access(quiet, .init(0))
                } onChange: {
                    withExtendedLifetime(sentinel) {}
                }
            }
            changing.withMutation(of: .init(0)) {}
            #expect(released == nil)
        }
    }
#endif
