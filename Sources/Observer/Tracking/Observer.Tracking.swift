#if Tracking
    import _Concurrency
    internal import Synchronization

    extension Observer {

        public enum Tracking {}
    }

    extension Observer.Tracking {

        public static func access(
            _ registrar: Observer.Registrar,
            _ propertyID: Observer.Property.ID
        ) {
            guard let frame else { return }
            frame.record(registrar, propertyID)
        }
    }

    extension Observer.Tracking {

        @TaskLocal static var frame: Frame?
    }

    extension Observer.Tracking {

        public static func run<R>(
            _ apply: () -> R,
            onChange: @escaping @Sendable () -> Void
        ) -> R {
            let frame = Frame()
            let result = $frame.withValue(frame) { apply() }

            let accesses = frame.accesses
            guard !accesses.isEmpty else { return result }

            _installOneShot(accesses: accesses, onChange: onChange)

            return result
        }
    }

    extension Observer.Tracking {

        @discardableResult
        static func _installOneShot(
            accesses: Frame.Accesses,
            onChange: @escaping @Sendable () -> Void
        ) -> Ownership.Latch<@Sendable () -> Void> {

            let pending = Pending()

            let cleanup: @Sendable () -> Void = {
                for (extent, id) in pending.subscriptions {
                    extent.unsubscribe(id)
                }
                onChange()
            }

            let latch = Ownership.Latch<@Sendable () -> Void>(cleanup)

            for (_, value) in accesses {
                let extent = value.extent
                let properties = value.properties
                let id = extent.subscribe(
                    to: properties,
                    didSet: { @Sendable [latch] _ in
                        latch.take()?()
                    }
                )
                pending.append(extent, id)
            }

            return latch
        }
    }
#endif
