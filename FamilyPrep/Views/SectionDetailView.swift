import SwiftUI

@MainActor
struct SectionDetailView: View {
    @EnvironmentObject private var repository: LocalDataRepository
    @Environment(\.appState) private var appState
    let section: PrepSection
    @State private var newChecklistText: String = ""
    @FocusState private var isNotesFocused: Bool
    @State private var renameChecklistItemId: String?
    @State private var renameChecklistText: String = ""
    @State private var renameChecklistPresented: Bool = false

    private var isOwner: Bool { appState.isOwner }

    var body: some View {
        ZStack {
            PastelEditorialCanvas()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headerSection
                    if section.title == "What to Do First" || section.title == "Legal Documents" || section.title == "Who to Notify" || section.title == "Running the Houses" || section.title == "Cars" || section.title == "Funeral Arrangements" || section.title == "Confirmation" || section.title == "Kieren's Jukebox" {
                        richMediaDashboardSection
                    }
                    notesSection
                    checklistSection
                    attachmentsSection
                    footerSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle(section.title)
            .navigationBarTitleDisplayMode(.large)
        }
        .onDisappear {
            saveNotesIfNeeded()
        }
        .alert(
            "Rename Checklist Item",
            isPresented: $renameChecklistPresented
        ) {
            TextField("New name", text: $renameChecklistText)
            Button("Cancel", role: .cancel) {
                resetRenameChecklistState()
            }
            Button("Save", action: commitRenameChecklistItem)
        } message: {
            Text("Enter the updated name for this checklist item.")
        }
    }

    private var richMediaDashboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            if section.title == "Legal Documents" {
                LegalDocumentsDashboardView()
            } else if section.title == "Who to Notify" {
                WhoToNotifyView()
            } else if section.title == "Running the Houses" {
                RunningTheHousesDashboardView()
            } else if section.title == "Cars" {
                CarsDashboardView()
            } else if section.title == "Funeral Arrangements" {
                FuneralArrangementsDashboardView()
            } else if section.title == "Confirmation" {
                ConfirmationDashboardView()
            } else if section.title == "Kieren's Jukebox" {
                KierensJukeboxDashboardView()
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
            HStack(spacing: 8) {
                Label("Notes", systemImage: "note.text")
                    .font(.title3.bold())
                if !isOwner {
                    Text("Read-only")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.14))
                        )
                        .foregroundStyle(.secondary)
                }
            }

            ZStack(alignment: .topLeading) {
                if section.notes.isEmpty && !isNotesFocused && isOwner {
                    Text("Type notes, instructions, or important details here...")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 14)
                        .padding(.leading, 14)
                        .allowsHitTesting(false)
                }
                TextEditor(text: Binding(
                    get: { section.notes },
                    set: { newValue in
                        guard isOwner else { return }
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
                            .fill(isOwner
                                  ? Color(.secondarySystemGroupedBackground)
                                  : Color(.tertiarySystemGroupedBackground).opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    )
                    .disabled(!isOwner)
                    .allowsHitTesting(isOwner)
            }
        }
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label("Checklist", systemImage: "checklist.checked")
                    .font(.title3.bold())
                if !isOwner {
                    Text("Read-only")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.14))
                        )
                        .foregroundStyle(.secondary)
                }
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

                if isOwner {
                    HStack(spacing: 10) {
                        TextField("Add a new item...", text: $newChecklistText)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 15, weight: .medium))
                            .lineLimit(2)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.85)
                            .fixedSize(horizontal: false, vertical: true)
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
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(item.isCompleted ? .green : .gray)
                    .frame(width: 22, height: 22, alignment: .center)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 26, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .strikethrough(item.isCompleted, color: .secondary.opacity(0.7))
                    .lineLimit(2)
                    .allowsTightening(true)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isOwner {
                Menu {
                    Button(action: {
                        renameChecklistItemId = item.id
                        renameChecklistText = item.text
                        renameChecklistPresented = true
                    }) {
                        Label("Rename", systemImage: "pencil")
                    }

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
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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

    private func resetRenameChecklistState() {
        renameChecklistItemId = nil
        renameChecklistText = ""
        renameChecklistPresented = false
    }

    private func commitRenameChecklistItem() {
        guard let targetId = renameChecklistItemId,
              let target = section.checklistItems.first(where: { $0.id == targetId }) else {
            resetRenameChecklistState()
            return
        }
        let updated = renameChecklistText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !updated.isEmpty else {
            resetRenameChecklistState()
            return
        }
        target.text = updated
        Task { try? await repository.updateSection(section) }
        resetRenameChecklistState()
    }

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            AttachmentsView(section: section)
        }
    }

    private var footerSection: some View {
        VStack(spacing: 6) {
            Text("All data stored locally. When Firebase is configured,\nchanges sync instantly across iOS and Android.")
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
