#if Tracking
    import Testing

    @testable import Observer

    enum `Observer.Tracking Nesting Tests` {}

    extension `Observer.Tracking Nesting Tests` {
        @Suite
        struct Test {}
    }

    extension `Observer.Tracking Nesting Tests`.Test {

        @Test
        func `an enclosing tracking is told of a change to what a nested tracking read`() {
            var counter = Counter()
            let outer = `Observer.Tracking Tests`.Box(0)
            let inner = `Observer.Tracking Tests`.Box(0)
            Observer.Tracking.run {
                Observer.Tracking.run {
                    _ = counter.x
                } onChange: {
                    inner.withLock { $0 += 1 }
                }
            } onChange: {
                outer.withLock { $0 += 1 }
            }
            counter.x = 1
            #expect(inner.withLock { $0 } == 1)
            #expect(outer.withLock { $0 } == 1)
        }

        @Test
        func `a nested tracking is not told of what only the enclosing tracking read`() {
            var counter = Counter()
            let outer = `Observer.Tracking Tests`.Box(0)
            let inner = `Observer.Tracking Tests`.Box(0)
            Observer.Tracking.run {
                _ = counter.y
                Observer.Tracking.run {
                    _ = counter.x
                } onChange: {
                    inner.withLock { $0 += 1 }
                }
            } onChange: {
                outer.withLock { $0 += 1 }
            }
            counter.y = 1
            #expect(inner.withLock { $0 } == 0)
            #expect(outer.withLock { $0 } == 1)
        }
    }
#endif
