import SwiftUI
import WebKit

struct FuneralArrangementsDashboardView: View {

    private struct FuneralPhotoDoc: Identifiable, Hashable {
        let id = UUID()
        let assetName: String
        let displayTitle: String
        let accent: Color
    }

    private let funeralPhotos: [FuneralPhotoDoc] = [
        FuneralPhotoDoc(assetName: "funeral_1",
                        displayTitle: "Family photograph",
                        accent: .indigo)
    ]

    @State private var selectedFuneralPhoto: FuneralPhotoDoc?

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            photosSection
            kierenFuneralSection
            brenFuneralSection
            songSection
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .sheet(item: $selectedFuneralPhoto) { doc in
            fullscreenFuneralPhotoViewer(for: doc)
        }
    }

    // MARK: - Photos Section

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Photos",
                          systemImage: "photo.stack.fill",
                          tint: .blue)

            cardBackground {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(funeralPhotos) { doc in
                        photoThumbnail(doc)
                    }
                }
                .padding(16)
            }
        }
    }

    private func photoThumbnail(_ doc: FuneralPhotoDoc) -> some View {
        Button(action: {
            selectedFuneralPhoto = doc
        }) {
            ZStack(alignment: .bottomTrailing) {
                Image(doc.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 135)
                    .clipped()
                    .cornerRadius(11)
                    .contentShape(Rectangle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(doc.accent.opacity(0.35), lineWidth: 0.8)
                    )

                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 21, height: 21)
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(doc.accent)
                }
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    // MARK: - Funeral (Kieren)

    private var kierenFuneralSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Funeral (Kieren)",
                          systemImage: "person.fill",
                          tint: .indigo)

            cardBackground {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hopefully the image above will inspire you.  As you know, I have always wanted to be thrown off the side of a Calmac ferry to save on costs.  Here's me visualising it as a happy day out as a family, were I suffering a terminal illness and incapacitated in a wheelchair.  I did ask for a bodybag but AI has guardrails don't you know")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Joking aside, I don't want an attended cremation.  I want the least money to be wasted.  I wouldn't mind my ashes going under a tree in the garden though, hoping that Bren is still alive.  Maybe even plant a tree!  And have a nice meal out on me")
                            .font(.body)

                        Link(destination: URL(string: "https://express-cremations.co.uk/")!) {
                            HStack(spacing: 8) {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.orange)
                                Text("Express Cremations")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.blue)
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.08))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.blue.opacity(0.25), lineWidth: 0.6)
                            )
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Funeral (Bren)

    private var brenFuneralSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Funeral (Bren)",
                          systemImage: "person.fill.2",
                          tint: .pink)

            cardBackground {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "flame")
                                .foregroundStyle(.orange)
                                .font(.subheadline.weight(.semibold))
                            Text("Cremation + return of ashes")
                                .font(.headline)
                        }

                        Text("Maybe an attended cremation would be nice for her friends.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "leaf.fill")
                                .foregroundStyle(.green)
                                .font(.subheadline.weight(.semibold))
                            Text("Ashes split")
                                .font(.headline)
                        }

                        HStack(alignment: .top, spacing: 10) {
                            Label("50%", systemImage: "mountain.2.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.teal)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 10)
                                .background(
                                    Capsule().fill(Color.teal.opacity(0.12))
                                )
                            Text("Scattered above her mum and dad in Wales")
                                .font(.body)
                            Spacer(minLength: 0)
                        }

                        HStack(alignment: .top, spacing: 10) {
                            Label("50%", systemImage: "sparkles")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.purple)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 10)
                                .background(
                                    Capsule().fill(Color.purple.opacity(0.12))
                                )
                            Text("A venue of your choice")
                                .font(.body)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Song Section (YouTube)

    private var songSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Song for the page",
                          systemImage: "music.note.tv.fill",
                          tint: .teal)

            cardBackground {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Loud, theatrical, and exactly the right kind of daft for a funeral send-off.  Play it loud.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Color.black
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 200)
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(14)
                        .overlay {
                            YouTubePlayerView(videoID: "02T6xLNXEE0")
                                .cornerRadius(14)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                }
                .padding(16)
            }
        }
    }

    private func fullscreenFuneralPhotoViewer(for doc: FuneralPhotoDoc) -> some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    Color.black.ignoresSafeArea()

                    ScrollView([.vertical, .horizontal]) {
                        Image(doc.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: geo.size.width - 32, maxHeight: geo.size.height - 32)
                            .padding(16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(doc.displayTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedFuneralPhoto = nil
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                            .font(.headline)
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule().fill(.white.opacity(0.12))
                            )
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.primary)
        }
    }

    private func cardBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
    }

}

#Preview {
    ScrollView {
        FuneralArrangementsDashboardView()
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
    }
    .background(Color(.systemGroupedBackground))
}
