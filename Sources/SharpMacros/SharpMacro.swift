import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

enum StructInitError: CustomStringConvertible, Error {
    case onlyApplicableToStruct
    
    var description: String {
        switch self {
        case .onlyApplicableToStruct: return "@StructInit can only be applied to a structure"
        }
    }
}

public struct FormBuilderMacro: MemberMacro {
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        
        // make sure that macro is being applied on a struct
        guard let structDel = declaration.as(StructDeclSyntax.self) else {
            throw StructInitError.onlyApplicableToStruct
        }
        
        let members = structDel.memberBlock.members
        let variableDeclarations = members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
        let variableNames = variableDeclarations.compactMap { $0.bindings.first?.pattern }
        let variableTypes = variableDeclarations.compactMap { $0.bindings.first?.typeAnnotation?.type }
        
        var body = """
            var body: some View {
        Form {
        
        """
        
        for (name, type) in zip(variableNames, variableTypes) {
            
            if type.as(SimpleTypeIdentifierSyntax.self)!.name.text == "String" {
                body += "TextField(\"Enter \(name)\", text: $\(name))"
            } else if type.as(SimpleTypeIdentifierSyntax.self)!.name.text == "Bool" {
                body += "Toggle(isOn: $\(name)){"
                body += "Text(\"\(name)\")"
                body += "}"
            }
        }
        
        body += """
                }
            }
        """
        
        return [DeclSyntax(stringLiteral: body)]
    }
    
}


@main
struct SharpPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        FormBuilderMacro.self
    ]
}

/*
 StructDeclSyntax
 ├─attributes: AttributeListSyntax
 │ ╰─[0]: AttributeSyntax
 │   ├─atSignToken: atSign
 │   ╰─attributeName: SimpleTypeIdentifierSyntax
 │     ╰─name: identifier("FormBuilder")
 ├─structKeyword: keyword(SwiftSyntax.Keyword.struct)
 ├─identifier: identifier("AddMovieView")
 ├─inheritanceClause: TypeInheritanceClauseSyntax
 │ ├─colon: colon
 │ ╰─inheritedTypeCollection: InheritedTypeListSyntax
 │   ╰─[0]: InheritedTypeSyntax
 │     ╰─typeName: SimpleTypeIdentifierSyntax
 │       ╰─name: identifier("View")
 ╰─memberBlock: MemberDeclBlockSyntax
   ├─leftBrace: leftBrace
   ├─members: MemberDeclListSyntax
   │ ├─[0]: MemberDeclListItemSyntax
   │ │ ╰─decl: VariableDeclSyntax
   │ │   ├─attributes: AttributeListSyntax
   │ │   │ ╰─[0]: AttributeSyntax
   │ │   │   ├─atSignToken: atSign
   │ │   │   ╰─attributeName: SimpleTypeIdentifierSyntax
   │ │   │     ╰─name: identifier("State")
   │ │   ├─modifiers: ModifierListSyntax
   │ │   │ ╰─[0]: DeclModifierSyntax
   │ │   │   ╰─name: keyword(SwiftSyntax.Keyword.private)
   │ │   ├─bindingKeyword: keyword(SwiftSyntax.Keyword.var)
   │ │   ╰─bindings: PatternBindingListSyntax
   │ │     ╰─[0]: PatternBindingSyntax
   │ │       ├─pattern: IdentifierPatternSyntax
   │ │       │ ╰─identifier: identifier("movieName")
   │ │       ├─typeAnnotation: TypeAnnotationSyntax
   │ │       │ ├─colon: colon
   │ │       │ ╰─type: SimpleTypeIdentifierSyntax
   │ │       │   ╰─name: identifier("String")
   │ │       ╰─initializer: InitializerClauseSyntax
   │ │         ├─equal: equal
   │ │         ╰─value: StringLiteralExprSyntax
   │ │           ├─openQuote: stringQuote
   │ │           ├─segments: StringLiteralSegmentsSyntax
   │ │           │ ╰─[0]: StringSegmentSyntax
   │ │           │   ╰─content: stringSegment("")
   │ │           ╰─closeQuote: stringQuote
   │ ╰─[1]: MemberDeclListItemSyntax
   │   ╰─decl: VariableDeclSyntax
   │     ├─attributes: AttributeListSyntax
   │     │ ╰─[0]: AttributeSyntax
   │     │   ├─atSignToken: atSign
   │     │   ╰─attributeName: SimpleTypeIdentifierSyntax
   │     │     ╰─name: identifier("State")
   │     ├─modifiers: ModifierListSyntax
   │     │ ╰─[0]: DeclModifierSyntax
   │     │   ╰─name: keyword(SwiftSyntax.Keyword.private)
   │     ├─bindingKeyword: keyword(SwiftSyntax.Keyword.var) MISSING
   │     ╰─bindings: PatternBindingListSyntax
   │       ╰─[0]: PatternBindingSyntax
   │         ├─pattern: IdentifierPatternSyntax
   │         │ ╰─identifier: identifier("isReleased")
   │         ├─typeAnnotation: TypeAnnotationSyntax
   │         │ ├─colon: colon
   │         │ ╰─type: SimpleTypeIdentifierSyntax
   │         │   ╰─name: identifier("Bool")
   │         ╰─initializer: InitializerClauseSyntax
   │           ├─equal: equal
   │           ╰─value: BooleanLiteralExprSyntax
   │             ╰─booleanLiteral: keyword(SwiftSyntax.Keyword.false)
   ╰─rightBrace: rightBrace
 */
