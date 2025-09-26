import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                WithViewStore(self.store, observe: { $0 }) { viewStore in
                    VStack {
                        Text(viewStore.announcings.debugDescription)
                        Text(viewStore.suggestions.debugDescription)
                    }
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            HStack(spacing: 8) {
                                Image(systemName: "waveform")
                                    .foregroundStyle(.primary)
                                Text(viewStore.transcript)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Button {
                                    viewStore.send(.finalizeTapped)
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .symbolRenderingMode(.hierarchical)
                                }
                                .accessibilityLabel("Готово")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                    .onAppear { viewStore.send(.onAppear) }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
