import SwiftUI
import WebKit

struct ConfirmationDashboardView: View {

    private struct ConfirmationPhotoDoc: Identifiable, Hashable {
        let id = UUID()
        let assetName: String
        let displayTitle: String
        let accent: Color
    }

    private let confirmationPhotos: [ConfirmationPhotoDoc] = [
        ConfirmationPhotoDoc(assetName: "gemini_running_800",
                             displayTitle: "Family photograph",
                             accent: .teal)
    ]

    @State private var selectedConfirmationPhoto: ConfirmationPhotoDoc?

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            photosSection
            introAlmostDoneSection
            locateWillSection
            dateOfDeathValuationsSection
            hmrcReferenceSection
            taxFormsSection
            payTaxSection
            iht421AndCourtSection
            grantConfirmationSection
            songSection
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .sheet(item: $selectedConfirmationPhoto) { doc in
            fullscreenConfirmationPhotoViewer(for: doc)
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
                    ForEach(confirmationPhotos) { doc in
                        photoThumbnail(doc)
                    }
                }
                .padding(16)
            }
        }
    }

    private func photoThumbnail(_ doc: ConfirmationPhotoDoc) -> some View {
        Button(action: {
            selectedConfirmationPhoto = doc
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

    // MARK: - You're Almost Done (Intro)

    private var introAlmostDoneSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "You're almost done",
                          systemImage: "sparkles.rectangle.stack.fill",
                          tint: .teal)

            cardBackground {
                VStack(alignment: .leading, spacing: 12) {
                    Text("As the end is near, what better than a musical interlude to set you up for the hardest (and most lucrative) steps.  Please play the Song for the day at the end and think of us, kindly.  Or laugh.  Hopefully both!")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Divider()

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title3)
                            .foregroundStyle(.teal)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.teal.opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: 6) {
                            Text("You've got this")
                                .font(.headline)
                            Text("Everything from here on is linear paperwork.  Take it one card at a time and you'll be done in a few weeks.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Locate the Will

    private var locateWillSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Locate the Will & Identify the Executors",
                          systemImage: "signature",
                          tint: .purple)

            cardBackground {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Before touching any accounts, find the original paper Will.")
                            .font(.headline)

                        Text("Why it matters:  The Will explicitly names the Executors.  These are the only people legally allowed to sign the upcoming HMRC tax returns and court inventories.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "doc.text.viewfinder")
                                .font(.headline)
                                .foregroundStyle(.red)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("The Original Document")
                                .font(.headline)

                            Text("A photocopy is useless for the court.  The physical paper original must be kept safe.  It is located in the bureau")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("[The master  copy is held securely at Thorntons]")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.tertiarySystemGroupedBackground))
                                )
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Date of Death Valuations

    private var dateOfDeathValuationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Request \"Date of Death\" Valuations",
                          systemImage: "scalemass.fill",
                          tint: .orange)

            cardBackground {
                VStack(alignment: .leading, spacing: 12) {
                    Text("You must get the exact financial value of everything owned on the specific day of passing.  Contact each company below and ask for a \"Date of Death Balance Certificate\":")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Divider()

                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.brown.opacity(0.14))
                                .frame(width: 40, height: 40)
                            Image(systemName: "house.fill")
                                .font(.headline)
                                .foregroundStyle(.brown)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("The Houses")
                                .font(.headline)
                            Text("You must get a formal, written valuation from a chartered surveyor or a local estate agent for the open-market value of all the properties")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.indigo.opacity(0.14))
                                .frame(width: 40, height: 40)
                            Image(systemName: "building.columns.fill")
                                .font(.headline)
                                .foregroundStyle(.indigo)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("The Banks")
                                .font(.headline)
                            Text("Contact the following for final balances across all listed account numbers (see Who to Contact):")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            FlowChipRow(items: ["TSB", "Starling", "Tembo", "NS&I", "eToro"], tint: .indigo)
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - HMRC Tax Reference

    private var hmrcReferenceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Get an HMRC Tax Reference Number",
                          systemImage: "number",
                          tint: .indigo)

            cardBackground {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.indigo.opacity(0.14))
                                .frame(width: 40, height: 40)
                            Image(systemName: "safari.fill")
                                .font(.headline)
                                .foregroundStyle(.indigo)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("The Action")
                                .font(.headline)
                            Text("Go online to GOV.UK and apply for an Inheritance Tax Reference Number using Form IHT422.")
                                .font(.body)
                        }
                    }

                    Divider()

                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.mint.opacity(0.18))
                                .frame(width: 40, height: 40)
                            Image(systemName: "calendar.badge.clock")
                                .font(.headline)
                                .foregroundStyle(.mint)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("The Timeline")
                                .font(.headline)
                            Text("Do this immediately after getting your valuations.  It takes HMRC about 3 weeks to generate and post this reference number to you, and you cannot pay the tax or submit forms without it.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - HMRC Tax Forms

    private var taxFormsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Fill in the HMRC Tax Forms",
                          systemImage: "doc.plaintext.fill",
                          tint: .blue)

            cardBackground {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Once you have your reference number and all your exact estate values, the executors must complete the heavy tax paperwork:")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Divider()

                    formCard(title: "Form IHT400 (The Inheritance Tax Account)",
                             systemImage: "list.bullet.rectangle.portrait.fill",
                             tint: .blue,
                             body: "This is the main, comprehensive 16-page tax return where you list everything, including the house valuations, bank cash, and any major gifts given away in the last 7 years.")

                    Divider()

                    formCard(title: "Form C1 (The Confirmation Inventory)",
                             systemImage: "building.columns.circle.fill",
                             tint: .purple,
                             body: "This is the Scottish court form where you list the exact same assets line-by-line.  You must fill this in alongside your tax return.")
                }
                .padding(16)
            }
        }
    }

    // MARK: - Pay the Tax

    private var payTaxSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Pay the Tax (Bypassing the Cash Trap)",
                          systemImage: "banknote.fill",
                          tint: .green)

            cardBackground {
                VStack(alignment: .leading, spacing: 12) {
                    Text("HMRC expects you to pay the tax bill before the court will grant Confirmation.  To clear this hurdle without spending your own personal money, use these tools:")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Divider()

                    infoCallout(tint: .indigo,
                                icon: "arrow.right.doc.on.clipboard",
                                title: "Form IHT423 (The Direct Payment Scheme)",
                                body: "Complete a copy of this form for TSB and Starling.  This sends a legal instruction to the banks to pull money directly from my frozen accounts and wire it straight to HMRC to clear the tax bill.  We'll try to ensure there is cash enough to do this")

                    infoCallout(tint: .brown,
                                icon: "house.lodge.fill",
                                title: "The Property Installment Option",
                                body: "Because much of the value is tied up in bricks-and-mortar (Rowanbank and 5 Grey Row), HMRC allows the tax owed on houses to be split into 10 annual installments.  You only need to pay the first 10% installment upfront to pass this step.")
                }
                .padding(16)
            }
        }
    }

    // MARK: - IHT421 Stamped Cert + Perth Sheriff Court

    private var iht421AndCourtSection: some View {
        let courtPackageItems: [String] = [
            "Your completed Form C1 (Asset Inventory)",
            "The Original physical paper Will",
            "A certified copy of the Death Certificate",
            "The required Court Submission Fee"
        ]

        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "IHT421 Stamped Certificate & Perth Sheriff Court",
                          systemImage: "envelope.fill",
                          tint: .red)

            cardBackground {
                VStack(alignment: .leading, spacing: 12) {
                    stepBlock(icon: "tray.and.up.arrow.fill",
                              tint: .red,
                              stepNumber: 1,
                              title: "Mail IHT400 to HMRC",
                              body: "Mail your completed Form IHT400 to:")

                    postalCard(address: """
HM Revenue and Customs
BX9 1HT
""", tint: .red)
                    .padding(.leading, 48)

                    Divider()

                    stepBlock(icon: "checkmark.shield.fill",
                              tint: .orange,
                              stepNumber: 2,
                              title: "Wait for the stamped IHT421 certificate",
                              body: "Once HMRC receives your paperwork and checks that the tax payment from Step 5 has cleared, they will not send you a physical receipt.  Instead, they will generate a secure, stamped digital certificate called an IHT421 (or an online clearance code).  They will send this code directly to the court as proof that the tax hurdle is cleared.")

                    Divider()

                    stepBlock(icon: "building.columns.circle.fill",
                              tint: .purple,
                              stepNumber: 3,
                              title: "Submit to the Perth Sheriff Court",
                              body: "Once HMRC issues your tax clearance code, mail your final court package to the Perth Sheriff Court:")

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(courtPackageItems, id: \.self) { (item: String) in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.purple)
                                    .padding(.top, 7)
                                Text(item)
                                    .font(.body)
                            }
                        }
                    }
                    .padding(.leading, 48)
                }
                .padding(16)
            }
        }
    }

    // MARK: - Receive Grant of Confirmation

    private var grantConfirmationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Receive the Grant of Confirmation & Unlock the Cash",
                          systemImage: "checkmark.seal.fill",
                          tint: .teal)

            cardBackground {
                VStack(alignment: .leading, spacing: 14) {
                    Text("The Sheriff Court will review the Will and inventory.  Within 2 to 4 weeks, they will issue the formal Grant of Confirmation.")
                        .font(.body)

                    Divider()

                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.green.opacity(0.16))
                                .frame(width: 44, height: 44)
                            Image(systemName: "party.popper.fill")
                                .font(.headline)
                                .foregroundStyle(.green)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("The End!")
                                .font(.title3.bold())
                                .foregroundStyle(.primary)
                            Text("Pay for 10+ Certified Copies of this certificate.  Send a copy to TSB, Starling, Tembo, eToro and NS&I.  They will instantly lift the freezes, release the cash to the executors' bank account, and allow the property titles to be transferred or sold.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    infoCallout(tint: .teal,
                                icon: "scroll.fill",
                                title: "🏡 Note on the properties (Rowanbank, 5 Grey Row and the flats)",
                                body: "You cannot update the house deeds yourself.  In Scotland, property records are held by Registers of Scotland (RoS).  Once you receive the Grant of Confirmation from the court, you must hand it to a Scottish solicitor (suggest Thorntons as they will manage our will).  They will draft a legal document called a Disposition to either transfer the titles to the family or manage the sale of the properties.")
                }
                .padding(16)
            }
        }
    }

    // MARK: - Song for the Day (YouTube)

    private var songSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Song for the day",
                          systemImage: "music.note.tv.fill",
                          tint: .teal)

            cardBackground {
                VStack(alignment: .leading, spacing: 12) {
                    Text("JXA X Frank Sinatra — My Way (Hardstyle Remix).  Crank it, pour something, and enjoy.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Color.black
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 200)
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(14)
                        .overlay {
                            YouTubePlayerView(videoID: "lHzhH_tJ7ak")
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

    // MARK: - Shared sub-view helpers

    private func formCard(title: String, systemImage: String, tint: Color, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(body).font(.body).foregroundStyle(.secondary)
            }
        }
    }

    private func infoCallout(tint: Color, icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(body).font(.body).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 0.6)
        )
    }

    private func stepBlock(icon: String,
                           tint: Color,
                           stepNumber: Int,
                           title: String,
                           body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 36, height: 36)
                Text(String(stepNumber))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(body).font(.body).foregroundStyle(.secondary)
            }
        }
    }

    private func postalCard(address: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(address)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 0.6)
        )
    }

    private func fullscreenConfirmationPhotoViewer(for doc: ConfirmationPhotoDoc) -> some View {
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
                        selectedConfirmationPhoto = nil
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

private struct FlowChipRow: View {
    let items: [String]
    let tint: Color

    var body: some View {
        FlexibleView(items: items, spacing: 6, alignment: .leading) { (item: String) in
            Text(item)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(
                    Capsule().fill(tint.opacity(0.12))
                )
        }
    }
}

private struct FlexibleView<Items: Collection, Content: View>: View where Items.Element: Hashable {
    let items: Items
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Items.Element) -> Content

    @State private var totalHeight = CGFloat.zero

    var body: some View {
        GeometryReader { geo in
            self.generate(in: geo)
        }
        .frame(height: totalHeight)
    }

    private func generate(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        let itemsArray: [Items.Element] = Array(items)

        return ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
            ForEach(itemsArray, id: \.self) { (element: Items.Element) in
                content(element)
                    .padding(.trailing, spacing)
                    .padding(.bottom, spacing)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > g.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if element == itemsArray.last {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if element == itemsArray.last {
                            height = 0
                        }
                        return result
                    }
            }
        }
        .background(HeightReaderView(binding: $totalHeight))
    }
}

private struct HeightReaderView: View {
    @Binding var binding: CGFloat

    var body: some View {
        GeometryReader { geo -> Color in
            DispatchQueue.main.async {
                self.binding = geo.size.height
            }
            return Color.clear
        }
    }
}

#Preview {
    ScrollView {
        ConfirmationDashboardView()
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
    }
    .background(Color(.systemGroupedBackground))
}
