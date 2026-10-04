import Foundation
import SwiftUI

struct NotificationEntry: Identifiable, Hashable {
    let id: UUID = UUID()
    let orgName: String
    let systemIcon: String
    let accentColor: Color
    let links: [NotificationLink]
    let phone: String?
    let fields: [NotificationField]
    let notes: [String]
    let leadParagraph: String?
}

struct NotificationLink: Identifiable, Hashable {
    let id: UUID = UUID()
    let label: String
    let url: URL
}

struct NotificationField: Identifiable, Hashable {
    enum MonospaceStyle { case sortCode, accountNumber, referenceID, niNumber, holderNumber, membershipNumber, generic }

    let id: UUID = UUID()
    let key: String
    let value: String
    let monospace: MonospaceStyle
    let note: String?
}

// MARK: - Seed data (parsed verbatim from who_to_notify.md)

enum WhoToNotifySeed {

    static let lifeLedger = NotificationEntry(
        orgName: "Life Ledger",
        systemIcon: "square.stack.3d.up.badge.automatic.fill",
        accentColor: .purple,
        links: [
            NotificationLink(label: "Open Official Portal",
                             url: URL(string: "https://lifeledger.com/")!)
        ],
        phone: nil,
        fields: [],
        notes: [
            "Automatically notifies banks, savings, utilities and other places in one go.",
            "Completely free — just bring the company names and account numbers listed below.",
            "Exceptions: eToro and Tembo may not be on Life Ledger — follow their individual sections."
        ],
        leadParagraph: "This secure, free online service allows you to report a death to multiple commercial companies all at once."
    )

    static let tsb = NotificationEntry(
        orgName: "TSB Bank",
        systemIcon: "building.columns.fill",
        accentColor: .teal,
        links: [
            NotificationLink(label: "Bereavement Support Form",
                             url: URL(string: "https://www.tsb.co.uk/help-and-support/bereavement-and-coping-with-loss.html")!)
        ],
        phone: nil,
        fields: [
            NotificationField(key: "Main Account — Sort Code", value: "77-85-39", monospace: .sortCode, note: nil),
            NotificationField(key: "Main Account — Number", value: "19842660", monospace: .accountNumber, note: nil),
            NotificationField(key: "Kieren Retirement", value: "25932068", monospace: .accountNumber, note: nil),
            NotificationField(key: "House Funds", value: "30568168", monospace: .accountNumber, note: nil),
            NotificationField(key: "Savings", value: "39120468", monospace: .accountNumber, note: nil)
        ],
        notes: [
            "TSB will help pay immediate funeral costs or probate fees directly from the remaining balance — if Mum hasn't already booked us in."
        ],
        leadParagraph: nil
    )

    static let starling = NotificationEntry(
        orgName: "Starling Bank",
        systemIcon: "banknote.fill",
        accentColor: .indigo,
        links: [
            NotificationLink(label: "Bereavement Help Centre",
                             url: URL(string: "https://www.starlingbank.com/faq/customer-support/bereavement/")!)
        ],
        phone: nil,
        fields: [
            NotificationField(key: "Sort Code", value: "60-83-71", monospace: .sortCode, note: nil),
            NotificationField(key: "Kieren Account", value: "33013953", monospace: .accountNumber, note: nil),
            NotificationField(key: "Bren Account", value: "25884497", monospace: .accountNumber, note: nil)
        ],
        notes: [],
        leadParagraph: nil
    )

    static let tembo = NotificationEntry(
        orgName: "Tembo (ISAs)",
        systemIcon: "building.columns.circle.fill",
        accentColor: .green,
        links: [
            NotificationLink(label: "Bereavement Guide",
                             url: URL(string: "https://help.tembomoney.com/en/articles/14615894-what-to-do-when-someone-with-a-tembo-account-dies")!)
        ],
        phone: nil,
        fields: [
            NotificationField(key: "Kieren Account ID", value: "ACC-51OZR4-5RN2WE", monospace: .referenceID, note: nil),
            NotificationField(key: "Bren Account ID", value: "ACC-ulineo-f32wxf", monospace: .referenceID, note: nil)
        ],
        notes: [
            "Tembo may not be listed on Life Ledger — use the direct bereavement guide above."
        ],
        leadParagraph: nil
    )

    static let nsandi = NotificationEntry(
        orgName: "National Savings & Investment (Premium Bonds)",
        systemIcon: "ticket.fill",
        accentColor: .pink,
        links: [
            NotificationLink(label: "Deceased Customer Claims Portal",
                             url: URL(string: "https://www.nsandi.com/help/manage-money-for-others/customers-who-have-died")!)
        ],
        phone: nil,
        fields: [
            NotificationField(key: "Holder Number", value: "30905977E", monospace: .holderNumber, note: nil)
        ],
        notes: [
            "Premium Bonds remain eligible to win prizes in the monthly draw for up to 12 months after the date of passing before they must be officially repaid into the estate."
        ],
        leadParagraph: nil
    )

