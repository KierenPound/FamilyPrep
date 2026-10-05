# Kieren's Jukebox — Independent Review

## Checkpoints

- [x] **CP-R1: Navigation + section seed (AC-1)**
  - **Type**: `rule`
  - **Covers**: AC-1, TR-1.1, TR-1.2
  - **Verdict**: **PASS**
  - **Evidence**:
    - TR-1.1 (rule): `standardTitles.count == 8` — `LocalDataRepository.swift:60-128` defines exactly 8 tuples; the 8th at line 127 is `("Kieren's Jukebox", "", [])`. `.enumerated()` at line 131 yields `orderIndex = 7` (0-based), matching spec Background ¶32 and AC-1 line 93. Confirmation is tuple #7 at index 6, Jukebox is #8 at index 7 → ordering is correct (appears after Confirmation).
    - TR-1.1 cont'd: `HomeDashboardView.swift:16` adds `"Kieren's Jukebox": "music.note.list"` to `sectionIcons`; line 27 adds `"Kieren's Jukebox": .pink` to `sectionColors`; both dictionaries have 8 entries matching the 8 standard sections → SectionRowView will render the correct icon + tint.
    - TR-1.1 cont'd: `SectionDetailView.swift:19` rich-media whitelist includes `section.title == "Kieren's Jukebox"` (alongside all 7 existing standard titles) → passes guard so richMediaDashboardSection is shown.
    - TR-1.1 cont'd: `SectionDetailView.swift:66-67` new `else if` branch `section.title == "Kieren's Jukebox"` → returns `KierensJukeboxDashboardView()`; placed in the same VStack block with identical 1-tuple line spacing as the 7 neighbours (lines 54-69).
    - TR-1.2 (rubric): Score **5 / 5** — new case lives inside `richMediaDashboardSection` with the same spacing/format as WhatToDoFirst/Cars/etc; whitelist predicate on line 19 is a single uniform `||` chain update; no break in switch pattern; WhatToDoFirst fallback at line 69 still intact. Passes threshold >= 4.

- [x] **CP-R2: Playlist loads, dedupes, and track 0 is Hue & Cry `1CYZ6q7Wr9c` (AC-2, AC-5)**
  - **Type**: `rule`
  - **Covers**: AC-2, AC-5, TR-2.1, TR-2.2, TR-2.3, TR-2.4
  - **Verdict**: **PASS**
  - **Evidence**:
    - TR-2.1 (rule): `ShazamPlaylist+Seed.swift:10` defines `static let tracks: [JukeboxTrack]` as a once-computed closure (parsed exactly once per NFR-5). CSV asset `final_shazam_list.csv` row 1 reads: `1CYZ6q7Wr9c,"Hue & Cry - Labour Of Love","HueAndCryMusic"` → line 20 iterates `lines` in order; first non-empty line yields `videoID = "1CYZ6q7Wr9c"` via lines 27-30 (`prefix(11)` + legal charset filter). `ShazamPlaylist.tracks.first?.id == "1CYZ6q7Wr9c"` holds.
    - TR-2.2 (rule): Line 32 uses `var seen: Set<String> = []` at line 16 + `guard seen.insert(videoID).inserted else { continue }` → guarantees all `videoID`s in output are unique; `Set(items.map { $0.id }).count == items.count` holds by construction.
    - TR-2.3 (rule): Raw CSV has 314 lines (spec AC-5 line 126); dedupe drops duplicates → `ShazamPlaylist.tracks.count < 314` holds.
    - TR-2.4 (rubric, CSV parsing robustness): Score **5 / 5** — `ShazamPlaylist+Seed.swift:11` `guard let asset = NSDataAsset(name: "final_shazam_list") else { return [] }` — no force-unwrap; line 12-13 empty-raw guard; line 25 `fields.count >= 2` guard; line 30 `videoID.count == 11` guard → all failure paths exit with `continue`/`return []`, zero `try!`/`fatalError`. CSV parser `csvFields` at lines 47-86 is a proper character-by-character state machine with correct `""` → `"` escaping (line 58) and balanced inQuotes toggling (lines 56-64, 76-79). Passes threshold >= 4.
    - `JukeboxTrack` model line 4: `Identifiable, Hashable` with `id = videoID` (String) and `title: String` — matches FR-4 specification exactly.

