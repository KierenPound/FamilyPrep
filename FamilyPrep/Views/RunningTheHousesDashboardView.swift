import SwiftUI
import WebKit

struct RunningTheHousesDashboardView: View {

    private struct HousePhotoDoc: Identifiable, Hashable {
        let id = UUID()
        let assetName: String
        let displayTitle: String
        let accent: Color
    }

    private struct TradesmanContact: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let role: String
        let company: String?
        let phoneNumber: String
        let systemImage: String
        let accent: Color
    }

    private struct TradesLocationGroup: Identifiable, Hashable {
        let id = UUID()
        let location: String
        let systemImage: String
        let tint: Color
        let tradesmen: [TradesmanContact]
    }

    private let housePhotos: [HousePhotoDoc] = [
        HousePhotoDoc(assetName: "houses_1",
                      displayTitle: "House photograph",
                      accent: .green)
    ]

    private let tradesmen: [TradesLocationGroup] = [
        TradesLocationGroup(location: "Perth",
                            systemImage: "mappin.circle.fill",
                            tint: .red,
                            tradesmen: [
                                TradesmanContact(name: "Neil",
                                                 role: "Gas and Plumbing",
                                                 company: "Perth Renu",
                                                 phoneNumber: "07894 248726",
                                                 systemImage: "flame.fill",
                                                 accent: .orange),
                                TradesmanContact(name: "Fraser",
                                                 role: "Electrics",
                                                 company: "FM Electrics",
                                                 phoneNumber: "07545 078968",
                                                 systemImage: "bolt.fill",
                                                 accent: .yellow),
                                TradesmanContact(name: "Andrew Gallagher",
                                                 role: "Electrics (Dunning)",
                                                 company: nil,
                                                 phoneNumber: "07977 194742",
                                                 systemImage: "bolt.fill",
                                                 accent: .yellow)
                            ]),
        TradesLocationGroup(location: "Ayr",
                            systemImage: "mappin.circle.fill",
                            tint: .blue,
                            tradesmen: [
                                TradesmanContact(name: "Darwin Johnstone",
                                                 role: "Gas and Plumbing",
                                                 company: nil,
                                                 phoneNumber: "07793 486802",
                                                 systemImage: "flame.fill",
                                                 accent: .orange),
                                TradesmanContact(name: "Klearflow drains",
                                                 role: "Drain cleaning (usually Bath Place)",
                                                 company: nil,
                                                 phoneNumber: "01292 501059",
                                                 systemImage: "water.faucet.fill",
                                                 accent: .teal),
                                TradesmanContact(name: "Steven Mitchell",
                                                 role: "Electrical checks and repairs",
                                                 company: "Mitchell Electrics",
                                                 phoneNumber: "07850 956254",
                                                 systemImage: "bolt.fill",
                                                 accent: .yellow)
                            ])
    ]

    @State private var selectedHousePhoto: HousePhotoDoc?

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            photosSection
            tradesmenSection
            songSection
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .sheet(item: $selectedHousePhoto) { doc in
            fullscreenHousePhotoViewer(for: doc)
        }
    }

    // MARK: - Photos Section

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Photos",
                          systemImage: "photo.stack.fill",
                          tint: .green)

            cardBackground {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(housePhotos) { doc in
                        photoThumbnail(doc)
                    }
                }
                .padding(16)
            }
        }
    }

    private func photoThumbnail(_ doc: HousePhotoDoc) -> some View {
        Button(action: {
            selectedHousePhoto = doc
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

    // MARK: - Tradesmen Section

    private var tradesmenSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Tradesmen",
                          systemImage: "wrench.and.screwdriver.fill",
                          tint: .indigo)

            cardBackground {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(tradesmen) { group in
                        locationGroupCard(group)
                    }
                }
                .padding(16)
            }
        }
    }

    private func locationGroupCard(_ group: TradesLocationGroup) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(group.tint.opacity(0.18))
                        .frame(width: 28, height: 28)
                    Image(systemName: group.systemImage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(group.tint)
                }
                Text(group.location)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(group.tradesmen) { trade in
                    tradesmanRow(trade)
                }
            }
        }
    }

    private func tradesmanRow(_ trade: TradesmanContact) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(trade.accent.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: trade.systemImage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(trade.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trade.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    if let company = trade.company {
                        Text(company)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text(trade.role)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Link(destination: URL(string: "tel://\(trade.phoneNumber.replacingOccurrences(of: " ", with: ""))")!) {
                    HStack(spacing: 5) {
                        Image(systemName: "phone.fill")
                            .font(.caption.weight(.semibold))
                        Text(trade.phoneNumber)
                            .font(.subheadline.weight(.semibold))
                            .monospaced()
                    }
                    .foregroundStyle(.green)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 11)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.14))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.green.opacity(0.25), lineWidth: 0.4)
                    )
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Song Section

    private var songSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Song for the page",
                          systemImage: "music.note.tv.fill",
                          tint: .teal)

            cardBackground {
                VStack(alignment: .leading, spacing: 12) {
                    Text("A little something to keep you going while sorting out all the house stuff. Play it loud!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ZStack {
                        Color.black
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: 200)
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(14)
                            .clipped()
                            .padding(.horizontal, 4)

                        YouTubePlayerView(videoID: "jqpAgMxhx30")
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: 200)
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(14)
                            .clipped()
                            .padding(.horizontal, 4)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(.separator), lineWidth: 0.5)
                            .padding(.horizontal, 4)
                    )
                }
                .padding(16)
            }
        }
    }

    // MARK: - Fullscreen viewer

    private func fullscreenHousePhotoViewer(for doc: HousePhotoDoc) -> some View {
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
                        selectedHousePhoto = nil
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
        RunningTheHousesDashboardView()
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
    }
    .background(Color(.systemGroupedBackground))
}
