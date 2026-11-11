import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ObserverPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ObservableMacro.self,
        ObservationTrackedMacro.self,
    ]
}