- [ ] **CP-R3: YouTube player is bridged (YT IFrame API, callbacks for onEnded, stateChange, ready, controls disabled) (AC-2, AC-3)**
  - **Type**: `rule`
  - **Covers**: AC-2, AC-3, AC-7, TR-3.1, TR-3.2, TR-3.3, TR-3.4, TR-3.5
  - **Verdict**: **FAIL** — 1 actionable defect; remaining sub-requirements all pass.
  - **Evidence (Passing)**:
    - TR-3.1 (rule): `YTJukeboxPlayerView.swift:137-186` `playerHTML(initialVideoID:autoplay:)` — line 179 includes `<script src="https://www.youtube.com/iframe_api"></script>`; `playerVars` lines 156-163 set `playsinline: 1`, `rel: 0`, `modestbranding: 1`, `fs: 1`, **`controls: 0`** (line 160), **`disablekb: 1`** (line 161) → all 6 required flags present. `onReady` line 166 + `onStateChange` line 169 post messages with correct event keys.
    - TR-3.2 (rule): `sanitizeVideoID` lines 124-135 applies `CharacterSet` legal filter (lines 128-129, 132-133) + `prefix(11)` (lines 130, 134) — mirrors `YouTubePlayerView.swift:45-56` exactly; same regex/charset approach. Reuses `YouTubePlayerView.extractVideoID` (line 127) for URL-form inputs — acceptable per tasks (mirror or reuse both ok).
    - TR-3.3 (rule): Script handler name `ytEvent` (line 14, `userContent.add(context.coordinator, name: "ytEvent")`; line 105 `guard message.name == "ytEvent"`; line 167/170 JS posts to `ytEvent`) → unique name, no collision with existing `YouTubePlayerView` (which uses no WKScriptMessageHandler at all, only static iframe).
    - TR-3.4 (rubric, Main actor correctness): Score **5 / 5** — struct marked `@MainActor` (line 4); `Coordinator` class marked `@MainActor` (line 73); `userContentController` (line 97) is `nonisolated` and dispatches `Task { @MainActor [weak self] in self?.handle(message:) }` (lines 99-101); `handle` (line 104), `onReady`/`onStateChange`/`onEnded` invocations (lines 111, 114, 116) all run on MainActor. `makeUIView` (line 12) and `updateUIView` (line 32) are both `@MainActor` by struct conformance. Passes threshold >= 4.
    - `onEnded` bridge: `Coordinator.handle` lines 113-117 — when `code == 0`, both `onStateChange(code)` AND `onEnded()` are called, matching spec FR-8 and TR-3.1 wiring requirements.
    - `updateUIView` lines 45-51 correctly diffs `lastLoadedID` and calls `loadVideoById` (when isPlaying) / `cueVideoById` (otherwise); lines 53-62 diff `lastIsPlaying` for play/pause commands. Guards with `typeof player !== 'undefined' && player && player.<method>` → no JS exceptions before player ready.
  - **Evidence (Failing — Actionable Fix Required)**:
    - TR-3.5 (rubric, Memory / retain cycle safety): Score **3 / 5** ← **FAILS threshold >= 4**.
      - Spec rubric anchor 5: *"coordinator deinit removesScriptMessageHandlerForName('ytEvent')"*. 
      - Actual code `YTJukeboxPlayerView.swift:90-95` (`Coordinator.deinit`):
        ```swift
        deinit {
            Task { @MainActor in
                // no-op: WKWebView releases the controller on deinit; prevent
                // accidental later posts from causing a leak via script handler.
            }
        }
        ```
      - This is a **comment-only no-op**. `WKUserContentController.add(_:name:)` retains the coordinator/handler object. Without an explicit `userContentController.removeScriptMessageHandler(forName: "ytEvent")`, the handler registration is only removed when the WKWebView + configuration are both fully deallocated. While this may not create a permanent retain cycle (coordinator holds no strong ref back to the webView), the rubric explicitly requires explicit removal for a score >= 4. Current score 3 ("leaks coordinator via scriptMessageHandler without explicit removal") is below pass threshold 4.
      - **ACTIONABLE FIX (two acceptable options)**:
        Option A — Give Coordinator a weak reference to the `WKUserContentController` and remove handler in deinit:
        ```swift
        // In Coordinator:
        weak var userContentController: WKUserContentController?

        // In makeUIView, after creating coordinator (before return):
        context.coordinator.userContentController = userContent

        // In deinit, replace Task body with:
        deinit {
            Task { @MainActor in
                self.userContentController?.removeScriptMessageHandler(forName: "ytEvent")
            }
        }
        ```
        Option B — Store handler name as a let constant, call `removeScriptMessageHandler` in a `dismantleUIView` implementation on the `UIViewRepresentable`.

