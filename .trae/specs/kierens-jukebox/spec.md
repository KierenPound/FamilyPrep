# Kieren's Jukebox (Standard Section) — Product Requirements Document

## Overview
- **Summary**: Add a new Standard dashboard section titled **"Kieren's Jukebox"** as the 8th section — after **Confirmation** — on the Home dashboard. The section opens a custom SwiftUI rich page that embeds a YouTube video player with an editorialized transport control UI (Play, Pause, Rewind, Fast Forward), reads the playlist from the bundled `final_shazam_list.csv` asset dataset, plays through tracks sequentially when the current video ends, and lets the user jump to previous/next track via the buttons.
- **Purpose**: Provide a curated, one-tap way to play Kieren's favourite Shazam'd tracks inside the FamilyPrep app without leaving the app.
- **Target Users**: Kieren + family members using the app (at home, preparing / dealing with bereavement admin, wanting a familiar soundtrack).

## Goals
- One-tap sequential playback of the entire Shazam playlist (314 CSV rows, deduped by video_id).
- Transport UI (Play / Pause / ⏮ Previous / ⏭ Next) feels like a jukebox — deterministic behaviour.
- First video_id (CSV top row) starts playback on initial **Play** press (no autostart).
- After a video finishes, the next video in the playlist starts automatically.
- The section appears *after Confirmation* in the Home list (orderIndex = 8).
- Matches the existing editorial aesthetic (Pastel canvas, inset-grouped cards, sage/ivory/dawn blue).

## Non-Goals
- Audio-only / background playback or lockscreen controls (YouTube iframe cannot do this reliably; out of scope).
- Shuffle / repeat modes, loop-one, or queue editing.
- Volume slider (defer to device volume).
- Lyrics / cover-art lookup or metadata fetching APIs — use title string verbatim from CSV, no network enrichment.
- Seek scrub bar (we only implement play/pause + prev/next).
- Persisting last-played position across launches; always start Play from track 0 on fresh enter.

## Background & Context
1. CSV asset dataset: `final_shazam_list.dataset/final_shazam_list.csv` in Assets.xcassets, 314 rows, format:
   `VIDEO_ID,"TITLE_WITH_DASH_OR_SUBTITLE_IN_QUOTES","CHANNEL_NAME"`.
   Hyphens/channel fields are messy; only video_id and the full quoted title string are reliable.
   Several duplicate video_ids exist in the list (rows 35/36, 45/XX, 65/72/74/97/146, 109/110, etc). The loader **must dedupe by video_id** preserving the first occurrence.
2. Existing navigation:
   - HomeDashboardView.swift → 7 standard sections from seed → ForEach row via NavigationLink(destination: SectionDetailView)
   - SectionDetailView richMediaDashboardSection() routes on `section.title` to 7 dashboard views; a new `"Kieren's Jukebox"` case must be added.
   - LocalDataRepository.seedStandardSections() seeds 7 standard sections via tuple list (title, youtube, sampleItems, orderIndex = enumerated from 0). Confirmation is last at index 6 / orderIndex 6. Jukebox added last → orderIndex 7 → appears after Confirmation.
3. Existing YouTubePlayerView.swift is a static WKWebView iframe (non-interactive — no JS callbacks, no play/pause control hooks, no video-end detection). Jukebox requires a NEW YouTube player (`YTJukeboxPlayerView`) with:
   - YouTube IFrame Player API (`<script src="https://www.youtube.com/iframe_api">`) + `onYouTubeIframeAPIReady` → `YT.Player('player', {... events: { onStateChange, onReady } })`.
   - WKScriptMessageHandler (`ytEvent` → postMessage body `{"event":"ready","videoId":...}` + `{"event":"stateChange","code":N}` where code ∈ {unstarted=-1, ended=0, playing=1, paused=2, buffering=3, cued=5}).
   - JS bridge commands: `playVideo()`, `pauseVideo()`, `loadVideoById(id, startSeconds:0, suggestedQuality:'hd720')`, `cueVideoById(id)` via `webView.evaluateJavaScript("player.playVideo();")`.
   - `allowsInlineMediaPlayback = true`, `mediaTypesRequiringUserActionForPlayback = []` to allow programmatic play after the *first* user tap.

