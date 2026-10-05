import SwiftUI
import WebKit

struct WhoToNotifyView: View {

    private struct WtnPhotoDoc: Identifiable, Hashable {
        let id = UUID()
        let assetName: String
        let displayTitle: String
        let accent: Color
    }

    private let wtnPhotos: [WtnPhotoDoc] = [
        WtnPhotoDoc(assetName: "who_to_notify_1",
                    displayTitle: "Family photograph",
                    accent: .purple)
    ]

    private let entries: [NotificationEntry] = WhoToNotifySeed.allEntries

    @State private var selectedWtnPhoto: WtnPhotoDoc?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            photosSection
            introCalloutSection

            ForEach(entries) { entry in
                organisationCard(entry)
            }

            songForThePageSection
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .sheet(item: $selectedWtnPhoto) { doc in
            fullscreenWtnPhotoViewer(for: doc)
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
                    ForEach(wtnPhotos) { doc in
                        photoThumbnail(doc)
                    }
                }
                .padding(16)
            }
        }
    }

    private func photoThumbnail(_ doc: WtnPhotoDoc) -> some View {
        Button(action: {
            selectedWtnPhoto = doc
        }) {
            ZStack(alignment: .bottomTrailing) {
                Image(doc.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(4/3, contentMode: .fill)
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

    // MARK: - Intro Callout

    private var introCalloutSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.title3)
                .foregroundStyle(.purple)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.purple.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text("Start with Life Ledger first")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("It bulk-notifies dozens of companies automatically using the accounts below. Only a few exceptions (Tembo, @SIPP) require direct calls.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.6), lineWidth: 0.5)
        )
    }

    // MARK: - Organisation Card

    private func organisationCard(_ entry: NotificationEntry) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: entry.orgName,
                          systemImage: entry.systemIcon,
                          tint: entry.accentColor)

            if let lead = entry.leadParagraph {
                Text(lead)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !entry.links.isEmpty || entry.phone != nil {
                actionsRow(entry)
            }

            if !entry.fields.isEmpty {
                fieldsStack(entry)
            }

            if !entry.notes.isEmpty {
                notesCallouts(entry)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator).opacity(0.4), lineWidth: 0.6)
        )
    }

    // MARK: - Actions Row (Links + Phone)

    private func actionsRow(_ entry: NotificationEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(entry.links) { link in
                Link(destination: link.url) {
                    HStack(spacing: 10) {
                        Image(systemName: "safari.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(entry.accentColor)
                        Text(link.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(entry.accentColor)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.subheadline)
                            .foregroundStyle(entry.accentColor.opacity(0.8))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(entry.accentColor.opacity(0.10))
                    )
                }
            }

            if let phone = entry.phone, let telURL = Self.telURL(for: phone) {
                Link(destination: telURL) {
                    HStack(spacing: 10) {
                        Image(systemName: "phone.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                        Text("Call \(Self.displayPhone(phone))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.subheadline)
                            .foregroundStyle(.green.opacity(0.8))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.green.opacity(0.10))
                    )
                }
            }
        }
    }

    // MARK: - Key/Value Fields (monospaced, copyable)

    private func fieldsStack(_ entry: NotificationEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(entry.fields) { field in
                copyableFieldRow(field, tint: entry.accentColor)
            }
        }
    }

    private func copyableFieldRow(_ field: NotificationField, tint: Color) -> some View {
        Menu {
            Button(action: { UIPasteboard.general.string = field.value }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            if field.note != nil {
                Button(action: { UIPasteboard.general.string = "\(field.key): \(field.value)" }) {
                    Label("Copy Full Line", systemImage: "list.clipboard")
                }
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(field.key)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(field.value)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(field.monospace == .sortCode ? .semibold : .medium)
                        .foregroundStyle(.primary)
                    if let note = field.note {
                        Text(note)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "doc.on.doc.fill")
                    .font(.caption)
                    .foregroundStyle(tint.opacity(0.7))
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(tint.opacity(0.10))
                    )
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: { UIPasteboard.general.string = field.value }) {
                Label("Copy Value", systemImage: "doc.on.doc")
            }
        }
    }

    // MARK: - Notes / Info Callouts

    private func notesCallouts(_ entry: NotificationEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(entry.notes.enumerated()), id: \.offset) { _, note in
                infoCallout(text: note, tint: entry.accentColor)
            }
        }
    }

    private func infoCallout(text: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(tint)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.08))
        )
    }

    // MARK: - Song For The Page Section (YouTube)

    private var songForThePageSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Song for the page",
                          systemImage: "music.note.tv.fill",
                          tint: .teal)

            cardBackground {
                VStack(alignment: .leading, spacing: 12) {
                    Text("A little something for this page — tap play to listen.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Color.black
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 200)
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(14)
                        .overlay {
                            YouTubePlayerView(videoID: "tuyBCSYTs5A")
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

    private func fullscreenWtnPhotoViewer(for doc: WtnPhotoDoc) -> some View {
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
                        selectedWtnPhoto = nil
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

    // MARK: - Phone helpers

    private static func displayPhone(_ raw: String) -> String {
        raw
    }

    private static func telURL(for raw: String) -> URL? {
        let cleaned = raw.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return URL(string: "tel:\(cleaned)")
    }
}

#Preview {
    NavigationStack {
        WhoToNotifyView()
            .padding()
    }
}
