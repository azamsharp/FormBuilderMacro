import Sharp
import SwiftUI

@FormBuilder
struct AddMovieView: View {
    @State private var movieName: String = ""
    @State private var isReleased: Bool = false
}
