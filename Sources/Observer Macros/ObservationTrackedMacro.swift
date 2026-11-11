import SwiftSyntax
import SwiftSyntaxMacros

public struct ObservationTrackedMacro {}

extension VariableDeclSyntax {

    fileprivate var trackedBinding: (name: TokenSyntax, type: TypeSyntax)? {
        guard bindings.count == 1, let binding = bindings.first,
            let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
            let typeAnnotation = binding.typeAnnotation
        else { return nil }
        return (identifier.identifier.trimmed, typeAnnotation.type.trimmed)
    }
}

private func extractID(from node: AttributeSyntax) -> UInt32 {
    guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
        let firstArg = arguments.first,
        let intExpr = firstArg.expression.as(IntegerLiteralExprSyntax.self),
        let value = UInt32(intExpr.literal.text)
    else { return 0 }
    return value
}

extension ObservationTrackedMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws(Never) -> [AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
            let (name, _) = varDecl.trackedBinding
        else {
            return []
        }
        let storage: TokenSyntax = .identifier("_\(name.text)")
        let id = extractID(from: node)

        let initAcc: AccessorDeclSyntax = """
            @storageRestrictions(initializes: \(storage))
            init(initialValue) {
                \(storage) = initialValue
            }
            """
        let readAcc: AccessorDeclSyntax = """
            _read {
                Observer.Tracking.access(_$registrar, .init(\(raw: id)))
                yield \(storage)
            }
            """
        let modifyAcc: AccessorDeclSyntax = """
            _modify {
                _$registrar.willSet(.init(\(raw: id)))
                yield &\(storage)
                _$registrar.didSet(.init(\(raw: id)))
            }
            """
        return [initAcc, readAcc, modifyAcc]
    }
}

extension ObservationTrackedMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws(Never) -> [DeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
            let (name, type) = varDecl.trackedBinding
        else {
            return []
        }
        let storage: TokenSyntax = .identifier("_\(name.text)")
        return ["var \(storage): \(type)"]
    }
}
