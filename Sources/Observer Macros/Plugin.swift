import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct Plugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        Ignored.self,
        Observable.self,
        Tracked.self,
    ]
}