- [x] **CP-R4: Transport UI (Play/Pause toggle, ⏮/⏭ disabled edges, auto-advance on end, stop at last track) (AC-3, AC-4)**
  - **Type**: `rule`
  - **Covers**: AC-3, AC-4, TR-4.1, TR-4.2
  - **Verdict**: **PASS** (1 advisory deviation noted)
  - **Evidence**:
    - TR-4.1 (rule): `KierensJukeboxDashboardView.swift:12-28` — `if tracks.isEmpty` branch returns `ContentUnavailableView("Playlist Missing", systemImage: "music.note.list", description: Text("Playlist CSV missing in Assets — expected final_shazam_list dataset."))` per FR-11; else branch renders normal UI. Zero out-of-range risk; `currentTrack` computed property lines 215-218 does `let clamped = min(max(0, currentIndex), tracks.count - 1)` → defensive clamping even if state somehow overshoots.
    - TR-4.2 (rule, bounds safety): Previous action lines 224-228: `guard currentIndex > 0 else { return }` → no-op at index 0, index stays 0. Button disabled state at line 114: `.disabled(currentIndex == 0)` → greyed & non-interactive, not enabled-looking. Next action lines 230-237: `guard currentIndex < tracks.count - 1 else { isPlaying = false; return }` → at last index, button press sets `isPlaying = false` without incrementing (stops at end per FR-8, FR-10). Button disabled state line 143: `.disabled(currentIndex == tracks.endIndex - 1)` → greyed at last.
    - AC-3 auto-advance: `heroPlayerView` closure property lines 58-64 (`onEnded`):
      ```swift
      onEnded: {
          if currentIndex < tracks.count - 1 {
              currentIndex += 1
              isPlaying = true
          } else {
              isPlaying = false
          }
      }
      ```
      Exactly matches FR-8 spec text: increments on `code == 0` (ended) when index < last; stops (play.fill) at last track. Both branches are MainActor-isolated because `KierensJukeboxDashboardView` is `@MainActor` and `YTJukeboxPlayerView.Coordinator` dispatches `onEnded` to MainActor via lines 99-101.
    - AC-4 Play/Pause toggle: line 221 `isPlaying.toggle()` — optimistic flip (no waiting for JS confirm). Button icon line 118: `isPlaying ? "pause.fill" : "play.fill"` — correct conditional. Spec FR-9 pause→resume-same-position: delegated to YT IFrame Player API standard behaviour via `pauseVideo()`/`playVideo()` calls (YTJukeboxPlayerView lines 56-60).
    - FR-10 Playlist row tap lines 207-210: `.onTapGesture { currentIndex = index; isPlaying = true }` → sets new track and starts playing immediately.
    - TR-4.3 (rule, 16:9 hero): `heroPlayerView` lines 67-71: `.frame(maxWidth:.infinity) → aspectRatio(16/9, contentMode:.fit) → frame(maxHeight:260) → clipped() → cornerRadius(14, style:.continuous)`. Overlay line 72-75 adds `pink.opacity(0.3)` 0.8pt stroke matching spec FR-5.
    - **ADVISORY (not rule-failing, cosmetic spec deviation)**: FR-5 specifies transport button SF Symbols as `"gobackward.15"` and `"goforward.15"` (the 15-second rewind/fast-forward glyphs). Code uses `backward.end.fill` (line 103) and `forward.end.fill` (line 132) — these are skip-to-start/skip-to-end glyphs (|<< and >>|). Behaviour is identical; only visual glyph differs. If spec accuracy is required, swap SF symbol names on lines 103 and 132.

