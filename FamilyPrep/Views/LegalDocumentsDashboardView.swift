import SwiftUI
import WebKit
import PDFKit

struct LegalDocumentsDashboardView: View {

    private struct HouseDeedDoc: Identifiable, Hashable {
        let id = UUID()
        let assetName: String
        let displayTitle: String
        let accent: Color
    }

    private struct HeaderImageDoc: Identifiable, Hashable {
        let id = UUID()
        let assetName: String
        let displayTitle: String
    }

    private struct WillDoc: Identifiable, Hashable {
        let id = UUID()
        let assetName: String
        let displayTitle: String
        let accent: Color
    }

    private let headerImages: [HeaderImageDoc] = [
        HeaderImageDoc(assetName: "legal_1", displayTitle: "Legal Documents – Cover 1"),
        HeaderImageDoc(assetName: "legal_2", displayTitle: "Legal Documents – Cover 2")
    ]

    private let wills: [WillDoc] = [
        WillDoc(assetName: "Will Style A - Mrs Brenda Mary Pound (Master)",
                displayTitle: "Will – Mrs Brenda Mary Pound",
                accent: .purple),
        WillDoc(assetName: "Will Style A - Mr Kieren Matthew Pound (Master)",
                displayTitle: "Will – Mr Kieren Matthew Pound",
                accent: .indigo)
    ]

    private let houseDeeds: [HouseDeedDoc] = [
        HouseDeedDoc(assetName: "PTH11996 - Title sheet",
                     displayTitle: "PTH11996 – Title sheet",
                     accent: .brown),
        HouseDeedDoc(assetName: "PTH11996 - Title Plan",
                     displayTitle: "PTH11996 – Title Plan",
                     accent: .mint),
        HouseDeedDoc(assetName: "PTH30329 - Title sheet",
                     displayTitle: "PTH30329 – Title sheet",
                     accent: .orange),
        HouseDeedDoc(assetName: "PTH30329 - Title Plan (A4 Print Version)",
                     displayTitle: "PTH30329 – Title Plan (A4)",
                     accent: .indigo),
        HouseDeedDoc(assetName: "PTH30329 - Title Plan (A0 Viewing Version)",
                     displayTitle: "PTH30329 – Title Plan (A0)",
                     accent: .teal)
    ]

