# SwiftUI Component & Data Styling Rules

Always follow these visual, behavioral, and architectural patterns when building or modifying SwiftUI views and parsing Markdown data into iOS pages.

---

## 1. Visual Hierarchy & Card Architecture
* **Container Sections:** Group logical data (e.g., individual bank, utility, or pension entries) into custom card components or `Section` views with consistent rounded corners, background tints, and padded margins matching the rest of the app.
* **Key-Value Pairs:** Use `LabeledContent` or custom app row components for displaying identifiers (Sort Codes, Account Numbers, NI Numbers, Holder IDs).
* **Code Formatting:** Monospace key numeric fields (Account Numbers, Reference IDs, Sort Codes) using `.font(.system(.body, design: .monospaced))` or app token design rules for maximum legibility.

---

## 2. Interactive Links & Action Buttons
* **External Web URLs:**
  * Wrap all web links in `Link(destination: url)` or your app's custom `SafariView` trigger.
  * Always include a trailing SF Symbol (`Image(systemName: "arrow.up.right.square")` or `safari`).
  * Ensure link labels match action-oriented text (e.g., "Open Portal" or "Bereavement Form").

* **Phone Call Actions:**
  * Detect and format phone numbers for tap-to-call using the `tel://` URL scheme.
  * Render call actions as primary/secondary buttons using `Image(systemName: "phone.fill")`.
  * Clean non-numeric characters before building the `URL(string: "tel:\(cleanedNumber)")`.

* **Copy-to-Clipboard Actions:**
  * Provide a tap-to-copy action or long-press context menu on sensitive numerical data (Sort Codes, Account Numbers, Membership IDs) using `UIPasteboard.general.string`.

---

## 3. Data Parsing & Sanitisation
* **Format Preservation:** Keep sort codes explicitly formatted as `XX-XX-XX`.
* **Note Callouts / Footnotes:** Render secondary informational notes or warnings (e.g., Premium Bond prize eligibility limits) inside light-tinted callout boxes using `Image(systemName: "info.circle.fill")`.
* **Decoupled Architecture:** Keep hardcoded fallback/seed data separated into model extension files (e.g., `AccountInfo+Seed.swift`) rather than embedding raw strings directly inside SwiftUI body declarations.

---

## 4. Trae Workflow Instructions
* When generating or populating a page from `.md` files (such as `#who_to_notify.md` or `#legal_documents.md`), inspect neighboring SwiftUI views (`#ReferenceView.swift`) first to mirror existing layout constants, color schemes, and icon styles.