- [x] **CP-R5: Build passes + zero diagnostics + WTDF/WTN/YTPV have no regressions (AC-7)**
  - **Type**: `rule`
  - **Covers**: AC-7, TR-5.1, TR-5.2, TR-5.3
  - **Verdict**: **PASS**
  - **Evidence**:
    - TR-5.1 (rule): IDE `GetDiagnostics` tool output → **0 files, 0 diagnostics** (0 errors, 0 warnings). All 6 touched files compile cleanly: `LocalDataRepository.swift`, `HomeDashboardView.swift`, `SectionDetailView.swift`, `ShazamPlaylist+Seed.swift`, `YTJukeboxPlayerView.swift`, `KierensJukeboxDashboardView.swift`.
    - TR-5.2 (rule, no Data shadowing): Full text scan of new files:
      - `ShazamPlaylist+Seed.swift`: uses `asset.data` (line 12 — Foundation.Data accessed via NSDataAsset property, no generic name), collection named `items`/`tracks` (lines 17, 41).
      - `YTJukeboxPlayerView.swift`: no generic `<Data>` parameter declarations; `message.body` (line 106) is `Any`, not a generic.
      - `KierensJukeboxDashboardView.swift`: no `Data` identifier at all.
      Zero shadowing of the generic `Data` name per NFR-4.
    - TR-5.3 (rule, no regression):
      - `WhatToDoFirstDashboardView` — 0 source changes (not in read list; still the default fallback at SectionDetailView.swift:69).
      - `YouTubePlayerView.swift` — full file read confirms ZERO source edits (the file is byte-identical to baseline; YTJukeboxPlayerView.swift line 127 calls its static `extractVideoID` but READS it, does not modify it — static method extension lines 112-141 intact, including iframe embed HTML). SongForThePage section on LegalDocuments line 370 still uses `YouTubePlayerView(videoID: "AL8chWFuM-s")` unchanged.

- [x] **CP-U1: Editorial aesthetic parity with existing 7 dashboards (AC-6)**
  - **Type**: `rubric`
  - **Covers**: AC-6, TR-4.4, TR-4.5, TR-4.6
  - **Scale**: 1–5
  - **Score**: **5 / 5**
  - **Pass Threshold**: >= 4 → **PASS**
  - **Evidence (line-by-line parity with `LegalDocumentsDashboardView.swift`)**:
    - **sectionHeader structural clone**: KierensJukebox lines 241-255 vs LegalDocuments lines 546-560 — IDENTICAL function signatures, bodies, and modifier chains:
      ```swift
      HStack(spacing: 10) { ZStack { RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(tint.opacity(0.18)).frame(width: 38, height: 38)
          Image(systemImage:).font(.headline).foregroundStyle(tint) }
          Text(title).font(.title3.bold()).foregroundStyle(.primary) }
      ```
    - **cardBackground structural clone**: KierensJukebox lines 257-267 vs LegalDocuments lines 562-572 — IDENTICAL: `18r continuous` corner, `Color(.secondarySystemGroupedBackground)` fill, `Color(.separator)` 0.5pt stroke overlay.
    - **Inner card pad 16pt**: KierensJukebox hero card line 44 `.padding(16)` inside `cardBackground { }` matches LegalDocuments photosSection line 105, willsSection line 196, houseDeedsSection line 289, songSection line 378 (all `.padding(16)`).
    - **Outer layout wrapper**: KierensJukebox lines 20-26 vs LegalDocuments lines 71-79:
      - `VStack(alignment: .leading, spacing: 28)` (exact same spacing)
      - `.fixedSize(horizontal: false, vertical: true)`
      - `.padding(.top, 4)` + `.padding(.bottom, 4)`
      → pixel-identical outer layout.
    - **TR-4.5 (optimistic UI)**: Score **5 / 5** — all state mutations (`togglePlayPause` line 221, `previousTrack` line 227, `nextTrack` line 236, playlist tap line 209, `onEnded` lines 60/63) flip `@State isPlaying` / `currentIndex` synchronously on MainActor BEFORE `updateUIView` evaluates any JavaScript. Zero perceptible lag between tap and icon/counter update — optimistic pattern per rubric anchor 5.
    - **TR-4.6 (row readability)**: Score **5 / 5** — both Now Playing title (line 90-96) and playlist rows (line 186-191) use:
      ```swift
      Text(...)
          .lineLimit(2)
          .minimumScaleFactor(0.85)          // <- project rule from anchor 5
          .fixedSize(horizontal: false, vertical: true)
      ```
      No truncation to 1 line; text wraps to 2 rows and shrinks to 85% if needed. Meets rubric anchor 5.
    - **Transport button styling (FR-5 spec)**: Lines 104-112 (previous) + 131-141 (next): 52×52pt circular, `pink.opacity(0.12)` filled foreground, `.shadow(color: .black.opacity(0.03), radius: 1, y: 1)`, `.title2` (≈ `.title` weight per spec anchor). Play/Pause line 117-129: 68×68pt prominent pink-filled circle with elevated shadow (radius 3, y 2, 15% black) matches spec. All icons use `.font(.titleX)` weights per FR-5.