    private let twoColumnGrid = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    @State private var selectedHouseDeed: HouseDeedDoc?
    @State private var selectedHeaderImage: HeaderImageDoc?
    @State private var selectedWill: WillDoc?

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            headerThumbnailSection
            willsSection
            houseDeedsSection
            songSection
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .sheet(item: $selectedHouseDeed) { doc in
            fullscreenHouseDeedViewer(for: doc)
        }
        .sheet(item: $selectedHeaderImage) { doc in
            fullscreenHeaderImageViewer(for: doc)
        }
        .sheet(item: $selectedWill) { doc in
            fullscreenWillViewer(for: doc)
        }
    }

    // MARK: - Header Thumbnails

    private var headerThumbnailSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Document covers",
                          systemImage: "photo.stack.fill",
                          tint: .blue)

            cardBackground {
                HStack(spacing: 14) {
                    ForEach(headerImages) { doc in
                        Button(action: { selectedHeaderImage = doc }) {
                            Image(doc.assetName)
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .frame(height: 120)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
                                )
                                .overlay(alignment: .topTrailing) {
                                    ZStack {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .frame(width: 24, height: 24)
                                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.primary)
                                    }
                                    .padding(8)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Wills Section

    private var willsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Wills",
                          systemImage: "signature",
                          tint: .purple)

            cardBackground {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Thorntons will have a physical copy.  There will also be a paper copy in the bureau, in the sitting room.  Both of you are the executors")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .top, spacing: 14) {
                        ForEach(wills) { doc in
                            willThumbnail(doc)
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private func willThumbnail(_ doc: WillDoc) -> some View {
        Button(action: { selectedWill = doc }) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(doc.assetName)
                        .resizable()
                        .aspectRatio(1.33, contentMode: .fill)
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(doc.accent.opacity(0.35), lineWidth: 0.5)
                        )

                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 26, height: 26)
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(doc.accent)
                    }
                    .padding(10)
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(doc.displayTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 4) {
                        Image(systemName: "doc.richtext.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Tap to open PDF")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Song Section (YouTube)

    private var songSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Song for the page",
                          systemImage: "music.note.tv.fill",
                          tint: .teal)

            cardBackground {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Don't fight the law!  Do it right and it will be quick and stress free.  Have a nice holiday when you are done")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Color.black
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(14)
                        .overlay {
                            YouTubePlayerView(videoID: "AL8chWFuM-s")
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

    // MARK: - House Deeds Section

    private var houseDeedsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "House Deeds",
                          systemImage: "house.and.flag.fill",
                          tint: .brown)

            cardBackground {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tap any card below to open and read the full Land Registry PDF.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: twoColumnGrid, alignment: .leading, spacing: 14) {
                        ForEach(houseDeeds) { doc in
                            houseDeedThumbnail(doc)
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private func houseDeedThumbnail(_ doc: HouseDeedDoc) -> some View {
        Button(action: { selectedHouseDeed = doc }) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(doc.assetName)
                        .resizable()
                        .aspectRatio(1.33, contentMode: .fill)
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(doc.accent.opacity(0.35), lineWidth: 1.2)
                        )

                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 26, height: 26)
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(doc.accent)
                    }
                    .padding(10)
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(doc.displayTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 4) {
                        Image(systemName: "doc.richtext.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Tap to open PDF")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func fullscreenHouseDeedViewer(for doc: HouseDeedDoc) -> some View {
        if let pdfURL = Bundle.main.url(forResource: doc.assetName, withExtension: "pdf") {
            PDFKitViewerSheet(url: pdfURL, title: doc.displayTitle, onClose: { selectedHouseDeed = nil })
        } else if let fallback = HouseDeedPDFLoader.url(forAssetNamed: doc.assetName) {
            PDFKitViewerSheet(url: fallback, title: doc.displayTitle, onClose: { selectedHouseDeed = nil })
        } else {
            imageFallbackViewer(for: doc)
        }
    }

    private func imageFallbackViewer(for doc: HouseDeedDoc) -> some View {
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
                        selectedHouseDeed = nil
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

    private func fullscreenHeaderImageViewer(for doc: HeaderImageDoc) -> some View {
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
                        selectedHeaderImage = nil
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

    private func fullscreenWillViewer(for doc: WillDoc) -> some View {
        if let pdfURL = Bundle.main.url(forResource: doc.assetName, withExtension: "pdf") {
            AnyView(
                PDFKitViewerSheet(url: pdfURL,
                                  title: doc.displayTitle,
                                  onClose: { selectedWill = nil })
            )
        } else if let fallbackURL = HouseDeedPDFLoader.url(forAssetNamed: doc.assetName) {
            AnyView(
                PDFKitViewerSheet(url: fallbackURL,
                                  title: doc.displayTitle,
                                  onClose: { selectedWill = nil })
            )
        } else {
            AnyView(
                NavigationStack {
                    GeometryReader { geo in
                        ZStack(alignment: .top) {
                            Color.black.ignoresSafeArea()

                            ScrollView([.vertical, .horizontal]) {
                                Image(doc.assetName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: geo.size.width - 32,
                                           maxHeight: geo.size.height - 32)
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
                                selectedWill = nil
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
            )
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

// MARK: - PDFKit Fullscreen Viewer (SwiftUI -> UIKit)

private struct PDFKitViewerSheet: View {
    let url: URL
    let title: String
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                PDFKitViewRepresented(url: url)
                    .ignoresSafeArea(edges: .bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ShareLink(item: url, preview: SharePreview(title, image: Image(systemName: "doc.richtext.fill"))) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onClose) {
                        Label("Close", systemImage: "xmark.circle.fill")
                            .font(.headline)
                            .labelStyle(.titleAndIcon)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule().fill(.quaternary)
                            )
                    }
                }
            }
        }
    }
}

private struct PDFKitViewRepresented: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.usePageViewController(true, withViewOptions: [UIPageViewController.OptionsKey.interPageSpacing: 8])
        pdfView.displaysPageBreaks = true
        pdfView.pageBreakMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        pdfView.backgroundColor = .systemGroupedBackground
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// MARK: - House Deed PDF Locator (bundle or asset catalog fallback paths)

private enum HouseDeedPDFLoader {
    static func url(forAssetNamed name: String) -> URL? {
        if let loose = Bundle.main.url(forResource: name, withExtension: "pdf") {
            return loose
        }
        let resourceRoot = Bundle.main.resourceURL ?? URL(fileURLWithPath: "")
        let candidates = [
            resourceRoot.appendingPathComponent("\(name).pdf"),
            resourceRoot.appendingPathComponent("Assets.car"),
            resourceRoot.appendingPathComponent("\(name).imageset/\(name).pdf")
        ]
        for url in candidates {
            if FileManager.default.fileExists(atPath: url.path), url.pathExtension.lowercased() == "pdf" {
                return url
            }
        }
        return nil
    }
}
