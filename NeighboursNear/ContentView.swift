import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                WithViewStore(self.store, observe: { $0 }) { viewStore in
                    VStack(spacing: 0) {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                ForEach(Array(viewStore.announcings.enumerated()), id: \.offset) { _, announcing in
                                    AnnouncingCard(announcing: announcing, photos: viewStore.photos)
                                }
                            }
                            .padding(16)
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        VStack(alignment: .leading, spacing: 8) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(viewStore.suggestions.enumerated()), id: \.offset) { index, suggestion in
                                        Button(action: {
                                            // Hook up to your TCA action if available, e.g. viewStore.send(.suggestionTapped(index))
                                        }) {
                                            Text(String(describing: suggestion))
                                                .font(.callout)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(.ultraThinMaterial, in: Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                            }

                            // Transcript below suggestions
                            Text(viewStore.transcript)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)

                            // Bottom-most toolbar with finalize and add photo buttons
                            HStack {
                                Button {
                                    viewStore.send(.finalizeTapped)
                                } label: {
                                    Label("Готово", systemImage: "checkmark.circle.fill")
                                        .labelStyle(.titleAndIcon)
                                }

                                Spacer()

                                Button {
                                    // Hook up to your add-photo action, e.g. viewStore.send(.addPhotoTapped)
                                } label: {
                                    Label("Add Photo", systemImage: "photo.on.rectangle.angled")
                                        .labelStyle(.iconOnly)
                                }
                                .accessibilityLabel("Add Photo")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                        }
                        .padding(.top, 8)
                    }
                    .onAppear { viewStore.send(.onAppear) }
                }
            }
        }
    }
}

private struct AnnouncingCard: View {
    let announcing: Announcing
    let photos: [String: UIImage]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let firstPhoto = announcing.photos.first, let photo = photos[firstPhoto] {
                // uiimage to swiftui image
                let uiImageRepresentable = Image(uiImage: photo)
                uiImageRepresentable
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                placeholderImage
            }
            
            Text(announcing.details)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Text(announcing.price)
                .font(.callout.weight(.semibold))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.15))
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private var placeholderImage: some View {
        ZStack {
            Image(systemName: "photo")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
