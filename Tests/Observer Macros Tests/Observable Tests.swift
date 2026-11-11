import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import Observer_Macros

private let testMacros: [String: MacroSpec] = [
    "Observable": MacroSpec(type: Observable.self),
    "_ObservationTracked": MacroSpec(type: Tracked.self),
]

private func expectMacroExpansion(
    _ originalSource: String,
    expandedSource: String,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    assertMacroExpansion(
        originalSource,
        expandedSource: expandedSource,
        macroSpecs: testMacros,
        failureHandler: { failure in
            Issue.record(
                Comment(rawValue: failure.message),
                sourceLocation: SourceLocation(
                    fileID: failure.location.fileID.description,
                    filePath: failure.location.filePath.description,
                    line: Int(failure.location.line),
                    column: Int(failure.location.column)
                )
            )
        },
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}

enum `Observable Tests` {}

extension `Observable Tests` {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

extension `Observable Tests`.Test.Unit {

    @Test
    func `simple struct with two stored vars expands to target shape`() {
        expectMacroExpansion(
            """
            @Observable
            struct Counter {
                var x: Int = 0
                var y: Int = 0
            }
            """,
            expandedSource: """
                struct Counter {
                    var x: Int = 0 {
                        @storageRestrictions(initializes: _x)
                        init(initialValue) {
                            _x = initialValue
                        }
                        _read {
                            Observer.Tracking.access(_$registrar, .init(0))
                            yield _x
                        }
                        _modify {
                            _$registrar.willSet(.init(0))
                            yield &_x
                            _$registrar.didSet(.init(0))
                        }
                    }

                    var _x: Int
                    var y: Int = 0 {
                        @storageRestrictions(initializes: _y)
                        init(initialValue) {
                            _y = initialValue
                        }
                        _read {
                            Observer.Tracking.access(_$registrar, .init(1))
                            yield _y
                        }
                        _modify {
                            _$registrar.willSet(.init(1))
                            yield &_y
                            _$registrar.didSet(.init(1))
                        }
                    }

                    var _y: Int

                    let _$registrar: Observer.Registrar = Observer.Registrar()
                }

                extension Counter: Observer.`Protocol` {
                }
                """
        )
    }

    @Test
    func `noncopyable struct expansion composes with ~Copyable Self`() {

        expectMacroExpansion(
            """
            @Observable
            struct Foo: ~Copyable {
                var x: Int = 0
            }
            """,
            expandedSource: """
                struct Foo: ~Copyable {
                    var x: Int = 0 {
                        @storageRestrictions(initializes: _x)
                        init(initialValue) {
                            _x = initialValue
                        }
                        _read {
                            Observer.Tracking.access(_$registrar, .init(0))
                            yield _x
                        }
                        _modify {
                            _$registrar.willSet(.init(0))
                            yield &_x
                            _$registrar.didSet(.init(0))
                        }
                    }

                    var _x: Int

                    let _$registrar: Observer.Registrar = Observer.Registrar()
                }

                extension Foo: Observer.`Protocol` {
                }
                """
        )
    }

    @Test
    func `class subject synthesizes accessors and conformance`() {
        expectMacroExpansion(
            """
            @Observable
            class Box {
                var value: Int = 0
            }
            """,
            expandedSource: """
                class Box {
                    var value: Int = 0 {
                        @storageRestrictions(initializes: _value)
                        init(initialValue) {
                            _value = initialValue
                        }
                        _read {
                            Observer.Tracking.access(_$registrar, .init(0))
                            yield _value
                        }
                        _modify {
                            _$registrar.willSet(.init(0))
                            yield &_value
                            _$registrar.didSet(.init(0))
                        }
                    }

                    var _value: Int

                    let _$registrar: Observer.Registrar = Observer.Registrar()
                }

                extension Box: Observer.`Protocol` {
                }
                """
        )
    }

    @Test
    func `generic struct preserves the type parameter in the storage peer`() {
        expectMacroExpansion(
            """
            @Observable
            struct Box<T> {
                var value: T
            }
            """,
            expandedSource: """
                struct Box<T> {
                    var value: T {
                        @storageRestrictions(initializes: _value)
                        init(initialValue) {
                            _value = initialValue
                        }
                        _read {
                            Observer.Tracking.access(_$registrar, .init(0))
                            yield _value
                        }
                        _modify {
                            _$registrar.willSet(.init(0))
                            yield &_value
                            _$registrar.didSet(.init(0))
                        }
                    }

                    var _value: T

                    let _$registrar: Observer.Registrar = Observer.Registrar()
                }

                extension Box: Observer.`Protocol` {
                }
                """
        )
    }
}

extension `Observable Tests`.Test.`Edge Case` {

    @Test
    func `mixed let and var only tracks var`() {
        expectMacroExpansion(
            """
            @Observable
            struct Counter {
                let id: Int
                var x: Int = 0
            }
            """,
            expandedSource: """
                struct Counter {
                    let id: Int
                    var x: Int = 0 {
                        @storageRestrictions(initializes: _x)
                        init(initialValue) {
                            _x = initialValue
                        }
                        _read {
                            Observer.Tracking.access(_$registrar, .init(0))
                            yield _x
                        }
                        _modify {
                            _$registrar.willSet(.init(0))
                            yield &_x
                            _$registrar.didSet(.init(0))
                        }
                    }

                    var _x: Int

                    let _$registrar: Observer.Registrar = Observer.Registrar()
                }

                extension Counter: Observer.`Protocol` {
                }
                """
        )
    }

    @Test
    func `underscore-prefixed var is not tracked`() {
        expectMacroExpansion(
            """
            @Observable
            struct Counter {
                var _internal: Int = 0
                var x: Int = 0
            }
            """,
            expandedSource: """
                struct Counter {
                    var _internal: Int = 0
                    var x: Int = 0 {
                        @storageRestrictions(initializes: _x)
                        init(initialValue) {
                            _x = initialValue
                        }
                        _read {
                            Observer.Tracking.access(_$registrar, .init(0))
                            yield _x
                        }
                        _modify {
                            _$registrar.willSet(.init(0))
                            yield &_x
                            _$registrar.didSet(.init(0))
                        }
                    }

                    var _x: Int

                    let _$registrar: Observer.Registrar = Observer.Registrar()
                }

                extension Counter: Observer.`Protocol` {
                }
                """
        )
    }
}
