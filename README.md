# Observer

Observer owns explicit property subscriptions: a registrar maps property identities to callbacks and supports cancellation by subscription identity. Registrar copies share the same state. Mutation notifications run outside the registry lock; didSet follows the mutation even when it throws. Observable is the marker protocol alias for participating values.

The package and module are named Observer to avoid shadowing the Apple SDK Observation module when Swift Testing compiles cross-import overlays. Automatic dependency tracking and macros belong to the higher-level Observations package.
