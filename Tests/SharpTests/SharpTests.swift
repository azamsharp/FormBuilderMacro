import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import SharpMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
    "FormBuilder": FormBuilderMacro.self
]

final class SharpTests: XCTestCase {
    
    
    func testFormBuilderMacro() {
        assertMacroExpansion("""
              @FormBuilder
              struct AddMovieView: View {
                @State private var movieName: String = ""
                @State private isReleased: Bool = false
              }
            
            """, expandedSource: """
         
            @FormBuilder
            struct AddMovieView: View {
                @State private var movieName: String = ""
                @State private isReleased: Bool = false

                var body: some View {
                    TextField("movieName", text: $movieName)
                    Toggle("isReleased", isOn: $isReleased)
                }
            }


""", macros: testMacros)
    }
    
    
    
    func testMacro() {
        assertMacroExpansion(
            """
            #stringify(a + b)
            """,
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
    }

    func testMacroWithStringLiteral() {
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
    }
}