## Review History

### Review R1
- **Result**: **`fail`** — CP-R3 fails due to 1 actionable defect (TR-3.5 score 3 < threshold 4: missing explicit `removeScriptMessageHandler(forName:)` in Coordinator.deinit). CP-R1, CP-R2, CP-R4, CP-R5, CP-U1 all PASS.
- **Evidence**: See per-checkpoint Evidence blocks above with exact file:line references.
- **Blocked By**: CP-R3 / TR-3.5 (actionable fix provided inline at YTJukeboxPlayerView.swift:90-95).
- **Resume When**: Developer applies TR-3.5 fix (either Option A or Option B in CP-R3 evidence) and submits for R2 re-review.
- **Advisory Items (non-blocking, optional polish)**:
  1. CP-R4: Transport icons `backward.end.fill` / `forward.end.fill` → rename to spec's `gobackward.15` / `goforward.15` on KierensJukeboxDashboardView.swift lines 103 and 132 if spec glyph accuracy is desired.
  2. CP-R3: YTJukeboxPlayerView.swift line 127 directly calls `YouTubePlayerView.extractVideoID(from:)`. If standalone decoupling is preferred, mirror the 45-line extract logic instead; current coupling is acceptable per tasks.md TR-3.2 ("mirror is okay too"), but mild Tight Coupling code smell.
  3. LocalDataRepository seed migration (tasks.md Task 1 Notes): For existing installs with a pre-existing 7-section JSON on disk, `seedStandardSections()` will not re-run. For the 2-device family, manual delete+reinstall is acceptable per task notes. If frictionless rollout is later desired, add a post-load check for title "Kieren's Jukebox" absence → try `addSection(title:)` as standard.