## Functional Requirements
- **FR-1 New Standard section**: New "Kieren's Jukebox" PrepSection seeded at orderIndex 7 (after Confirmation), `isStandard: true`, no sample checklist items, empty YouTube URL (the player is embedded).
- **FR-2 Home row**: New row appears in HomeDashboardView — icon: `music.note.list`, tint/color: `.pink`; `sectionIcons`/`sectionColors` dicts updated so SectionRow renders correctly.
- **FR-3 SectionDetailView routing**: When `section.title == "Kieren's Jukebox"`, SectionDetailView renders `KierensJukeboxDashboardView()`. Whitelist added to rich-media guard condition (line 19 pattern).
- **FR-4 CSV playlist load**: Static struct `ShazamPlaylist` (in new file `ShazamPlaylist+Seed.swift` following [Domain]+Seed pattern) reads `final_shazam_list` NSDataAsset, parses CSV by splitting lines preserving quoted fields, dedupes by video_id keeping first occurrence. Yields array `[JukeboxTrack]` where `JukeboxTrack: Identifiable` has `id = videoID` and `title: String` (the CSV's second field — keep as-is, no splitting). Playlist count = unique video IDs only.
- **FR-5 Dashboard view layout**: KierensJukeboxDashboardView.swift —
  - PastelEditorialCanvas-style page (same SectionDetailView card outer wrapper / 16pt card pad / 20r round).
  - Page header: `Label("Kieren's Jukebox", systemImage: "music.note.list")` `.title3.bold()`, pink tint.
  - Line 1: **Now Playing** header, Track number / total (e.g. `1 / 260`) in monospaced digit style.
  - Line 2: Track title (verbatim from CSV, use Text + `.lineLimit(2)` + `.multilineTextAlignment(.leading)` for wraps).
  - **16:9 YouTube player**: fixed `.aspectRatio(16/9)`, 14pt corner radius, `maxHeight: 260` (slightly larger than SongForThePage videos to feel like a jukebox hero video stage).
  - **Transport bar**: 4 pill buttons in a ZStack/capsule row (centered, equal spacing):
    - ⏮ `"gobackward.15"` (SF Symbol) — Previous track, disabled when currentIndex == 0.
    - ▶️ / ⏸ Button — toggles Play/Pause. Shows `play.fill` when paused, `pause.fill` when playing.
    - ⏭ `"goforward.15"` — Next track, disabled when currentIndex == tracks.count - 1.
    - Buttons styled 52×52pt circular, filled (pink.opacity(0.12)) foreground pink, shadow 0.2 black/0.3r/y1. Icons: `.title` weight.
  - **Playlist scroll list** below transport bar — ForEach(tracks) row; highlight current row with pink.accent background; tap a row to jump (loads track, starts playing immediately).
- **FR-6 Initial state**: No video plays when page opens. Player is cued to track 0 (row 1 of CSV → Hue & Cry - Labour Of Love, video_id `1CYZ6q7Wr9c`) waiting, Play button shows play.fill.
- **FR-7 Play button behaviour (first press)**: On first ▶️ Play tap → JavaScript `loadVideoById(tracks[0].videoID, 0)` → then `playVideo()` → after JS bridge confirms stateChange code=1 → button flips to pause.fill.
- **FR-8 Automatic advancement to next track**: When JavaScript bridge fires `stateChange` with `code = 0` (Ended), and `currentIndex < tracks.count - 1` → increment `currentIndex` in Swift, call `loadVideoById(next).playVideo()`, update title row to new track. If index is last → stop (show play.fill, no loop, do nothing).
- **FR-9 Pause button**: Press when state = Playing → `pauseVideo()` call → button flips back to play.fill. Press Play again resumes from same position (standard YT behaviour).
- **FR-10 Previous / Next buttons**:
  - Previous (⏮): If index > 0, decrement; loadVideoById; playVideo(). If already 0 → disabled (greyed) and no-op.
  - Next (⏭): If index < last, increment; loadVideoById; playVideo(). If last → disabled and no-op.
  - Manual tap-row in playlist: sets currentIndex, loadVideoById, playVideo().
- **FR-11 Error / guard state**: Invalid/missing dataset yields ContentUnavailableView with message + "Playlist CSV missing in Assets" (never crash on empty array — `tracks.isEmpty` handled).

## Non-Functional Requirements
- **NFR-1 Correctness (no silent failures)**: JS messages that aren't valid JSON or lack expected `event` key are silently ignored (no throws, no force-try in @MainActor callbacks).
- **NFR-2 Main actor**: All player view state, WKWebView manipulation, and SwiftUI state updates happen on `@MainActor`. Both the view struct and YTJukeboxPlayerView's Coordinator marked `@MainActor`.
- **NFR-3 Rendering stability**: YouTube hero frame locked at `.frame(maxWidth:.infinity) → aspectRatio(16/9) → maxHeight: 260 → clipped → cornerRadius(14)`. No layout feedback loops.
- **NFR-4 Compile-time correctness**: No warnings / no shadowing of generic `Data` (use `Foundation.Data`, or rename track collection local to `items` or `tracks`).
- **NFR-5 Persistence of playlist**: Deduplicated track list is a computed static let — parsed once. Do not re-parse CSV on every body call.

## Constraints
- **Technical**: Must use YouTube IFrame Player API + WKWebView + WKScriptMessageHandler bridge. YouTube Data API v3 / GoogleSignIn / Spotify / AVFoundation not permitted (no audio assets bundled).
- **Technical**: Use bundled NSDataAsset (`final_shazam_list`) only — no network fetch of Shazam library.
- **Business**: Dedupe by video_id so we don't see the same track 4× scroll back-to-back.
- **Dependencies**: No 3rd-party pods/SPM. All native SwiftUI + WebKit.
- **Dependencies**: Existing `PastelEditorialCanvas.swift` / card metrics from existing dashboards.
- **Platform**: iOS 18+ only (family of two devices — OK to assume latest).

## Assumptions
- User has working internet when using Jukebox.
- User accepts the first-play "tap Play" gesture (Apple requires user gesture before first autoplay — we can't fully circumvent, but after first play subsequent advances will be programmatic and work because the iframe received a user gesture earlier).
- `Foundation.Data` can hold the 30KB CSV easily (NSDataAsset).
- CSV is UTF-8 encoded with LF line endings and `"…"` quoted strings only; no embedded `\n` inside a quote (file inspection confirms).

## Acceptance Criteria

### AC-1: Jukebox appears after Confirmation on Home
- **Type**: `rule`
- **Given**: App launched with no prior sections → seed runs.
- **When**: User scrolls to end of Home dashboard list.
- **Then**: 8th row exists after Confirmation with title "Kieren's Jukebox", icon `music.note.list`, pink accent row color, star ⭐ Standard badge, `orderIndex == 7`.
- **Pass Condition**: Home list order matches seed array → last row matches.
- **Evidence**: Read `LocalDataRepository.seedStandardSections()` tuples + verify sectionIcons/sectionColors dicts.

### AC-2: First Play behaviour starts CSV row 1 (Hue & Cry)
- **Type**: `rule`
- **Given**: Freshly opened Jukebox page; player cued but not playing (Play button visible).
- **When**: User taps Play button ONCE.
- **Then**: YouTube iframe loads video_id = `1CYZ6q7Wr9c`; plays from t=0; stateChange code=1 (playing) received via JS bridge; Now Playing line shows `1 / {uniqueCount}` and the CSV title from row 1.
- **Pass Condition**: View state after first tap has `currentIndex == 0` and the YTJukeboxPlayerView's `playerState == .playing`.
- **Evidence**: `ShazamPlaylist.items.first?.videoID == "1CYZ6q7Wr9c"` check.

### AC-3: Advancement auto-plays next track on video end
- **Type**: `rule`
- **Given**: Playing track N; bridge knows video state.
- **When**: Bridge posts `stateChange` with `code = 0` (Ended) AND index < last.
- **Then**: currentIndex increases by 1 on Main thread; `loadVideoById(next)` + `playVideo()` called via JS evaluate; next-track title and N+1/Count text appear.
- **Pass Condition**: Trigger by tapping Next fast is equivalent (manual equivalent test). Check that stateChange=0 handler advances index via unit/logging via print or debug output or testable increment.
- **Evidence**: YTJukeboxPlayerView.Coordinator `userContentController(_:didReceive:)` body handles `code == 0` case with `onEnded()` closure which is wired to increment-and-play.

### AC-4: Transport controls work as specified
- **Type**: `rule`
- **Given**: Jukebox page open.
- **When**: Tap Play → Pause → Play → Next → Next → Previous → Previous → Previous (at 0) → Next (at last+1 stop).
- **Then**:
  - Play/Pause icons flip exactly with playing state.
  - Next disabled at last index; Previous disabled at index 0 (not enabled-looking).
  - Rapid taps never cause index < 0 or index >= tracks.count (bounds safe).
- **Pass Condition**: Manual interactive click-path or reading code + `disabled(index == 0)` / `disabled(index == tracks.endIndex-1)`.
- **Evidence**: Read `transportControls` computed view block + Previous/Next action bodies with guard.

### AC-5: Playlist deduped by video_id (first occurrence kept)
- **Type**: `rule`
- **Given**: Raw CSV has 314 lines with numerous repeated video_ids such as `Bol6PsSSgRU` (lines 35+36), `26PAgklYYvo` (×5).
- **When**: `ShazamPlaylist.items` is computed.
- **Then**: All elements have unique `videoID` (Set vs array count matches). Order is preserved-first. Hue & Cry is entry 0.
- **Pass Condition**: `items.count < 314` && `Set(items.map { $0.id }).count == items.count`.
- **Evidence**: Static `ShazamPlaylist+Seed.swift` parse output inspected in Swift.

### AC-6: Jukebox visual style matches existing dashboards (editorial, sage/ivory mesh)
- **Type**: `rubric`
- **Dimension**: Editorial aesthetic consistency with the 7 existing dashboard pages.
- **Scale**: 1-5
- **Anchors**: 1 = looks alien / jarring, different corner radius / padding from peers; 3 = functional but missing polish (card bg, tint color mismatch); 5 = indistinguishable structural parity with e.g. LegalDocumentsDashboardView (same outer card: `VStack(spacing:14) → cardBackground → inner pad 16pt, headline spacing, label+icon+accent header)
- **Pass Threshold**: >= 4
- **Evidence**: Read layout + compare modifier chain with LegalDocumentsDashboardView line 70.. (photosSection pattern).

### AC-7: No compiler warnings / zero diagnostics
- **Type**: `rule`
- **Given**: Implementation complete in Xcode.
- **When**: Run `GetDiagnostics` (IDE Swift compiler) OR `swift build` / xcodebuild build.
- **Then**: 0 errors; 0 warnings about shadowing `Data` / unused vars / main-actor precondition failures.
- **Pass Condition**: IDE diagnostics pane has 0 yellow + 0 red issues for the 4 files we touched.
- **Evidence**: Post-build GetDiagnostics output.

## Open Questions
- [ ] **Loop at end (back to track 1)?** Kieren said stop at end in description. Not implementing unless asked.
- [ ] **Pink colour?** Icon tint `.pink` proposed. Confirm — if you want sage/dawn-blue family, say.
- [ ] **CSV title splitting.** Many titles are `"<hyphenated string>"` (e.g. `"Hue & Cry - Labour Of Love"`). Currently kept whole verbatim in AC. Want split into artist+title in 2-line stack? If so → spec change.
