import SwiftUI
import WebKit

struct WhatToDoFirstDashboardView: View {

    private struct CertificateDoc: Identifiable, Hashable {
        let id = UUID()
        let assetName: String
        let displayTitle: String
        let accent: Color
    }

    private let certificates: [CertificateDoc] = [
        CertificateDoc(assetName: "Kieren_birth_certificate",
                       displayTitle: "Kieren birth certificate",
                       accent: .indigo),
        CertificateDoc(assetName: "Bren_birth_certificate",
                       displayTitle: "Brenda birth certificate",
                       accent: .pink),
        CertificateDoc(assetName: "Marriage_certificate_1",
                       displayTitle: "Marriage cert part 1",
                       accent: .orange),
        CertificateDoc(assetName: "Marriage_certificate_2",
                       displayTitle: "Marriage cert part 2",
                       accent: .teal)
    ]

    @State private var selectedCertificate: CertificateDoc?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                introSection
                medicalCertificateSection
                deathCertificateSection
                dadDetailsSection
                mumDetailsSection
                requiredDocumentsSection
                registrarOutcomeSection
                tellUsOnceSection
                songSection
                driveFolderSection
            }
            .padding(.top, 4)
            .padding(.bottom, 4)
        }
        .sheet(item: $selectedCertificate) { doc in
            fullscreenCertificateViewer(for: doc)
        }
    }

    // MARK: - Intro

    private var introSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Immediate things you need to do",
                          systemImage: "flag.fill",
                          tint: .red)

            Text("You don't need to do these all at once.  Take your time!  It's not like we are going anywhere!")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }

    // MARK: - Medical Certificate

    private var medicalCertificateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Medical certificate",
                          systemImage: "stethoscope",
                          tint: .red)

            cardBackground {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Contact the GP or hospital doctor to get the **Medical Certificate of Cause of Death (MCCD)**.")
                        .font(.body)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Local Process", systemImage: "mappin.and.ellipse")
                            .font(.headline)
                            .foregroundStyle(.tint)

                        Text("The doctor will email this certificate directly to **Perth & Kinross Council**. They will also pass your name and phone number to the registration team so they know who to contact.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Death Certificate / Contact Registrars

    private var deathCertificateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Death certificate",
                          systemImage: "doc.text.fill",
                          tint: .blue)

            cardBackground {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Once you know the MCCD has been sent over by the medical team, contact the Perth Registrars to schedule your formal phone appointment:")
                        .font(.body)

                    HStack(spacing: 10) {
                        phoneButton(phone: "01738475121",
                                    display: "01738 475121",
                                    systemImage: "phone.fill")

                        emailButton(email: "perth-registrars@pkc.gov.uk",
                                    systemImage: "envelope.fill")
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("It helps to gather a few details about the person who passed away before the registrar calls you.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Because the appointment is done over the phone, **you do not need the physical, original documents**. The registrar just needs you to read out the information or confirm the details.")
                                .font(.subheadline)
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Dad's Details

    private var dadDetailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Dad's Registration Details",
                          systemImage: "person.text.rectangle",
                          tint: .indigo)

            personDetailCard(
                accent: .indigo,
                rows: [
                    ("Full name", "Kieren Matthew Pound"),
                    ("Date and place of birth", "05 Jan 1968 · Guildford, Surrey, England"),
                    ("Date and place of death", "Unfortunately I can't fill this in for you!  Over to you"),
                    ("Last known address", "Rowanbank, Thimblerow, Dunning, PH2 0RT"),
                    ("Occupation", ""),
                    ("Marital status", ""),
                    ("Spouse or partner's details", "Brenda Mary Pound, retired"),
                    ("Parents' full names", "Brian Ronald Pound / Isobel Mary Underwood"),
                    ("GP details", "St Margaret's Health Centre, St Margaret's Drive, Auchterarder, PH3 1JH")
                ]
            )
        }
    }

    // MARK: - Mum's Details

    private var mumDetailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Mum's Registration Details",
                          systemImage: "person.text.rectangle.fill",
                          tint: .pink)

            personDetailCard(
                accent: .pink,
                rows: [
                    ("Full name", "Brenda Mary Pound"),
                    ("Date and place of birth", "21 Jul 1957 · Perry Barr, Birmingham, England"),
                    ("Date and place of death", "Unfortunately I can't fill this in for you!  Over to you"),
                    ("Last known address", "Rowanbank, Thimblerow, Dunning, PH2 0RT"),
                    ("Occupation", ""),
                    ("Marital status", ""),
                    ("Spouse or partner's details", "Kieren Matthew Pound, retired"),
                    ("Parents' full names", "John Potts / Evelyn Potts (nee Jinks)"),
                    ("GP details", "St Margaret's Health Centre, St Margaret's Drive, Auchterarder, PH3 1JH")
                ]
            )
        }
    }

    // MARK: - Required Documents (Images)

    private var requiredDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Death certificate (documents that may be required)",
                          systemImage: "doc.on.doc.fill",
                          tint: .orange)

            cardBackground {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text("Tap any document card below to open the full high‑resolution scan.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(certificates) { doc in
                            certificateThumbnail(doc)
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private func certificateThumbnail(_ doc: CertificateDoc) -> some View {
        Button(action: {
            selectedCertificate = doc
        }) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    Image(doc.assetName)
                        .resizable()
                        .aspectRatio(1.33, contentMode: .fill)
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(doc.accent.opacity(0.35), lineWidth: 1.2)
                        )

                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 30, height: 30)
                        Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(doc.accent)
                    }
                    .padding(8)
                }
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
                        Image(systemName: "doc.viewfinder")
                            .font(.caption2)
                        Text("Tap to expand")
                            .font(.caption2)
                    }
                    .foregroundStyle(doc.accent)
                }
                .padding(.horizontal, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private func fullscreenCertificateViewer(for doc: CertificateDoc) -> some View {
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
                        selectedCertificate = nil
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

    // MARK: - Registrar Outcome

    private var registrarOutcomeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "What the Registrar will Give You",
                          systemImage: "hand.point.up.braille.fill",
                          tint: .purple)

            cardBackground {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("At the end of the phone call, the registrar will issue the formal **Death Certificate (Form 14)**, which allows the funeral director to proceed, and they will give you the unique access code for the **Tell Us Once** service.")
                            .font(.body)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Certified Copies", systemImage: "doc.on.doc.fill")
                            .font(.headline)
                            .foregroundStyle(.purple)

                        Text("You will need to ask them for **5 Full Certified Copies**. They cost **£10.00 each** at the time of registration. You'll need to pay for them. Ouch! You can order more later for **£15.00** via:")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        Link(destination: URL(string: "https://my.pkc.gov.uk/en")!) {
                            Label("my.pkc.gov.uk/en", systemImage: "globe")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.12))
                                )
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Tell Us Once

    private var tellUsOnceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Tell Us Once",
                          systemImage: "megaphone.fill",
                          tint: .green)

            cardBackground {
                VStack(alignment: .leading, spacing: 16) {
                    Text("The registrar will provide a unique tracking code for the free, official service. Entering this code online allows you to report the bereavement to multiple government systems simultaneously, automatically updating:")
                        .font(.body)

                    VStack(alignment: .leading, spacing: 10) {
                        bulletRow(text: "HMRC (Taxes)", color: .green)
                        bulletRow(text: "DWP (State Pensions & Benefits)", color: .green)
                        bulletRow(text: "The Passport Office", color: .green)
                        bulletRow(text: "The DVLA (Driving Licences)", color: .green)
                        bulletRow(text: "Local Council Tax Teams", color: .green)
                    }
                    .padding(.leading, 4)

                    Divider()

                    Link(destination: URL(string: "https://www.gov.uk/after-a-death/organisations-you-need-to-contact-and-tell-us-once")!) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.up.right.square.fill")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Official GOV.UK Tell Us Once Service")
                                    .font(.subheadline.weight(.semibold))
                                Text("www.gov.uk/after-a-death")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.green.opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.green.opacity(0.25), lineWidth: 1)
                        )
                    }
                    .foregroundStyle(.green)
                }
                .padding(16)
            }
        }
    }

    // MARK: - Song Section (YouTube)

    private var songSection: some View {
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
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(14)
                        .overlay {
                            YouTubePlayerView(videoID: "b4ZypVnbYHM")
                                .cornerRadius(14)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                }
                .padding(14)
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

    private func personDetailCard(accent: Color,
                                  rows: [(label: String, value: String)]) -> some View {
        cardBackground {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                    HStack(alignment: .top, spacing: 12) {
                        Text(row.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(accent)
                            .frame(width: 160, alignment: .leading)

                        if row.value.isEmpty {
                            Text("—")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(row.value)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)

                    if idx < rows.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
    }

    private func bulletRow(text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(color)
                .font(.subheadline)
            Text(text)
                .font(.body)
        }
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

#Preview {
    ScrollView {
        WhatToDoFirstDashboardView()
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
    }
    .background(Color(.systemGroupedBackground))
}
