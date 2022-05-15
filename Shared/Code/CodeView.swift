import SwiftUI
import ComposableArchitecture
import IdentifiedCollections

struct CodeView: View {
    let store: Store<DrawingState, DrawingAction>
    @Binding var isInEditionMode: Bool

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                if isInEditionMode {
                    TextEditor(text: code(viewStore: viewStore))
                        .font(.body.monospaced())
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    ScrollView {
                        HStack {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(codeHeader.codeFormatted).opacity(0.8)
                                ForEachStore(
                                    store.scope(state: \.pathElements, action: DrawingAction.pathElement(id:action:)),
                                    content: pathElementCode(store:)
                                )
                                Text(codeFooter).opacity(0.8)
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
    }

    @ViewBuilder
    private func pathElementCode(store: Store<PathElementState, PathElementAction>) -> some View {
        WithViewStore(store) { viewStore in
            HStack {
                Text(viewStore.element.code.codeFormatted(extraIndentation: 2))
                    .opacity(viewStore.isHovered ? 1 : 0.8)
                if viewStore.isHovered {
                    Button("Remove", role: .destructive) {
                        viewStore.send(.remove)
                    }
                    .padding(.horizontal)
                }
            }
            .background {
                if viewStore.isHovered {
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
                    viewStore.send(.hoverChanged(isHovered))
                }
            }
        }
    }

    private func code(viewStore: ViewStore<DrawingState, DrawingAction>) -> Binding<String> {
        Binding<String>(
            get: { [
                codeHeader,
                viewStore.pathElements.map(\.element.code).joined(separator: "\n"),
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