    static let wmPensions = NotificationEntry(
        orgName: "West Midlands Pension Authority (Mum's Pension)",
        systemIcon: "pawprint.circle.fill",
        accentColor: .orange,
        links: [],
        phone: nil,
        fields: [
            NotificationField(key: "Membership Number", value: "10240482", monospace: .membershipNumber, note: nil),
            NotificationField(key: "NI Number", value: "YY 89 74 84 A", monospace: .niNumber, note: nil)
        ],
        notes: [
            "They should already get notified by the \"Tell Us Once\" service used earlier."
        ],
        leadParagraph: nil
    )

    static let atSipp = NotificationEntry(
        orgName: "@SIPP (Mum's Pension)",
        systemIcon: "building.2.crop.circle.fill",
        accentColor: .mint,
        links: [
            NotificationLink(label: "Contact Page",
                             url: URL(string: "https://atsipp.co.uk/contact/")!)
        ],
        phone: "0141 204 7950",
        fields: [],
        notes: [
            "They hold SIPP-related earnings from the commercial rent of the Monkton building to Fly High, and own the building itself.",
            "Best placed to advise on date of death value, transfer of monies, etc. — call the number above."
        ],
        leadParagraph: nil
    )

    static let lifesight = NotificationEntry(
        orgName: "Lifesight (Dad's Pension)",
        systemIcon: "person.text.rectangle.fill",
        accentColor: .cyan,
        links: [
            NotificationLink(label: "Bereavement Form",
                             url: URL(string: "https://lifesight.assure.wtwco.com/bereavement")!)
        ],
        phone: nil,
        fields: [
            NotificationField(key: "Membership Number", value: "0012662", monospace: .membershipNumber, note: nil),
            NotificationField(key: "NI Number", value: "NP 58 40 50 D", monospace: .niNumber, note: nil)
        ],
        notes: [
            "Listed as \"Willis Towers Watson\" inside Life Ledger."
        ],
        leadParagraph: nil
    )

    static let octopus = NotificationEntry(
        orgName: "Octopus Energy",
        systemIcon: "bolt.fill",
        accentColor: .purple,
        links: [],
        phone: nil,
        fields: [
            NotificationField(key: "Rowanbank Property Account", value: "A-EE4346C1", monospace: .referenceID,
                              note: "Registered to brendapound@hotmail.co.uk"),
            NotificationField(key: "5 Grey Row Property Account", value: "A-E82FD9A4", monospace: .referenceID,
                              note: "Registered to kieren@hotmail.co.uk")
        ],
        notes: [],
        leadParagraph: nil
    )

    static let sky = NotificationEntry(
        orgName: "Sky",
        systemIcon: "tv.badge.wifi.fill",
        accentColor: .blue,
        links: [],
        phone: nil,
        fields: [
            NotificationField(key: "Rowanbank — Broadband", value: "625176741977", monospace: .accountNumber,
                              note: "brendapound@hotmail.co.uk"),
            NotificationField(key: "Rowanbank — Sky Stream", value: "625176741969", monospace: .accountNumber,
                              note: "brendapound@hotmail.co.uk"),
            NotificationField(key: "5 Grey Row — TV", value: "622900284986", monospace: .accountNumber,
                              note: "kieren@hotmail.co.uk"),
            NotificationField(key: "5 Grey Row — Mobile", value: "623050819472", monospace: .accountNumber,
                              note: "kieren@hotmail.co.uk")
        ],
        notes: [
            "Cancelling the primary Sky bundle should automatically decouple and cancel the integrated Netflix profile."
        ],
        leadParagraph: nil
    )

    static let digitalSubs = NotificationEntry(
        orgName: "Digital Subscriptions (Amazon, Apple, etc.)",
        systemIcon: "creditcard.and.123",
        accentColor: .gray,
        links: [],
        phone: nil,
        fields: [],
        notes: [
            "Amazon, Apple, and anything else running on a direct debit or recurring card payment should get cancelled automatically by the bank once they freeze the accounts.",
            "You shouldn't have to contact them. Aside from setting up your own Amazon Prime account or paying for your own deliveries!"
        ],
        leadParagraph: nil
    )

    static let computers = NotificationEntry(
        orgName: "Computers",
        systemIcon: "macbook.and.iphone",
        accentColor: .gray,
        links: [],
        phone: nil,
        fields: [],
        notes: [
            "We have at last standardised on Macs after years of viruses, achingly slow performance, and Excel crashing just when you haven't saved the work on the old Windows ones. Thanks Matt!",
            "The password for all of them is the town of your birth, with some substitutions as per the site image."
        ],
        leadParagraph: nil
    )

    static let songForThePageLyric = "Ring, ring, why don't you give me a call? Don't worry, it'll all be fine."

    static var allEntries: [NotificationEntry] {
        [
            lifeLedger,
            tsb,
            starling,
            tembo,
            nsandi,
            wmPensions,
            atSipp,
            lifesight,
            octopus,
            sky,
            digitalSubs,
            computers
        ]
    }
}
