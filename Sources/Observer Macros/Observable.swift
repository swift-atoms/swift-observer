import SwiftSyntax
import SwiftSyntaxMacros

public struct Observable {}

extension VariableDeclSyntax {

    fileprivate var isObservableStored: Bool {
        guard bindingSpecifier.tokenKind == .keyword(.var) else { return false }
        for modifier in modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.static), .keyword(.class), .keyword(.lazy):
                return false

            default:
                continue
            }
        }
        for binding in bindings {
            if binding.accessorBlock != nil { return false }
            if let id = binding.pattern.as(IdentifierPatternSyntax.self),
                id.identifier.text.hasPrefix("_")
            {
                return false
            }
        }
        return true
    }

    fileprivate var firstBindingName: String? {
        guard let binding = bindings.first,
            let id = binding.pattern.as(IdentifierPatternSyntax.self)
        else { return nil }
        return id.identifier.text
    }
}

extension Observable: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws(Never) -> [DeclSyntax] {

        _ = protocols

        for member in declaration.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self),
                varDecl.bindings.contains(where: { binding in
                    binding.pattern.as(IdentifierPatternSyntax.self)?
                        .identifier.text == "_$registrar"
                })
            {
                return []
            }
        }
        return [
            "let _$registrar: Observer.Registrar = Observer.Registrar()"
        ]
    }
}

extension Observable: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws(Never) -> [ExtensionDeclSyntax] {
        if let inherits = declaration.inheritanceClause {
            for entry in inherits.inheritedTypes {
                let token = entry.type.trimmedDescription
                if token == "Observable" || token == "Observer.Observable"
                    || token == "Observer.Protocol" || token == "Observer.`Protocol`"
                {
                    return []
                }
            }
        }
        let extensionDecl: DeclSyntax = """
            extension \(type.trimmed): Observer.`Protocol` {}
            """
        return [extensionDecl.cast(ExtensionDeclSyntax.self)]
    }
}

extension Observable {
    static func tracked(_ index: UInt32) -> AttributeSyntax {
        "@_ObservationTracked(\(raw: index))"
    }
}

extension Observable: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws(Never) -> [AttributeSyntax] {
        guard let varDecl = member.as(VariableDeclSyntax.self),
            varDecl.isObservableStored,
            let varName = varDecl.firstBindingName
        else {
            return []
        }
        for attr in varDecl.attributes {
            if let attribute = attr.as(AttributeSyntax.self),
                attribute.attributeName.trimmedDescription.hasSuffix("_ObservationTracked")
            {
                return []
            }
        }
        var index: UInt32 = 0
        for memberItem in declaration.memberBlock.members {
            guard let candidate = memberItem.decl.as(VariableDeclSyntax.self) else { continue }
            if candidate.firstBindingName == varName {
                break
            }
            if candidate.isObservableStored {
                index += 1
            }
        }
        return [tracked(index)]
    }
}
