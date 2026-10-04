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

    private struct WillDoc: Identifiable, Hashable {
        let id = UUID()
        let assetName: String
        let displayTitle: String
        let accent: Color
    }

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
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    @State private var selectedHouseDeed: HouseDeedDoc?
    @State private var selectedWill: WillDoc?

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            willsSection
            houseDeedsSection
            songSection
            driveFolderSection
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .sheet(item: $selectedHouseDeed) { doc in
            fullscreenHouseDeedViewer(for: doc)
        }
        .sheet(item: $selectedWill) { doc in
            fullscreenWillViewer(for: doc)
        }
    }

    // MARK: - Wills Section

    private var willsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Wills",
                          systemImage: "signature",
                          tint: .purple)

            cardBackground {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Thorntons hold the master document. There will be paper copiesO in the bureau, in the sitting room.  Both of you are the executors")
                        .font(.body)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Contact Thorntons", systemImage: "building.columns.fill")
                            .font(.headline)
                            .foregroundStyle(.tint)

                        HStack(spacing: 10) {
                            phoneButton(phone: "01738231178",
                                        display: "01738 231178",
                                        systemImage: "phone.fill")

                            emailButton(email: "AHoggan@thorntons-law.co.uk",
                                         systemImage: "envelope.fill")
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Will documents", systemImage: "doc.richtext.fill")
                            .font(.headline)
                            .foregroundStyle(.tint)

                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text("Tap any card below to open and read the full Will PDF.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        HStack(alignment: .top, spacing: 12) {
                            ForEach(wills) { doc in
                                willThumbnail(doc)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private func willThumbnail(_ doc: WillDoc) -> some View {
        Button(action: {
            selectedWill = doc
        }) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .bottomTrailing) {
                    Image(doc.assetName)
                        .resizable()
                        .aspectRatio(1.33, contentMode: .fill)
                        .frame(height: 70)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(doc.accent.opacity(0.35), lineWidth: 0.6)
                        )

                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 22, height: 22)
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(doc.accent)
                    }
                    .padding(6)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.displayTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 3) {
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 10))
                        Text("Tap to open PDF")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(doc.accent)
                }
                .padding(.horizontal, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    // MARK: - House Deeds Section

    private var houseDeedsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "House Deeds",
                          systemImage: "house.and.flag.fill",
                          tint: .brown)

            cardBackground {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Below are the official title sheets and plans from Scotland Land Information Service")
                        .font(.body)

                    Divider()

                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text("Tap any card below to open and read the full Land Registry PDF.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    LazyVGrid(
                        columns: twoColumnGrid,
                        spacing: 12
                    ) {
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
        Button(action: {
            selectedHouseDeed = doc
        }) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .bottomTrailing) {
                    Image(doc.assetName)
                        .resizable()
                        .aspectRatio(1.33, contentMode: .fill)
                        .frame(height: 70)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(doc.accent.opacity(0.35), lineWidth: 0.6)
                        )

                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 22, height: 22)
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(doc.accent)
                    }
                    .padding(6)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.displayTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 3) {
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 10))
                        Text("Tap to open PDF")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(doc.accent)
                }
                .padding(.horizontal, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
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
                        .frame(maxHeight: 200)
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

    // MARK: - Drive Folder

    private var driveFolderSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Related Files",
                          systemImage: "folder.fill",
                          tint: .yellow)

            Link(destination: URL(string: "https://docs.google.com/folderview?authuser=0&id=1mxq_Dc28Rq76dMY69rhufmXoaJG0f5NU")!) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.yellow.opacity(0.18))
                            .frame(width: 48, height: 48)
                        Image(systemName: "folder.fill")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Open Google Drive Folder")
                            .font(.subheadline.weight(.semibold))
                        Text("docs.google.com – Related documents")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
            }
            .foregroundStyle(.primary)
        }
    }

    // MARK: - Fullscreen viewers

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

    private func phoneButton(phone: String, display: String, systemImage: String) -> some View {
        Link(destination: URL(string: "tel:\(phone)")!) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(display)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.green.opacity(0.12))
            )
            .foregroundStyle(.green)
            .overlay(
                Capsule()
                    .stroke(Color.green.opacity(0.25), lineWidth: 1)
            )
        }
    }

    private func emailButton(email: String, systemImage: String) -> some View {
        Link(destination: URL(string: "mailto:\(email)")!) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(email)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.12))
            )
            .foregroundStyle(.blue)
            .overlay(
                Capsule()
                    .stroke(Color.blue.opacity(0.25), lineWidth: 1)
            )
        }
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

#Preview {
    ScrollView {
        LegalDocumentsDashboardView()
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
    }
    .background(Color(.systemGroupedBackground))
}
