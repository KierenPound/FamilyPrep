import SwiftUI
import WebKit

struct CarsDashboardView: View {

    private struct CarPhotoDoc: Identifiable, Hashable {
        let id = UUID()
        let assetName: String
        let displayTitle: String
        let accent: Color
    }

    private let carPhotos: [CarPhotoDoc] = [
        CarPhotoDoc(assetName: "cars_1",
                    displayTitle: "Vehicle photograph",
                    accent: .orange)
    ]

    @State private var selectedCarPhoto: CarPhotoDoc?

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            photosSection
            dvlaSection
            songSection
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .sheet(item: $selectedCarPhoto) { doc in
            fullscreenCarPhotoViewer(for: doc)
        }
    }

    // MARK: - Photos Section

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Photos",
                          systemImage: "photo.stack.fill",
                          tint: .orange)

            cardBackground {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(carPhotos) { doc in
                        photoThumbnail(doc)
                    }
                }
                .padding(16)
            }
        }
    }

    private func photoThumbnail(_ doc: CarPhotoDoc) -> some View {
        Button(action: {
            selectedCarPhoto = doc
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

    // MARK: - DVLA Vehicle Transfer & Insurance Rules

    private var dvlaSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Vehicle Transfer & Insurance Rules (DVLA)",
                          systemImage: "exclamationmark.shield.fill",
                          tint: .red)

            cardBackground {
                VStack(alignment: .leading, spacing: 22) {
                    // Intro paragraphs
                    introParagraphs

                    // Info callout: V5 in black folder
                    infoCallout(
                        icon: "info.circle.fill",
                        tint: .blue,
                        text: "The physical V5 documents are in the black folder in the sitting room."
                    )

                    Divider()

                    // Section: Important Insurance Rules
                    subSectionHeader(title: "Important Insurance Rules",
                                     systemImage: "exclamationmark.triangle.fill",
                                     tint: .red)

                    VStack(alignment: .leading, spacing: 12) {
                        insuranceRuleBullet(
                            title: "Named Drivers are NOT Covered:",
                            text: "Even if you are listed as a named driver on my car insurance policy, your cover becomes instantly invalid the moment we shuffle off this mortal coil."
                        )
                        insuranceRuleBullet(
                            title: "Do Not Drive the Car:",
                            text: "The car must be left parked safely on private land (a driveway or garage). Do not drive it on a public road until you have explicitly called the car insurance provider to arrange \"Executor Cover\", a temporary policy (via apps like Cuvva), or a brand-new policy in your own name. Driving it under the old policy is illegal and means you are driving uninsured."
                        )
                    }

                    Divider()

                    // Section: How to Transfer Ownership (Post)
                    subSectionHeader(title: "How to Transfer Ownership (via Post)",
                                     systemImage: "envelope.fill",
                                     tint: .indigo)

                    // KEEP the car flow
                    VStack(alignment: .leading, spacing: 12) {
                        subHeaderChip(title: "If you are KEEPING the Car:",
                                  systemImage: "car.fill",
                                  tint: .green)

                        keepCarStep(number: 1,
                                   title: "Fill out details:",
                                   text: "Fill out the \"new keeper\" details section in the physical V5C Logbook with your name and address.")

                        keepCarStep(number: 2,
                                   title: "Keep green slip:",
                                   text: "Tear off the green \"new keeper\" slip (Section 2) and keep it. You must use this slip to tax the vehicle in your name immediately online, as the old road tax cancels automatically.")

                        keepCarStep(number: 3,
                                   title: "Write a cover letter:",
                                   text: "Write a brief covering letter to the DVLA explaining your relationship to me, the date I expired, and who should receive any road tax refund.")

                        keepCarStep(number: 4,
                                   title: "Send to DVLA:",
                                   text: "Post the main part of the V5C Logbook and your covering letter to:",
                                   trailingBlock: """
Sensitive Casework Team
DVLA
Swansea
SA99 1ZZ
""")
                    }

                    Divider()

                    // SELL the car flow
                    VStack(alignment: .leading, spacing: 12) {
                        subHeaderChip(title: "If you are SELLING the Car:",
                                  systemImage: "banknote.fill",
                                  tint: .red)

                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(.red)
                                .font(.footnote.weight(.semibold))
                                .frame(width: 22, height: 22, alignment: .center)
                            Text("Follow the exact same steps as above, but fill out the V5C Logbook with the buyer's details, hand them the green slip so they can tax it, and mail the rest of the logbook with your covering letter to the DVLA Sensitive Casework Team.")
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: DVLA sub helpers

    private var introParagraphs: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("A motor vehicle is a personal possession. You do not have to wait for Confirmation to transfer or sell any of the cars.")
                .font(.body)
                .foregroundStyle(.primary)
            Text("However, there are strict legal rules regarding insurance and the logbook.")
                .font(.body)
                .foregroundStyle(.primary)
        }
    }

    private func infoCallout(icon: String, tint: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.headline)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.25), lineWidth: 0.6)
        )
    }

    private func subSectionHeader(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.opacity(0.18))
                    .frame(width: 28, height: 28)
                Image(systemName: systemImage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }

    private func subHeaderChip(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.18))
                    .frame(width: 28, height: 28)
                Image(systemName: systemImage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
        }
    }

    private func insuranceRuleBullet(title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.footnote.weight(.semibold))
                .frame(width: 22, height: 22, alignment: .center)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func keepCarStep(number: Int, title: String, text: String, trailingBlock: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.18))
                    .frame(width: 26, height: 26)
                Text("\(number)")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.green)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
                if let block = trailingBlock {
                    Text(block)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.indigo.opacity(0.10))
                        )
                        .padding(.top, 4)
                }
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
                    Text("One for the road — press play and sing along while sorting all the car stuff. You've got this!")
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

                        YouTubePlayerView(videoID: "rbgiJu7YFvo")
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

    private func fullscreenCarPhotoViewer(for doc: CarPhotoDoc) -> some View {
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
                        selectedCarPhoto = nil
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
        CarsDashboardView()
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
    }
    .background(Color(.systemGroupedBackground))
}