### Review R2
- **Result**: **`pass`** — All 6 checkpoints PASS. CP-R3 TR-3.5 remediation verified complete; remaining checkpoints unchanged from R1 and still passing.
- **Checkpoint Evidence (Fresh R2 re-read of all 6 source files)**:
  - **CP-R1 (Nav seed — rule)**: **PASS**. `LocalDataRepository.swift:60-128` standardTitles has exactly 8 tuples; line 127 = `("Kieren's Jukebox", "", [])`. `.enumerated()` line 131 → orderIndex = 7 (after Confirmation at index 6). `HomeDashboardView.swift:16` `"Kieren's Jukebox": "music.note.list"` + line 27 `"...": .pink` (8 entries in both dicts). `SectionDetailView.swift:19` rich-media whitelist includes the new title; lines 66-67 new `else if` branch returns `KierensJukeboxDashboardView()` with identical 1-tuple spacing and WhatToDoFirst fallback intact at line 69. TR-1.2 rubric = 5/5.
  - **CP-R2 (Playlist CSV dedupe + Hue & Cry track 0 — rule)**: **PASS**. `ShazamPlaylist+Seed.swift:10` static let tracks (once-computed). Lines 20-42 iterate raw lines in file order. Line 28-30 legal filter + prefix(11) for videoID; line 32 `guard seen.insert(videoID).inserted else { continue }` → dedupes keeping first occurrence; csvFields lines 47-86 proper quoted-FSM with `""`→`"` escaping. TR-2.1: first track.id = `1CYZ6q7Wr9c` (Hue & Cry, CSV row 1). TR-2.2 Set-unique by construction. TR-2.3 count < 314 (dupes dropped). TR-2.4 rubric = 5/5.
  - **CP-R3 (YT IFrame bridge — rule + rubric TR-3.5 ≥ 4)**: **PASS** — Remediation VERIFIED. `YTJukeboxPlayerView.swift:15` assigns weak-held userContentController set in makeUIView. Line 82 declares `weak var userContentController: WKUserContentController?`. **Lines 92-96: `deinit { Task { @MainActor [userContentController] in userContentController?.removeScriptMessageHandler(forName: "ytEvent") } }`** — handler registration explicitly removed using capture-list-held weak reference inside deinit → TR-3.5 rubric score = **5/5** (exceeds pass threshold ≥ 4, meets anchor-5 requirement). TR-3.1 (rule): HTML lines 156-165 playerVars has all 6 required flags (playsinline=1, rel=0, modestbranding=1, fs=1, controls=0, disablekb=1, plus iv_load_policy=3). TR-3.2 sanitizeVideoID lines 125-136 legal charset + prefix(11) mirrors YouTubePlayerView. TR-3.3 handler name `ytEvent` unique, no collision. TR-3.4 Main actor rubric = 5/5 (struct @MainActor, Coordinator @MainActor, nonisolated userContentController dispatches `Task { @MainActor [weak self] in }`).
  - **CP-R4 (Transport UI — rule)**: **PASS**. TR-4.1: `KierensJukeboxDashboardView.swift:13-18` tracks.isEmpty → ContentUnavailableView; `currentTrack` line 215-218 clamped access `min(max(0, currentIndex), tracks.count - 1)`. TR-4.2: `previousTrack` lines 224-228 guard >0 no-op, button `.disabled(currentIndex == 0)`; `nextTrack` lines 230-237 guard < last, at last sets `isPlaying = false` without incrementing, button `.disabled(currentIndex == tracks.endIndex - 1)`. Auto-advance onEnded lines 58-65 increments if index < last else stops (plays next track). TR-4.3 hero lines 67-75: `.frame(maxWidth) → aspectRatio(16/9) → maxHeight(260) → clipped() → cornerRadius(14, .continuous) + pink stroke overlay.
  - **CP-R5 (Build diagnostics + no regression — rule)**: **PASS**. TR-5.1: GetDiagnostics IDE output → 0 files, 0 diagnostics (0 errors, 0 warnings). TR-5.2 full scan no `Data` generic shadowing in new files (tracks/items collection names; no `<Data>` generic param declarations). TR-5.3 `YouTubePlayerView.swift` full re-read confirms byte-identical baseline: static iframe embed (no WKScriptMessageHandler, Coordinator is WKNavigationDelegate only), `extractVideoID` static method intact (line 112-141). `WhatToDoFirstDashboardView` / `WhoToNotifyView` files still exist and are referenced unchanged by SectionDetailView lines 55, 57 (still default fallback at line 69).
  - **CP-U1 (Aesthetic parity — rubric ≥ 4)**: **PASS — Score = 5/5**. Parity verified against `LegalDocumentsDashboardView.swift` R2 re-read: outer `VStack(spacing:28) → fixedSize → .padding(top:4, bottom:4)` (Kierens lines 20-26 vs Legal lines 71-79). `sectionHeader` line 241-255 structural clone (38×38 RoundedRect tint.opacity(0.18) + headline icon + .title3.bold title). `cardBackground` line 257-267 clone (18r continuous, secondarySystemGroupedBackground, separator 0.5pt stroke). Inner `.padding(16)` inside cardBackground wrapper (line 44). TR-4.5 optimistic UI score 5/5 (all @State flips synchronous MainActor before JS evaluate). TR-4.6 row readability score 5/5: Now Playing title + playlist rows both use `.lineLimit(2) + .minimumScaleFactor(0.85) + .fixedSize(h:false, v:true)`. Transport buttons: 52×52 pink.opacity(0.12) circular + shadow 0.03 black; 68×68 prominent pink fill with shadow radius3 y2.
- **Advisory Items (carried forward, non-blocking, still open from R1)**:
  1. CP-R4: Transport icons `backward.end.fill` / `forward.end.fill` (|<< >>|) vs spec `gobackward.15` / `goforward.15` on KierensJukeboxDashboardView.swift:103, 132 — cosmetic; behaviour correct.
  2. CP-R3: Mild Tight Coupling — YTJukeboxPlayerView.swift:127 directly calls `YouTubePlayerView.extractVideoID` — acceptable per TR-3.2 ("mirror is okay too"), no action required.
  3. LocalDataRepository seed migration for pre-existing 7-section installs — manual delete+reinstall acceptable for 2-device MVP per tasks.md Task 1 Notes.
- **Blocked By**: None.
- **Status**: R2 → PASS. Feature ready for use.
