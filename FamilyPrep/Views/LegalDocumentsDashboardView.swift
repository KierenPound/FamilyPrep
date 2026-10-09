import SwiftUI
import WebKit
import PDFKit

struct LegalDocumentsDashboardView: View {

    private struct LegalPhotoDoc: Identifiable, Hashable {
        let id = UUID()
        let assetName: String
        let displayTitle: String
        let accent: Color
    }

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

    private let legalPhotos: [LegalPhotoDoc] = [
        LegalPhotoDoc(assetName: "gemini_legal_800",
                      displayTitle: "Family photograph",
                      accent: .blue)
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
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    @State private var selectedHouseDeed: HouseDeedDoc?
    @State private var selectedWill: WillDoc?
    @State private var selectedLegalPhoto: LegalPhotoDoc?

    @State private var willsCardWidth: CGFloat = 320
    @State private var deedsCardWidth: CGFloat = 320

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            photosSection
            willsSection
            houseDeedsSection
            songSection
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
        .sheet(item: $selectedHouseDeed) { doc in
            fullscreenHouseDeedViewer(for: doc)
        }
        .sheet(item: $selectedWill) { doc in
            fullscreenWillViewer(for: doc)
        }
        .sheet(item: $selectedLegalPhoto) { doc in
            fullscreenLegalPhotoViewer(for: doc)
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
                    ForEach(legalPhotos) { doc in
                        photoThumbnail(doc)
                    }
                }
                .padding(16)
            }
        }
    }

    private func photoThumbnail(_ doc: LegalPhotoDoc) -> some View {
        Button(action: {
            selectedLegalPhoto = doc
        }) {
            ZStack(alignment: .bottomTrailing) {
                Image(doc.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, alignment: .center)
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

    // MARK: - Wills Section

    private var willsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Wills",
                          systemImage: "signature",
                          tint: .purple)

            cardBackground {
                let tileSide = max(60, (willsCardWidth - 32 - 12) / 2)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Thorntons hold the master document. There will be paper copies in the bureau, in the sitting room.  Both of you are the executors")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)

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
                        .fixedSize(horizontal: false, vertical: true)

                        HStack(alignment: .top, spacing: 12) {
                            ForEach(wills) { doc in
                                willThumbnail(doc, tileSide: tileSide)
                                    .frame(width: tileSide)
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { willsCardWidth = geo.size.width }
                            .onChange(of: geo.size.width) { _, newValue in willsCardWidth = newValue }
                    }
                )
            }
        }
    }

    private func willThumbnail(_ doc: WillDoc, tileSide: CGFloat) -> some View {
        Button(action: {
            selectedWill = doc
        }) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Color(.quaternarySystemFill)
                    if let pdfURL = PDFLoader.url(for: doc.assetName),
                       let pdfDoc = PDFDocument(url: pdfURL),
                       let page = pdfDoc.page(at: 0) {
                        let thumb = page.thumbnail(
                            of: CGSize(width: tileSide * 3, height: tileSide * 3),
                            for: .cropBox
                        )
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "doc.richtext.fill")
                                .font(.system(size: 44, weight: .light))
                                .foregroundStyle(doc.accent)
                            Text("Loading…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: tileSide, height: tileSide)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(doc.accent.opacity(0.45), lineWidth: 0.7)
                )
                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(doc.displayTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2, reservesSpace: false)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        Image(systemName: "doc.richtext")
                            .font(.system(size: 11))
                        Text("Tap to open PDF")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(doc.accent)
                }
            }
            .frame(width: tileSide, alignment: .leading)
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
                let tileSide = max(60, (deedsCardWidth - 32 - 12) / 2)
                VStack(alignment: .leading, spacing: 14) {
                    Text("Below are the official title sheets and plans from Scotland Land Information Service")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text("Tap any card below to open and read the full Land Registry PDF.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            if houseDeeds.indices.contains(0) {
                                houseDeedThumbnail(houseDeeds[0], tileSide: tileSide)
                                    .frame(width: tileSide)
                            }
                            if houseDeeds.indices.contains(1) {
                                houseDeedThumbnail(houseDeeds[1], tileSide: tileSide)
                                    .frame(width: tileSide)
                            }
                        }
                        HStack(alignment: .top, spacing: 12) {
                            if houseDeeds.indices.contains(2) {
                                houseDeedThumbnail(houseDeeds[2], tileSide: tileSide)
                                    .frame(width: tileSide)
                            }
                            if houseDeeds.indices.contains(3) {
                                houseDeedThumbnail(houseDeeds[3], tileSide: tileSide)
                                    .frame(width: tileSide)
                            }
                        }
                        HStack(alignment: .top, spacing: 12) {
                            if houseDeeds.indices.contains(4) {
                                houseDeedThumbnail(houseDeeds[4], tileSide: tileSide)
                                    .frame(width: tileSide)
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear { deedsCardWidth = geo.size.width }
                            .onChange(of: geo.size.width) { _, newValue in deedsCardWidth = newValue }
                    }
                )
            }
        }
    }

    private func houseDeedThumbnail(_ doc: HouseDeedDoc, tileSide: CGFloat) -> some View {
        Button(action: {
            selectedHouseDeed = doc
        }) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Color(.quaternarySystemFill)
                    if let pdfURL = PDFLoader.url(for: doc.assetName),
                       let pdfDoc = PDFDocument(url: pdfURL),
                       let page = pdfDoc.page(at: 0) {
                        let thumb = page.thumbnail(
                            of: CGSize(width: tileSide * 3, height: tileSide * 3),
                            for: .cropBox
                        )
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "doc.richtext.fill")
                                .font(.system(size: 44, weight: .light))
                                .foregroundStyle(doc.accent)
                            Text("Loading…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: tileSide, height: tileSide)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(doc.accent.opacity(0.45), lineWidth: 0.7)
                )
                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(doc.displayTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2, reservesSpace: false)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        Image(systemName: "doc.richtext")
                            .font(.system(size: 11))
                        Text("Tap to open PDF")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(doc.accent)
                }
            }
            .frame(width: tileSide, alignment: .leading)
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

    // MARK: - Fullscreen viewers

    @ViewBuilder
    private func fullscreenHouseDeedViewer(for doc: HouseDeedDoc) -> some View {
        if let pdfURL = PDFLoader.url(for: doc.assetName) {
            PDFKitViewerSheet(url: pdfURL, title: doc.displayTitle, onClose: { selectedHouseDeed = nil })
        } else {
            // No PDF embedded in the bundle for this deed; fall back to the
            // same image asset that the thumbnail uses so the user sees a
            // large, zoomable view of the content regardless.
            imageFallbackViewer(for: doc)
        }
    }

    private func imageFallbackViewer(for doc: HouseDeedDoc) -> some View {
        NavigationStack {
            GeometryReader { geo in
                let viewportW = max(320, min(geo.size.width.isFinite ? geo.size.width : 0, 3840))
                let viewportH = max(320, min(geo.size.height.isFinite ? geo.size.height : 0, 2160))
                ZStack {
                    // Paper-white neutral background matches PDF look; fills safe area
                    Color(.secondarySystemBackground).ignoresSafeArea()

                    // Single axis (vertical) scroll + fit width = the classic
                    // document scroll behavior. A landscape 4:3 Title Plan fills
                    // 100% of screen WIDTH (no black void), and the user just
                    // scrolls down if needed for legend.
                    ScrollView(.vertical, showsIndicators: true) {
                        Image(doc.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: viewportW)
                            .frame(width: viewportW)
                            .padding(.vertical, 8)
                    }
                    .frame(width: viewportW, height: viewportH)
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
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Close")
                                .font(.subheadline.bold())
                        }
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
        if let pdfURL = PDFLoader.url(for: doc.assetName) {
            return AnyView(
                PDFKitViewerSheet(url: pdfURL,
                                  title: doc.displayTitle,
                                  onClose: { selectedWill = nil })
            )
        } else {
            return AnyView(
                NavigationStack {
                    GeometryReader { geo in
                        let viewportW = max(320, min(geo.size.width.isFinite ? geo.size.width : 0, 3840))
                        let viewportH = max(320, min(geo.size.height.isFinite ? geo.size.height : 0, 2160))
                        ZStack {
                            Color(.secondarySystemBackground).ignoresSafeArea()

                            ScrollView(.vertical, showsIndicators: true) {
                                Image(doc.assetName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: viewportW)
                                    .frame(width: viewportW)
                                    .padding(.vertical, 8)
                            }
                            .frame(width: viewportW, height: viewportH)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text(doc.displayTitle)
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                selectedWill = nil
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark.circle.fill")
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(.secondary)
                                    Text("Close")
                                        .font(.subheadline.bold())
                                }
                                .foregroundStyle(.primary)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule().fill(.quaternary)
                                )
                            }
                        }
                    }
                    .toolbarBackground(.visible, for: .navigationBar)
                }
            )
        }
    }

    private func fullscreenLegalPhotoViewer(for doc: LegalPhotoDoc) -> some View {
        NavigationStack {
            GeometryReader { geo in
                let viewportW = max(320, min(geo.size.width.isFinite ? geo.size.width : 0, 3840))
                let viewportH = max(320, min(geo.size.height.isFinite ? geo.size.height : 0, 2160))
                ZStack {
                    Color(.secondarySystemBackground).ignoresSafeArea()

                    ScrollView(.vertical, showsIndicators: true) {
                        Image(doc.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: viewportW)
                            .frame(width: viewportW)
                            .padding(.vertical, 8)
                    }
                    .frame(width: viewportW, height: viewportH)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(doc.displayTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedLegalPhoto = nil
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.secondary)
                            Text("Close")
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(.primary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule().fill(.quaternary)
                        )
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
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

// MARK: - PDF Locator — robustly finds PDFs ANYWHERE inside the app,
// including loose bundle files, PDFs embedded in xcassets as Data Sets
// (read via NSDataAsset then written to a temp file URL), and PDFs
// dragged into the project folder hierarchy.

private enum PDFLoader {

    private static var catalogDumped = false

    static func url(for assetName: String) -> URL? {
        dumpAssetCatalogOnceIfNeeded()

        let normalized = normalize(assetName)

        // 1) Loose bundle PDFs via url(forResource)
        if let loose = Bundle.main.url(forResource: assetName, withExtension: "pdf") {
            print("📄🟢 [1/loose] matched '\(assetName)' → \(loose.lastPathComponent)")
            return loose
        }
        if let looseNoExt = Bundle.main.url(forResource: assetName, withExtension: nil),
           looseNoExt.pathExtension.lowercased() == "pdf" {
            print("📄🟢 [1b/loose no-ext] '\(assetName)' → \(looseNoExt.lastPathComponent)")
            return looseNoExt
        }

        // 2) NSDataAsset — for when PDFs are Data-Set assets inside Assets.xcassets
        //    compiled into Assets.car.
        let snakeName = assetName.replacingOccurrences(of: " ", with: "_")
        let dashCompactName = assetName.replacingOccurrences(of: " - ", with: "-")
        let dataAssetVariants: [String] = [
            assetName, "\(assetName).pdf", snakeName, "\(snakeName).pdf",
            dashCompactName, "\(dashCompactName).pdf",
            assetName.lowercased(), "\(assetName.lowercased()).pdf",
            assetName.replacingOccurrences(of: "–", with: "-"),
            assetName.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
        ]
        for candidate in dataAssetVariants {
            if let dataAsset = NSDataAsset(name: candidate) {
                if let url = writeAssetDataToTempCache(data: dataAsset.data, assetName: assetName) {
                    print("📄🟢 [2/NSDataAsset] matched '\(candidate)' → temp \(url.lastPathComponent)")
                    return url
                }
            }
        }

        // 2.5) UIImage + PDF renderer — for PDFs stored as .imageset (vector PDF
        //      inside Assets.car imageset). NSDataAsset can't see these, but
        //      UIImage(named:) renders them perfectly. We re-rasterize the
        //      loaded image into a new PDF document so the full PDFKit viewer
        //      (pinch-zoom, page swipe, etc.) is still used instead of the
        //      image-only fallback viewer.
        if let uiImage = UIImage(named: assetName) {
            let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: uiImage.size))
            let pdfData = renderer.pdfData { context in
                context.beginPage()
                uiImage.draw(in: CGRect(origin: .zero, size: uiImage.size))
            }
            if let url = writeAssetDataToTempCache(data: pdfData, assetName: assetName) {
                print("📄🟢 [2.5/imageset→PDF] '\(assetName)' loaded from imageset and rendered to PDFKit-compatible data")
                return url
            }
        }

        // 3) Deep-file-deep: recurse every file in bundle.
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        let fm = FileManager.default
        let enumerator = fm.enumerator(
            at: resourceURL,
            includingPropertiesForKeys: [.isRegularFileKey, .nameKey],
            options: [.skipsHiddenFiles]
        )

        var fuzzyCandidates: [URL] = []
        while let url = enumerator?.nextObject() as? URL {
            let rv = try? url.resourceValues(forKeys: [.isRegularFileKey])
            guard rv?.isRegularFile == true else { continue }
            guard url.pathExtension.lowercased() == "pdf" else { continue }
            let fname = url.deletingPathExtension().lastPathComponent
            if fname.lowercased() == assetName.lowercased() { print("📄🟢 [3/deep exact]: '\(assetName)' → \(url.lastPathComponent)"); return url }
            if normalize(fname) == normalized { print("📄🟢 [3/deep norm]: '\(assetName)' → \(url.lastPathComponent)"); return url }
            fuzzyCandidates.append(url)
        }

        // 4) Fuzzy contains
        for url in fuzzyCandidates {
            let nFname = normalize(url.deletingPathExtension().lastPathComponent)
            if nFname.contains(normalized) || normalized.contains(nFname) {
                print("📄🟢 [4/fuzzy]: '\(assetName)' → \(url.lastPathComponent)")
                return url
            }
        }

        print("📄🔴 ALL PDF FALLBACK (image viewer): '\(assetName)' — no PDF found in bundle or Assets. "
              + "See discovered names above in '💼 AssetCatalog dump'.")
        return nil
    }

    // MARK: - Helpers

    /// Called once per app launch. Walks the bundle and prints
    /// all PDFs discovered + tries NSDataAsset name attempts so we can
    /// see what the actual Assets.car catalog naming is.
    private static func dumpAssetCatalogOnceIfNeeded() {
        guard !catalogDumped else { return }
        catalogDumped = true

        print("\n💼 PDFLoader — AssetCatalog Dump {")
        defer { print("}\n") }

        // --- 1) Loose PDFs anywhere in the bundle:
        var pdfList: [URL] = []
        if let r = Bundle.main.resourceURL,
           let enumerator = FileManager.default.enumerator(
               at: r,
               includingPropertiesForKeys: [.isRegularFileKey, .nameKey],
               options: [.skipsHiddenFiles]
           ) {
            while let u = enumerator.nextObject() as? URL {
                guard (try? u.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { continue }
                if u.pathExtension.lowercased() == "pdf" { pdfList.append(u) }
            }
        }
        print("  📁 loose PDFs found = \(pdfList.count):")
        for u in pdfList { print("     · \(u.lastPathComponent)") }
        if pdfList.isEmpty { print("     (none)") }

        // 2) Try the ACTUAL asset names used in the model data (exact names
        //    that live inside the .imageset folders in Assets.xcassets):
        let testNames = [
            "PTH11996 - Title sheet",
            "PTH11996 - Title Plan",
            "PTH30329 - Title sheet",
            "PTH30329 - Title Plan (A4 Print Version)",
            "PTH30329 - Title Plan (A0 Viewing Version)",
            "Will Style A - Mrs Brenda Mary Pound (Master)",
            "Will Style A - Mr Kieren Matthew Pound (Master)"
        ]
        let tryVariants: (String) -> [String] = { name in
            [name, "\(name).pdf",
             name.replacingOccurrences(of: " ", with: "_"),
             name.lowercased()]
        }
        print("  🔎 NSDataAsset name attempts (matches only):")
        var foundAnyDataAsset = false
        for n in testNames {
            for v in tryVariants(n) {
                if NSDataAsset(name: v) != nil {
                    print("    ✅ '\(v)' EXISTS")
                    foundAnyDataAsset = true
                }
            }
        }
        if !foundAnyDataAsset { print("    (none — PDFs are stored as .imageset, not .dataset; expected)") }

        // 3) UIImage probes — these match .imageset assets (which is how all
        //    current PDFs are stored). Confirms the Tier 2.5 imageset→PDF
        //    pipeline will succeed for every listed document.
        print("  🖼️  UIImage (imageset) name attempts:")
        for n in testNames {
            if UIImage(named: n) != nil {
                print("    ✅ '\(n)' — imageset asset OK")
            } else {
                print("    ❌ '\(n)' — NOT FOUND")
            }
        }
    }

    private static func writeAssetDataToTempCache(data: Data, assetName: String) -> URL? {
        let fm = FileManager.default
        do {
            let caches = try fm.url(for: .cachesDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: true)
            let safeName = assetName
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: ":", with: "_")
            let dirURL = caches.appendingPathComponent("FamilyPrep_PDFs", isDirectory: true)
            if !fm.fileExists(atPath: dirURL.path) {
                try fm.createDirectory(at: dirURL, withIntermediateDirectories: true)
            }
            let fileURL = dirURL.appendingPathComponent("\(safeName).pdf")
            if fm.fileExists(atPath: fileURL.path),
               let existing = try? Data(contentsOf: fileURL),
               existing.count == data.count {
                return fileURL
            }
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            print("⚠️ PDFLoader temp-write failed for '\(assetName)': \(error.localizedDescription)")
            return nil
        }
    }

    private static func normalize(_ s: String) -> String {
        var chars: [Character] = []
        for c in s.lowercased() {
            switch c {
            case " ", "-", "_", "–", "—", ".", "(", ")", "[", "]", "{", "}", " ", "/", ":", ";":
                continue
            default:
                chars.append(c)
            }
        }
        return String(chars)
    }
}

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
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Close")
                                .font(.subheadline.bold())
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule().fill(.quaternary)
                        )
                    }
                }
            }
        }
        .onAppear { print("📖 PDF viewer opened: \(url.lastPathComponent)") }
    }
}

