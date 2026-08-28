# Observation

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Observation primitives for Swift — a typed `Observation` namespace with a lock-protected `Registrar` and phantom-tagged property and subscription identifiers, extending observation to the `~Copyable` and `~Escapable` Subjects that Apple's class-only `@Observable` cannot reach.

---

## Quick Start

`Observation` is the vocabulary a value type uses to announce mutations: a `Registrar` holds the `Property.ID → Subscription.ID` bindings, and observers subscribe with `willSet` / `didSet` callbacks. Because the registrar's identity lives in a heap-allocated extent rather than in the Subject's class identity, a `~Copyable` Subject — the case Apple's macro forbids — can adopt observation by hand.

```swift
import Observation

// A ~Copyable Subject. Apple's class-only @Observable cannot express this.
struct Counter: ~Copyable, Observable {
    let _$registrar = Observation.Registrar()
    private var _raw: Int = 0

    var raw: Int {
        _read {
            _$registrar.access(.init(0))   // Property.ID 0 names `raw`.
            yield _raw
        }
        _modify {
            _$registrar.willSet(.init(0))
            yield &_raw
            _$registrar.didSet(.init(0))
        }
    }
}

var counter = Counter()
let subscription = counter._$registrar.subscribe(
    to: [.init(0)],
    didSet: { property in print("changed property", property.underlying) }
)

counter.raw = 42                                  // prints "changed property 0"
counter._$registrar.unsubscribe(subscription)
```

Identifiers are phantom-tagged integers, so they cannot be crossed at the type level: `Observation.Property.ID` is `Tagged<Observation.Property, UInt32>` and `Observation.Subscription.ID` is `Tagged<Observation.Subscription, UInt64>` — distinct types even though both are integers underneath. A `Subscription.ID` is meaningful only within the `Registrar` that vended it, so reusing the value `0` across two registrars is never a collision.

```swift
import Observation

let registrar = Observation.Registrar()

// withMutation brackets a change with willSet/didSet and returns the body's value.
let snapshot = registrar.withMutation(of: .init(0)) {
    // mutate backing storage here
    return 42
}

print(snapshot)   // 42
```

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-atoms/swift-observation.git", branch: "main")
]
```

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Observation", package: "swift-observation"),
    ]
)
```

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the matching Linux / Windows toolchain).

---

## Architecture

One base library product. Depends only on `Tagged`, `Ownership.Immutable`, and the standard library's `Synchronization` module.

| Product | Target | Purpose |
|---------|--------|---------|
| `Observation` | `Sources/Observation/` | The base `Observation` namespace: the marker protocol `Observation.Protocol` (with the `Observable` adjective typealias), the phantom-tagged `Observation.Property.ID` and `Observation.Subscription.ID`, and the lock-protected `Observation.Registrar` with `access` / `willSet` / `didSet` / `withMutation` / `subscribe` / `unsubscribe`. |

Foundation-free.

---

## Platform Support

| Platform | Status |
|----------|--------|
| macOS 26 | Full support |
| Linux | Full support |
| Windows | Full support |
| iOS / tvOS / watchOS / visionOS | Supported |

---

## Community

<!-- BEGIN: discussion -->
<!-- Discussion thread created at publication. -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
