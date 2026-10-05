# Kieren's Jukebox — Implementation Plan

## Task 1: Seed + Navigation (new section + home row wiring)
- **Status**: `pending`
- **Priority**: high
- **Depends On**: None
- **Description**:
  - Add 8th tuple `("Kieren's Jukebox", "", [])` to `standardTitles` array in [LocalDataRepository.swift](file:///Volumes/KierenSSD/FamilyPrep/FamilyPrep/FamilyPrep/Services/LocalDataRepository.swift#L59-L154) `seedStandardSections()` (after Confirmation). Confirmation is orderIndex 6 → new one gets orderIndex 7 (preserved via `.enumerated()`).
  - Update [HomeDashboardView.swift](file:///Volumes/KierenSSD/FamilyPrep/FamilyPrep/FamilyPrep/Views/HomeDashboardView.swift#L8-L26) `sectionIcons` and `sectionColors` dicts with new entry `"Kieren's Jukebox"` → icon `"music.note.list"`, color `.pink`.
  - Update [SectionDetailView.swift](file:///Volumes/KierenSSD/FamilyPrep/FamilyPrep/FamilyPrep/Views/SectionDetailView.swift#L17-L78):
    - Add `section.title == "Kieren's Jukebox"` to the rich-media whitelist if-condition on line 19.
    - Add a new `else if` branch inside `richMediaDashboardSection` that returns `KierensJukeboxDashboardView()`.
- **Acceptance Criteria Addressed**: AC-1
- **Test Requirements**:
  - `rule` TR-1.1: Home list shows exactly 8 standard sections on fresh seed; 8th is "Kieren's Jukebox" with orderIndex = 7. Evidence: `standardTitles.count == 8` at compile-time + SectionDetailView routing contains new title string.
  - `rubric` TR-1.2: SectionDetail routing uniformity. Scale 1-5. 1=new case breaks switch pattern or repeats WhatToDoFirst fallback; 3=works but placement weird; 5=case in same block with same 1-tuple spacing as neighbours, whitelist predicate updated uniformly. Threshold >= 4.
- **Notes**: `seedStandardSections()` only runs when there's no on-disk data. For existing installs where user already has the 7 sections, the 8th won't appear without a migration. Since this is an MVP / family of 2 devices, manual delete + reinstall OR migration `try addSection(title:)` of "Kieren's Jukebox" as standard on next load check is acceptable. Out of scope for Task 1 unless required later.

## Task 2: Playlist seed (CSV → Swift typed array, dedupe, keep order)
- **Status**: `pending`
- **Priority**: high
- **Depends On**: None
- **Description**:
  - New file `ShazamPlaylist+Seed.swift` under `FamilyPrep/Models/` following the [Domain]+Seed pattern (per project_memory).
  - Define `struct JukeboxTrack: Identifiable, Hashable { let id: String ; let title: String }` where `id == videoID` (11-char).
  - Define `enum ShazamPlaylist` + static `static let tracks: [JukeboxTrack] = { ... }()` computed once at init.
  - Load `NSDataAsset(name: "final_shazam_list")`. UTF-8-decode to String. Split by `\n`. For each non-empty line, parse the three columns respecting `"` quoted fields:
    - Handwritten small CSV parser is acceptable, use Character-by-character state machine OR split on `,` and handle `"…"` quoting — since file has no embedded newlines/commas inside quotes (inspected above), either approach works.
    - Field 1 → `videoID` (trim anything before the leftmost `,`). Filter to legal chars, prefix(11).
    - Field 2 → `title` (strip surrounding `"`). Keep verbatim, don't try to split artist.
    - Field 3 → channel name; discard.
  - Dedupe by videoID preserving FIRST occurrence. Use `var seen = Set<String>(); compactMap` returning nil when `seen.insert(videoID).inserted == false`.
  - Fallback to `[]` if NSDataAsset nil — never fatalError. `ContentUnavailableView` will show on dashboard.
- **Acceptance Criteria Addressed**: AC-5
- **Test Requirements**:
  - `rule` TR-2.1: `ShazamPlaylist.tracks.first?.id == "1CYZ6q7Wr9c"` (Hue & Cry row 1). Evidence: static let accessible + equality holds.
  - `rule` TR-2.2: `Set(ShazamPlaylist.tracks.map(\.id)).count == ShazamPlaylist.tracks.count` (all unique).
  - `rule` TR-2.3: `ShazamPlaylist.tracks.count < 314` (dedup occurred).
  - `rubric` TR-2.4: CSV parsing robustness. Scale 1-5. 1=force try! crashes on bad data; 3=works for this file but ignores quotes incorrectly; 5=parser reads CSV deterministically, no throw, no force-unwrap on asset/string conversion, `guard` exits on empty. Threshold >= 4.

## Task 3: YouTube IFrame bridge player with 2-way JS ↔ Swift callbacks
- **Status**: `pending`
- **Priority**: high
- **Depends On**: None
- **Description**:
  - New file `YTJukeboxPlayerView.swift` under `FamilyPrep/Views/`. Do NOT modify existing `YouTubePlayerView.swift` (SongForThePage sections still use the static embed iframe; don't break them).
  - `struct YTJukeboxPlayerView: UIViewRepresentable { @MainActor class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler { } }`
  - Input bindings via parameters (not @Environment — composable):
    ```swift
    let videoID: String
    let isPlaying: Bool
    let onReady: () -> Void
    let onStateChange: (Int) -> Void    // -1..5
    let onEnded: () -> Void             // convenience: called when code==0
    ```
  - `makeUIView` creates `WKWebView` config with:
    - `userContentController.add(coordinator, name: "ytEvent")`
    - inline playback + no user-action-for-playback → matches existing YTPV
    - nonPersistent data store
    - `.isOpaque = false`, scroll disabled, clear bg
  - HTML payload has `<script src="https://www.youtube.com/iframe_api"></script>`; player options:
    ```swift
    height: '100%', width: '100%', videoId: firstVideoID,
    playerVars: { playsinline: 1, rel: 0, modestbranding: 1, fs: 1, controls: 0, disablekb: 1 },
    events: { onReady: function(e) { window.webkit.messageHandlers.ytEvent.postMessage({event:'ready'}) },
              onStateChange: function(e) { window.webkit.messageHandlers.ytEvent.postMessage({event:'stateChange', code: e.data}) } }
    ```
    - Set `controls=0, disablekb=1` so only SwiftUI transport buttons control playback (consistent UX).
  - `updateUIView`:
    - If `videoID != coordinator.lastLoadedID` → `evaluateJavaScript("player.loadVideoById('\(sanitized)',0);")` (when `isPlaying`) OR `player.cueVideoById(...)` otherwise.
    - If `isPlaying` changed from last → call `player.playVideo()` or `player.pauseVideo()`.
  - Coordinator `userContentController(_:didReceive:)` → decode JSON body `{event:, code:?}`; call `onReady`, `onStateChange(code)`, and if `code == 0` call `onEnded()`. Catch all failures silently.
- **Acceptance Criteria Addressed**: AC-2, AC-3, AC-4, AC-7
- **Test Requirements**:
  - `rule` TR-3.1: HTML string validates that iframe_api script src is set, `playerVars` includes controls=0, disablekb=1, playsinline=1, rel=0, modestbranding=1.
  - `rule` TR-3.2: `sanitizeVideoID` enforces prefix(11) + legal charset, same regex/filter approach used in YouTubePlayerView (reuse or mirror, but don't call it from here to avoid tight coupling if file stays standalone is ok too — mirror is okay).
  - `rule` TR-3.3: JS → Swift message handler names unique, no collisions across multiple web views (use unique handler name `ytEvent` and not shared).
  - `rubric` TR-3.4: Main actor correctness. Scale 1-5. 1=non-main actor state changes with warnings; 3=works but hacks around; 5=struct marked @MainActor per project rules, Coordinator class @MainActor, evaluateJavaScript completion dispatching to MainActor only. Threshold >= 4.
  - `rubric` TR-3.5: Memory / retain cycle safety. Scale 1-5. 1=unowned self breaks; 3=leaks coordinator via scriptMessageHandler without explicit removal; 5=coordinator deinit removesScriptMessageHandlerForName("ytEvent"). Threshold >= 4.

## Task 4: KierensJukeboxDashboardView.swift (hero + transport + playlist UI + state machine)
- **Status**: `pending`
- **Priority**: high
- **Depends On**: Task 2, Task 3
- **Description**:
  - New file under Views, `@MainActor struct KierensJukeboxDashboardView: View`.
  - State:
    ```swift
    private let tracks = ShazamPlaylist.tracks
    @State private var currentIndex: Int = 0
    @State private var isPlaying: Bool = false
    @State private var videoID: String { tracks[currentIndex].id }
    ```
    - Guard `tracks.isEmpty` → show ContentUnavailableView.
  - Layout (sticking to existing dashboard card aesthetic):
    - **Hero player section** (top card, full-width 16:9, radius 14, maxHeight 260):
      ```
      VStack(alignment: .leading, spacing: 14) {
        header (Label+title)
        heroPlayerCard
          .frame(maxWidth:.infinity)
          .aspectRatio(16/9, contentMode: .fit)
          .frame(maxHeight: 260)
          .clipped().cornerRadius(14)
          .overlay(stroke pink.opacity(0.3), lineWidth 0.8)
        nowPlayingRow (track N / total + title)
        transportRow (Previous / PlayPause / Next)
        playlistSection (title "Up Next" + ForEach list w/ current row accent + tap to jump)
      }
      .padding(16)
      ```
    - **Now Playing row**: 2-line vertical stack — label (Now Playing, pink tint) above; title (monospaced digits for counter, then Text + title, `.lineLimit(2)`, `.fixedSize(horizontal: false, vertical: true)`)
    - **Transport bar**: 3 buttons spaced evenly inside a capsule.
      - Previous: `"gobackward.15"` SF symbol, `.disabled(currentIndex == 0)`, action `guard currentIndex > 0 else { return }; currentIndex -= 1; isPlaying = true`
      - Play/Pause: `.frame(width: 68, height: 68)`, `.tint(.pink)`, `.buttonStyle(.borderedProminent)`, toggles `isPlaying`
      - Next: `"goforward.15"`, `.disabled(currentIndex == tracks.count - 1)`, action `guard currentIndex < tracks.count - 1 else { return }; currentIndex += 1; isPlaying = true`
    - **Playlist list**: Up to 12 visible rows; ScrollView inside VStack; each row `HStack { sfSymbol "play.fill" for current; title }.contentShape(Rectangle()).onTapGesture { currentIndex = $0; isPlaying = true }`. Current row pink.opacity(0.12) highlight, rounded-rect 12r.
  - YTJukeboxPlayerView wiring:
    - Pass `videoID: videoID, isPlaying: isPlaying`.
    - `onEnded`:
      ```swift
      if currentIndex < tracks.count - 1 {
          currentIndex += 1
          isPlaying = true
      } else {
          isPlaying = false
      }
      ```
    - `onStateChange`: Keep a debug print for development; future hook, not used for core.
- **Acceptance Criteria Addressed**: AC-1, AC-2, AC-3, AC-4, AC-6, AC-7
- **Test Requirements**:
  - `rule` TR-4.1: View guard `tracks.isEmpty` has ContentUnavailableView path; never index-out-of-range.
  - `rule` TR-4.2: Transport action functions don't allow overshoot: try to decrement when index=0 → stays 0; increment when index=last → stays last, `isPlaying = false` for last-tap-next.
  - `rule` TR-4.3: 16:9 hero has explicit `.frame(maxHeight: 260)` plus `.aspectRatio(16/9, contentMode: .fit)` + corner radius 14. Matches project rules for video embeds.
  - `rubric` TR-4.4: Editorial aesthetic parity with LegalDocumentsDashboardView. Scale 1-5. 1=jarring; 3=workable; 5=same padding pattern, header icon+tint format, stroke overlay pattern. Threshold >= 4.
  - `rubric` TR-4.5: Optimistic UI toggle pattern (isPlaying flips *before* JS confirm — matches project_memory's optimistic UI rule → feel "zero delay"). Scale 1-5. 1=waits for JS ready → lag; 3=toggles later; 5=immediate flip on Main thread. Threshold >= 4.
  - `rubric` TR-4.6: Current playlist row readability (2-line wrap, not truncated ellipsis). Scale 1-5. 1=truncates `.lineLimit(1)`; 3=ok; 5=uses Text + `.lineLimit(2)` + `.minimumScaleFactor(0.85)` per project rules. Threshold >= 4.

## Task 5: Compile + Verify (GetDiagnostics / build)
- **Status**: `pending`
- **Priority**: high
- **Depends On**: Task 1, Task 2, Task 3, Task 4
- **Description**: Run `GetDiagnostics`, resolve warnings, ensure 0 errors 0 warnings for all 4 touched files + 2 new files. Ensure existing 7 dashboards + Song-for-page YouTubePlayerView still compiles without regression (didn't break them).
- **Acceptance Criteria Addressed**: AC-7
- **Test Requirements**:
  - `rule` TR-5.1: GetDiagnostics → 0 errors AND 0 warnings.
  - `rule` TR-5.2: grep/scan for `Data` generic name in new files is non-shadowing (no `func doThing<Data>` etc) — covered by build success.
  - `rule` TR-5.3: `WhatToDoFirstDashboardView` + `YouTubePlayerView` untouched or have no source changes from HEAD 5c24d6c (git diff clean for them).
