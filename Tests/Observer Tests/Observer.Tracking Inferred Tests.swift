#if Tracking
    import Testing

    @testable import Observer

    @Observable
    final class Inferred {
        var count = 0
        var name = "Ada"
    }

    enum `Observer.Tracking Inferred Tests` {}

    extension `Observer.Tracking Inferred Tests` {
        @Suite struct `Properties without a type annotation are tracked` {}
    }

    extension `Observer.Tracking Inferred Tests`.`Properties without a type annotation are tracked` {
        @Test
        func `a change to an inferred property reaches the tracker`() {
            let subject = Inferred()
            let changed = `Observer.Tracking Tests`.Box(false)
            _ = Observer.Tracking.run({ subject.count }, onChange: { changed.withLock { $0 = true } })
            subject.name = "Grace"
            #expect(changed.withLock { $0 } == false)
            subject.count = 1
            #expect(changed.withLock { $0 })
            #expect(subject.count == 1)
            #expect(subject.name == "Grace")
        }
    }
#endif