private struct PDFKitViewRepresented: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.backgroundColor = .systemGroupedBackground
        pdfView.minScaleFactor = 0.1
        pdfView.maxScaleFactor = 10.0
        pdfView.displayDirection = .horizontal
        pdfView.displaysPageBreaks = true
        pdfView.pageBreakMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        // Page view controller = swipe horizontally between pages like iBooks,
        // and critically: every page (A4 portrait, A0 landscape, anything)
        // auto-fits the screen exactly once on first load — matches the
        // original working PDF viewer behavior before we accidentally broke
        // it with singlePageContinuous vertical mode.
        pdfView.usePageViewController(true, withViewOptions: [
            UIPageViewController.OptionsKey.interPageSpacing: 16
        ])

        if let doc = PDFDocument(url: url) {
            pdfView.document = doc
            print("✅ PDF loaded OK: \(url.lastPathComponent) — pages = \(doc.pageCount)")
        } else {
            // PDFDocument(url:) sometimes rejects valid PDFs that are in
            // temp directories (sandbox path access). Retry with a Data
            // read which bypasses path-based security bookmarks.
            do {
                let data = try Data(contentsOf: url)
                if let doc2 = PDFDocument(data: data) {
                    pdfView.document = doc2
                    print("✅ PDF loaded via Data fallback: \(url.lastPathComponent) — pages = \(doc2.pageCount)")
                } else {
                    print("❌ PDFDocument(url:) + PDFDocument(data:) BOTH returned nil for: \(url.lastPathComponent)")
                }
            } catch {
                print("❌ PDF load failed: \(error.localizedDescription)")
            }
        }
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}

#Preview {
    ScrollView {
        LegalDocumentsDashboardView()
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
    }
    .background(Color(.systemGroupedBackground))
}
