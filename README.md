# swift-observer

Use this package when you hand-write an observable subject, of any kind, including `~Copyable` and `~Escapable` ones, and need a thread-safe registry that delivers will-set and did-set notifications per property to subscribers. Start from `Observer.Registrar`: the subject stores one, numbers its own fields with `Observer.Property.ID`, and brackets each mutation with `willSet`/`didSet` or `withMutation`. Subscribers get back an `Observer.Subscription.ID`. Conformance to `Observer.Protocol` (also spelled `Observable`) is a marker with no requirements. With the `Tracking` trait, the `@Observable` macro generates this wiring, and `Observer.Tracking.run(_:onChange:)` tells you once when anything read inside a closure changes.

## Laws

- A notification reaches only subscriptions whose property set contains the notified `Observer.Property.ID`. The order in which those subscriptions are called is unspecified.
- `withMutation` calls `willSet`, then the body, then `didSet`. `didSet` still runs when the body throws, and the body's error and result pass through unchanged.
- Each notification phase takes a snapshot of the matching callbacks under the lock, then calls them after unlocking. So callbacks and mutation bodies may re-enter the registrar. A subscription removed during dispatch is still called for the snapshot in progress. A subscription added during dispatch starts with the next notification. The `willSet` and `didSet` phases of one mutation take separate snapshots.
- `unsubscribe` releases the callbacks' captured values after unlocking, so a deinitialiser that runs then may call back into the registrar. Unsubscribing an unknown or retired identifier does nothing.
- A subscription stays until it is passed to `unsubscribe` or until the last copy of its registrar goes away; then its callbacks and what they captured are released, without being called.
- Within one registrar, subscription identifiers are issued in increasing order from 0 and are never reused. Once `UInt64.max` has been issued, the next `subscribe` traps rather than reuse an identifier. Identifiers only have meaning within the registrar that issued them, so two fresh registrars issue the same values.
- Copies of an `Observer.Registrar` share one registry, so they share subscriptions and the same `id`. Separately created registrars have different `id`s.
- With the `Tracking` trait, `Observer.Tracking.run` records every property read through `Observer.Tracking.access` while its closure runs, and calls `onChange` once, on the first did-set of any of them; its subscriptions then end. A tracking keeps no registrar alive, so a registrar it read can go away without a change, and then `onChange` is never called.
- A tracking nested inside another records into both: the enclosing tracking is also told of a change to what the nested one read. The nested one is not told of what only the enclosing one read.
