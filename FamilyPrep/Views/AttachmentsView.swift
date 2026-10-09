import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AttachmentsView: View {
    @EnvironmentObject private var repository: LocalDataRepository
    let section: PrepSection
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isImportingPDF = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Attachments", systemImage: "paperclip")
                    .font(.title3.bold())
                Spacer()
                if repository.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            HStack(spacing: 10) {
                PhotosPicker(selection: $selectedPhotoItems,
                             maxSelectionCount: 5,
                             matching: .images,
                             preferredItemEncoding: .compatible) {
                    Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.blue)
                .onChange(of: selectedPhotoItems) { _, newValue in
                    Task {
                        for item in newValue {
                            do {
                                _ = try await repository.uploadPhoto(item, to: section)
                            } catch {
                                repository.errorMessage = error.localizedDescription
                            }
                        }
                        selectedPhotoItems.removeAll()
                    }
                }

                Button(action: { isImportingPDF = true }) {
                    Label("Add PDF / File", systemImage: "doc.fill.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)
                .fileImporter(
                    isPresented: $isImportingPDF,
                    allowedContentTypes: [UTType.pdf, UTType.image, UTType.content],
                    allowsMultipleSelection: true
                ) { result in
                    handleFileImport(result: result)
                }
            }

            if section.attachments.isEmpty {
                ContentUnavailableView(
                    "No Attachments",
                    systemImage: "paperclip.badge.ellipsis",
                    description: Text("Upload photos or PDFs here to store them in Firebase Storage.")
                )
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(section.attachments) { attachment in
                            AttachmentCard(attachment: attachment) {
                                Task {
                                    try? await repository.deleteAttachment(attachment, from: section)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        Task {
            do {
                let urls = try result.get()
                for url in urls {
                    _ = try await repository.uploadFile(at: url, to: section)
                }
            } catch {
                repository.errorMessage = error.localizedDescription
            }
        }
    }
}

struct AttachmentCard: View {
    let attachment: Attachment
    let onDelete: () -> Void
    @State private var showDeleteConfirm = false
    @State private var image: UIImage?

    private var attachmentType: AttachmentType {
        attachment.type
    }

    var body: some View {
        Menu {
            Button(role: .destructive, action: { showDeleteConfirm = true }) {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    thumbnail
                        .frame(width: 140, height: 140)
                        .clipped()
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                    badge
                        .padding(6)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(attachment.fileName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.8)
                        .padding(.trailing, 4)
                    Text(formattedSize)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 140, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .confirmationDialog(
            "Delete attachment?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove the file from storage.")
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        switch attachmentType {
        case .photo:
            if let _ = attachmentDownloadURL, let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else if let url = attachmentDownloadURL {
                Color(.secondarySystemFill)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    )
                    .task { await loadImage(from: url) }
            } else {
                Color(.secondarySystemFill)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    )
            }
        case .pdf:
            Color.orange.opacity(0.15)
                .overlay(
                    Image(systemName: "doc.richtext.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                )
        default:
            Color(.secondarySystemFill)
                .overlay(
                    Image(systemName: "doc.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                )
        }
    }

    @ViewBuilder
    private var badge: some View {
        Image(systemName: attachmentType == .pdf ? "doc.fill" : "photo.fill")
            .font(.caption2).bold()
            .foregroundStyle(.white)
            .padding(5)
            .background(
                Circle().fill(attachmentType == .pdf ? .orange : .blue)
            )
    }

    private var attachmentDownloadURL: URL? {
        URL(string: attachment.downloadURL)
    }

    private var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: attachment.fileSize, countStyle: .file)
    }

    private func loadImage(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = UIImage(data: data) {
                await MainActor.run { self.image = img }
            }
        } catch {
            // ignore
        }
    }
}
