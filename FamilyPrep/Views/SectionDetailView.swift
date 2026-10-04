import SwiftUI

@MainActor
struct SectionDetailView: View {
    @EnvironmentObject private var repository: LocalDataRepository
    let section: PrepSection
    @State private var newChecklistText: String = ""
    @State private var editingYouTubeURL: String = ""
    @FocusState private var isNotesFocused: Bool

    private var videoID: String {
        YouTubePlayerView.extractVideoID(from: section.youtubeURL) ?? ""
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                headerSection
                if section.title == "What to Do First" || section.title == "Legal Documents" || section.title == "Who to Notify" {
                    richMediaDashboardSection
                }
                notesSection
                youtubeSection
                checklistSection
                attachmentsSection
                footerSection
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 32)
        }
        .contentMargins(.top, 8, for: .scrollContent)
        .contentMargins(.horizontal, 36, for: .scrollContent)
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            editingYouTubeURL = section.youtubeURL
        }
        .onDisappear {
            saveNotesIfNeeded()
            saveYouTubeURLIfNeeded()
        }
    }

    private var richMediaDashboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            if section.title == "Legal Documents" {
                LegalDocumentsDashboardView()
            } else if section.title == "Who to Notify" {
                WhoToNotifyView()
            } else {
                WhatToDoFirstDashboardView()
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

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Label("\(section.checklistItems.filter { $0.isCompleted }.count)/\(section.checklistItems.count)",
                      systemImage: "checklist")
                if section.isStandard {
                    Label("Standard", systemImage: "star.fill")
                        .foregroundStyle(.yellow)
                }
                Spacer()
                Text(section.updatedAt, format: .dateTime.day().month().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Notes", systemImage: "note.text")
                .font(.title3.bold())

            ZStack(alignment: .topLeading) {
                if section.notes.isEmpty && !isNotesFocused {
                    Text("Type notes, instructions, or important details here...")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 14)
                        .padding(.leading, 14)
                        .allowsHitTesting(false)
                }
                TextEditor(text: Binding(
                    get: { section.notes },
                    set: { newValue in
                        section.notes = newValue
                        throttleSaveSection()
                    }
                ))
                    .focused($isNotesFocused)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 140)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    )
            }
        }
    }

    private var youtubeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("YouTube Video", systemImage: "play.tv.fill")
                .font(.title3.bold())

            HStack(spacing: 8) {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)
                TextField("Paste YouTube URL here...", text: $editingYouTubeURL)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        saveYouTubeURLIfNeeded()
                    }
                if !editingYouTubeURL.isEmpty {
                    Button(role: .destructive, action: {
                        editingYouTubeURL = ""
                        section.youtubeURL = ""
                        Task { try? await repository.updateSection(section) }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .padding(.leading, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )

            if !editingYouTubeURL.isEmpty && videoID.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Invalid YouTube URL. Try a format like https://youtu.be/dQw4w9WgXcQ")
                }
                .font(.caption)
                .foregroundStyle(.orange)
            }

            Color.black
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 200)
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(14)
                .clipped()
                .padding(.horizontal, 10)
                .overlay {
                    YouTubePlayerView(videoID: videoID)
                        .cornerRadius(14)
                        .padding(.horizontal, 10)
                        .clipped()
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.separator), lineWidth: 0.5)
                        .padding(.horizontal, 10)
                )
        }
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Checklist", systemImage: "checklist.checked")
                    .font(.title3.bold())
                Spacer()
                Text("\(completedCount)/\(section.checklistItems.count)")
                    .font(.caption).monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 6)

            VStack(spacing: 8) {
                ForEach(section.checklistItems.sorted(by: { $0.orderIndex < $1.orderIndex })) { item in
                    checklistRow(for: item)
                        .padding(.leading, 8)
                }

                HStack(spacing: 10) {
                    TextField("Add a new item...", text: $newChecklistText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addChecklistItem() }
                    Button(action: addChecklistItem) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.tint)
                    }
                    .disabled(newChecklistText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.leading, 8)
            }
        }
    }

    private var completedCount: Int {
        section.checklistItems.filter { $0.isCompleted }.count
    }

    private func checklistRow(for item: ChecklistItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: {
                let newState = !item.isCompleted
                item.isCompleted = newState
                Task {
                    do {
                        try await repository.setChecklistItem(item, isCompleted: newState)
                    } catch {
                        await MainActor.run { item.isCompleted = !newState }
                    }
                }
            }) {
                Image(systemName: item.isCompleted
                      ? "checkmark.circle.fill"
                      : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
                    .frame(width: 28, height: 28, alignment: .center)
                    .padding(.leading, 4)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 36, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                TextField("Item", text: Binding(
                    get: { item.text },
                    set: { item.text = $0 }
                ))
                    .font(.body)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .strikethrough(item.isCompleted, color: .secondary)
                    .onSubmit {
                        Task { try? await repository.updateSection(section) }
                    }
                    .onChange(of: item.text) { _, _ in
                        throttleSaveSection()
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                Button(role: .destructive, action: {
                    let snapshot = item
                    section.checklistItems.removeAll { $0.id == snapshot.id }
                    Task {
                        do {
                            try await repository.deleteChecklistItem(snapshot, from: section)
                        } catch {
                            await MainActor.run {
                                if !section.checklistItems.contains(where: { $0.id == snapshot.id }) {
                                    section.checklistItems.append(snapshot)
                                }
                            }
                        }
                    }
                }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(minWidth: 30, alignment: .trailing)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            let newState = !item.isCompleted
            item.isCompleted = newState
            Task {
                do {
                    try await repository.setChecklistItem(item, isCompleted: newState)
                } catch {
                    await MainActor.run { item.isCompleted = !newState }
                }
            }
        }
        .padding(12)
        .padding(.leading, 4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func addChecklistItem() {
        let text = newChecklistText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let nextOrder = (section.checklistItems.map { $0.orderIndex }.max() ?? -1) + 1
        let newItem = ChecklistItem(text: text, isCompleted: false, orderIndex: nextOrder)
        section.checklistItems.append(newItem)
        let snapshot = newItem
        newChecklistText = ""
        Task {
            do {
                try await repository.addChecklistItem(to: section, text: text)
            } catch {
                await MainActor.run {
                    section.checklistItems.removeAll { $0.id == snapshot.id }
                    repository.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            AttachmentsView(section: section)
        }
    }

    private var footerSection: some View {
        VStack(spacing: 6) {
            Text("All data stored locally. When Firebase is configured,")
            + Text(" changes sync instantly across iOS and Android.")
        }
        .font(.caption)
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
        .padding(.top, 16)
    }

    @State private var saveTask: Task<Void, Never>?

    private func throttleSaveSection() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            Task {
                try? await repository.updateSection(section)
            }
        }
    }

    private func saveNotesIfNeeded() {
        if !section.notes.isEmpty {
            Task { try? await repository.updateSection(section) }
        }
    }

    private func saveYouTubeURLIfNeeded() {
        if editingYouTubeURL != section.youtubeURL {
            section.youtubeURL = editingYouTubeURL.trimmingCharacters(in: .whitespacesAndNewlines)
            Task { try? await repository.updateSection(section) }
        }
    }
}

#Preview {
    final class PreviewBox: @unchecked Sendable {
        @MainActor
        static func make() -> some View {
            let repo = LocalDataRepository()
            let sample = PrepSection(title: "Sample Section", orderIndex: 0, isStandard: true, notes: "Sample notes content here with multiple lines to show the editor.", youtubeURL: "")
            sample.checklistItems.append(ChecklistItem(text: "Do this thing", isCompleted: true, orderIndex: 0))
            sample.checklistItems.append(ChecklistItem(text: "Then do this other very important step that is long", isCompleted: false, orderIndex: 1))
            return NavigationStack {
                SectionDetailView(section: sample)
                    .environmentObject(repo)
            }
        }
    }
    return PreviewBox.make()
}
