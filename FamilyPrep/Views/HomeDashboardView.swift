import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject private var repository: LocalDataRepository
    @State private var showAddSheet = false
    @State private var newSectionTitle = ""

    private let sectionIcons: [String: String] = [
        "What to Do First": "flag.fill",
        "Legal Documents": "doc.text.fill",
        "Who to Notify": "person.2.fill",
        "Running the Houses": "house.fill",
        "Funeral Arrangements": "leaf.fill",
        "Cars": "car.fill",
        "Confirmation": "checkmark.seal.fill"
    ]

    private let sectionColors: [String: Color] = [
        "What to Do First": .red,
        "Legal Documents": .blue,
        "Who to Notify": .green,
        "Running the Houses": .orange,
        "Funeral Arrangements": .purple,
        "Cars": .indigo,
        "Confirmation": .teal
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                if repository.isLoading {
                    ProgressView("Loading sections...")
                } else if repository.sections.isEmpty {
                    ContentUnavailableView(
                        "No Sections Yet",
                        systemImage: "list.dash",
                        description: Text("Tap + to add your first section.")
                    )
                } else {
                    sectionsList
                }
            }
            .navigationTitle("Family Prep")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus")
                            .font(.title3.bold())
                            .frame(width: 36, height: 36)
                            .background(
                                Circle().fill(Color.accentColor)
                            )
                            .foregroundStyle(.white)
                    }
                    .sheet(isPresented: $showAddSheet) {
                        AddSectionSheet(
                            isPresented: $showAddSheet,
                            onSave: { title in
                                Task {
                                    try? await repository.addSection(title: title)
                                }
                            }
                        )
                    }
                }
            }
            .task {
                try? await repository.loadSections()
            }
        }
    }

    private var sectionsList: some View {
        List {
            ForEach(repository.sections) { section in
                NavigationLink(destination: SectionDetailView(section: section)) {
                    SectionRowView(
                        section: section,
                        icon: icon(for: section),
                        color: color(for: section)
                    )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteStandardSections)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .refreshable {
            try? await repository.loadSections()
        }
    }

    private func icon(for section: PrepSection) -> String {
        section.isStandard
            ? (sectionIcons[section.title] ?? "folder.fill")
            : "folder.fill"
    }

    private func color(for section: PrepSection) -> Color {
        section.isStandard
            ? (sectionColors[section.title] ?? .blue)
            : .secondary
    }

    private func deleteStandardSections(at offsets: IndexSet) {
        for offset in offsets {
            let section = repository.sections[offset]
            guard !section.isStandard else { continue }
            Task {
                try? await repository.deleteSection(section)
            }
        }
    }
}

struct SectionRowView: View {
    let section: PrepSection
    let icon: String
    let color: Color

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(section.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                progressBadge
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var progressBadge: some View {
        let total = section.checklistItems.count
        if total == 0 {
            HStack(spacing: 4) {
                Image(systemName: "paperclip")
                    .font(.caption2)
                Text("\(section.attachments.count) attachments")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        } else {
            let completed = section.checklistItems.filter { $0.isCompleted }.count
            let progress = total == 0 ? 0 : Double(completed) / Double(total)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: completed == total ? "checkmark.circle.fill" : "checklist")
                        .font(.caption2)
                    Text("\(completed)/\(total)")
                        .font(.caption).monospacedDigit()
                }
                .foregroundStyle(progress == 1 ? Color.green : .secondary)
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(progress == 1 ? .green : color)
                    .frame(maxWidth: 180)
            }
        }
    }
}

struct AddSectionSheet: View {
    @Binding var isPresented: Bool
    let onSave: (String) -> Void
    @State private var title: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("New Custom Section"),
                        footer: Text("Sections sync instantly across devices when Firebase is configured.")) {
                    TextField("Section name (e.g. Motorhome)", text: $title)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)
                }
            }
            .navigationTitle("Add Section")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed)
                        isPresented = false
                    }
                    .bold()
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    let repo = LocalDataRepository()
    return HomeDashboardView()
        .environmentObject(repo)
}
