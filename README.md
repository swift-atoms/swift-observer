# swift-observer

Use this package when you hand-write an observable subject, of any kind, including `~Copyable` and `~Escapable` ones, and need a thread-safe registry that delivers will-set and did-set notifications per property to subscribers. Start from `Observer.Registrar`: the subject stores one, numbers its own fields with `Observer.Property.ID`, and brackets each mutation with `willSet`/`didSet` or `withMutation`. Subscribers get back an `Observer.Subscription.ID`. Conformance to `Observer.Protocol` (also spelled `Observable`) is a marker with no requirements. If you want a macro that generates this wiring, plus observation tracking, use the swift-observations package, which is built on this one.

## Laws

- A notification reaches only subscriptions whose property set contains the notified `Observer.Property.ID`. The order in which those subscriptions are called is unspecified.
- `withMutation` calls `willSet`, then the body, then `didSet`. `didSet` still runs when the body throws, and the body's error and result pass through unchanged.
- Each notification phase takes a snapshot of the matching callbacks under the lock, then calls them after unlocking. So callbacks and mutation bodies may re-enter the registrar. A subscription removed during dispatch is still called for the snapshot in progress. A subscription added during dispatch starts with the next notification. The `willSet` and `didSet` phases of one mutation take separate snapshots.
- `unsubscribe` releases the callbacks' captured values after unlocking, so a deinitialiser that runs then may call back into the registrar. Unsubscribing an unknown or retired identifier does nothing.
- Subscriptions are not tied to any lifetime. A subscription stays until it is passed to `unsubscribe`.
- Within one registrar, subscription identifiers are issued in increasing order from 0 and are never reused. Once `UInt64.max` has been issued, the next `subscribe` traps rather than reuse an identifier. Identifiers only have meaning within the registrar that issued them, so two fresh registrars issue the same values.
- Copies of an `Observer.Registrar` share one registry, so they share subscriptions and the same `id`. Separately created registrars have different `id`s.
