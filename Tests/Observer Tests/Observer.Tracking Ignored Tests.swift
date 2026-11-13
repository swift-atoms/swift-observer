#if Tracking
    import Testing

    @testable import Observer

    @Observable
    final class Ignoring {
        var count = 0
        @ObservationIgnored var cache = 0
        var name = "Ada"
        @ObservationIgnored let token = 7
    }

    enum `Observer.Tracking Ignored Tests` {}

    extension `Observer.Tracking Ignored Tests` {
        @Suite struct `An ignored member is not observed` {}
    }

    extension `Observer.Tracking Ignored Tests`.`An ignored member is not observed` {
        @Test
        func `a write to an ignored member does not reach a tracker that read it`() {
            let subject = Ignoring()
            let changed = `Observer.Tracking Tests`.Box(false)
            _ = Observer.Tracking.run({ subject.cache + subject.token }, onChange: { changed.withLock { $0 = true } })
            subject.cache = 1
            #expect(changed.withLock { $0 } == false)
            #expect(subject.cache == 1)
        }

        @Test
        func `the members after an ignored one are still tracked each on its own`() {
            let subject = Ignoring()
            let changed = `Observer.Tracking Tests`.Box(false)
            _ = Observer.Tracking.run({ subject.name }, onChange: { changed.withLock { $0 = true } })
            subject.count = 1
            subject.cache = 2
            #expect(changed.withLock { $0 } == false)
            subject.name = "Grace"
            #expect(changed.withLock { $0 })
        }
    }
#endif
