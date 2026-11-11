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
            guard let frame = currentFrame() else { return }
            frame.record(registrar, propertyID)
        }
    }

    extension Observer.Tracking {

        @TaskLocal static var frame: Frame?

        static func currentFrame() -> Frame? {
            frame
        }
    }

    public func withObservationTracking<R>(
        _ apply: () -> R,
        onChange: @escaping @Sendable () -> Void
    ) -> R {
        let frame = Observer.Tracking.Frame()
        let result = Observer.Tracking.$frame.withValue(frame) { apply() }

        let accesses = frame.accesses
        guard !accesses.isEmpty else { return result }

        Observer.Tracking._installOneShot(accesses: accesses, onChange: onChange)

        return result
    }

    extension Observer.Tracking {

        @discardableResult
        static func _installOneShot(
            accesses: Frame.Accesses,
            onChange: @escaping @Sendable () -> Void
        ) -> Ownership.Latch<@Sendable () -> Void> {

            let pending = Pending()

            let cleanup: @Sendable () -> Void = {
                for (registrar, id) in pending.subscriptions {
                    registrar.unsubscribe(id)
                }
                onChange()
            }

            let latch = Ownership.Latch<@Sendable () -> Void>(cleanup)

            for (_, value) in accesses {
                let registrar = value.registrar
                let properties = value.properties
                let id = registrar.subscribe(
                    to: properties,
                    didSet: { @Sendable [latch] _ in
                        latch.take()?()
                    }
                )
                pending.append(registrar, id)
            }

            return latch
        }
    }
#endif
