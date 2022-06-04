import SwiftUI
import ComposableArchitecture
import IdentifiedCollections

struct CodeView: View {
    let store: Store<BaseState<CodeState>, CodeAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                if viewStore.mode == .edition {
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
                                    store.scope(
                                        state: \.pathElements,
                                        action: CodeAction.pathElement(id:action:)
                                    ),
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
            }.onTapGesture(count: 2) {
                viewStore.send(.modeChanged(.edition))
            }
        }
    }

    @ViewBuilder
    private func pathElementCode(store: Store<PathElement, PathElementAction>) -> some View {
        WithViewStore(store) { viewStore in
            HStack {
                Text(viewStore.code.codeFormatted(extraIndentation: 2))
                    .opacity(viewStore.isHovered ? 1 : 0.8)
                if viewStore.isHovered && viewStore.isTransformable {
                    Menu {
                        ForEach(PathTool.allCases.filter { $0 != viewStore.type.tool }) { tool in
                            Button { viewStore.send(.transform(to: tool)) } label: { tool.text }
                        }
                        Button("Remove", role: .destructive) {
                            viewStore.send(.remove)
                        }
                    } label: {
                        Label("Transform", systemImage: "scissors")
                    }
                    .frame(width: 150)
                    .padding()
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

    private func code(viewStore: ViewStore<BaseState<CodeState>, CodeAction>) -> Binding<String> {
        Binding<String>(
            get: { [
                codeHeader,
                viewStore.pathElements.map(\.code).joined(separator: "\n"),
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

private extension PathElement.PathElementType {
    var tool: PathTool {
        switch self {
        case .move: return .move
        case .line: return .line
        case .curve: return .curve
        case .quadCurve: return .quadCurve
        }
    }
}

private extension PathTool {
    var text: Text {
        switch self {
        case .move: return Text("Move")
        case .line: return Text("Line")
        case .curve: return Text("Curve")
        case .quadCurve: return Text("QuadCurve")
        }
    }
}
