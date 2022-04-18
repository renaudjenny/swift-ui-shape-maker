import SwiftUI

struct CodeView: View {
    @Binding var pathElements: [PathElement]
    @Binding var hoveredOffsets: Set<Int>
    @Binding var isInEditionMode: Bool

    var body: some View {
        ZStack {
            if isInEditionMode {
                TextEditor(text: code)
                    .font(.body.monospaced())
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ScrollView {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(codeHeader.codeFormatted)
                            ForEach(Array(pathElements.enumerated()), id: \.offset) { offset, element in
                                HStack {
                                    Text(element.code.codeFormatted(extraIndentation: 2))
                                    if hoveredOffsets.contains(offset) {
                                        Button("Remove", role: .destructive) {
                                            pathElements.remove(at: offset)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                .background {
                                    if hoveredOffsets.contains(offset) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white)
                                            .shadow(color: .black, radius: 4)
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white)
                                            .padding()
                                    }
                                }
                                .contentShape(Rectangle())
                                .onHover { isHovered in
                                    withAnimation(.easeInOut) {
                                        if isHovered {
                                            hoveredOffsets.insert(offset)
                                        } else {
                                            hoveredOffsets.remove(offset)
                                        }
                                    }
                                }
                            }
                            Text(codeFooter)
                        }
                        .padding(.horizontal, 5)
                        Spacer()
                    }
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity)
                .font(.body.monospaced())
                .background(Color.white)
                .padding()
            }
        }.onTapGesture {
            isInEditionMode = true
        }
    }

    private var code: Binding<String> {
        Binding<String>(
            get: { [
                codeHeader,
                pathElements.map(\.code).joined(separator: "\n"),
                codeFooter,
            ].joined(separator: "\n").codeFormatted },
            set: { _, _ in }
        )
    }

    private var codeHeader: String { """
    import SwiftUI

    struct MyShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let width = min(rect.width, rect.height)
    """}

    // swiftlint: disable indentation_width
    private var codeFooter: String { """
            return path
        }
    }
    """ }
    // swiftlint: enable indentation_width
}
