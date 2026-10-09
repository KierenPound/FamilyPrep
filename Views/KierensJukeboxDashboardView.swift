import SwiftUI
import WebKit

@MainActor
struct KierensJukeboxDashboardView: View {
    private let tracks = ShazamPlaylist.tracks

    @State private var currentIndex: Int = 0
    @State private var isPlaying: Bool = false
    @State private var isPlayerReady: Bool = false
    @State private var forcePlayID: UUID = UUID()
    @State private var currentPlaybackIntentionID: UUID = UUID()
    @State private var suppressPausedUntil: Date = .distantPast

    var body: some View {
        if tracks.isEmpty {
            ContentUnavailableView(
                "Playlist Missing",
                systemImage: "music.note.list",
                description: Text("Playlist CSV missing in Assets — expected final_shazam_list dataset.")
            )
        } else {
            VStack(alignment: .leading, spacing: 28) {
                jukeboxHeroSection
                playlistSection
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Jukebox Hero

    private var jukeboxHeroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Kieren's Jukebox",
                          systemImage: "music.note.list",
                          tint: .pink)

            cardBackground {
                VStack(alignment: .leading, spacing: 14) {
                    heroPlayerView
                    nowPlayingRow
                    transportRow
                }
                .padding(16)
            }
        }
    }

    @State private var didAutoplayOnOpen: Bool = false

    private var heroPlayerView: some View {
        let accent = Color.pink
        return YTJukeboxPlayerView(
            videoID: currentTrack.id,
            isPlaying: isPlaying,
            forcePlayID: forcePlayID,
            onReady: {
                isPlayerReady = true
                if !didAutoplayOnOpen && currentIndex == 0 {
                    didAutoplayOnOpen = true
                    let freshIntention = UUID()
                    currentPlaybackIntentionID = freshIntention
                    forcePlayID = freshIntention
                    suppressPausedUntil = Date().addingTimeInterval(1.2)
                    isPlaying = true
                    scheduleFinalPlayEnforcer(
                        intentionID: freshIntention,
                        videoID: tracks[0].id,
                        extraRetry: true
                    )
                }
            },
            onStateChange: { code in
                switch code {
                case 1:
                    isPlaying = true
                case 2:
                    if Date() >= suppressPausedUntil {
                        isPlaying = false
                    } else {
                        isPlaying = true
                    }
                case 3:
                    isPlaying = true
                case -1, 5:
                    if Date() >= suppressPausedUntil {
                        isPlaying = false
                    } else {
                        isPlaying = true
                    }
                case 0:
                    isPlaying = false
                default:
                    break
                }
            },
            onEnded: {
                if currentIndex < tracks.count - 1 {
                    currentIndex = currentIndex + 1
                } else {
                    isPlaying = false
                }
            },
            onError: { code in
                guard (code == 101 || code == 150) && currentIndex < tracks.count - 1 else { return }
                currentIndex = currentIndex + 1
            }
        )
        .onAppear {
            if !didAutoplayOnOpen && tracks.isEmpty == false {
                let freshIntention = UUID()
                currentPlaybackIntentionID = freshIntention
                forcePlayID = freshIntention
                suppressPausedUntil = Date().addingTimeInterval(1.2)
                isPlaying = true
                scheduleFinalPlayEnforcer(
                    intentionID: freshIntention,
                    videoID: tracks[0].id,
                    extraRetry: true
                )
            }
        }
        .onChange(of: currentIndex) { oldIdx, newIdx in
            if oldIdx != newIdx {
                let freshIntention = UUID()
                currentPlaybackIntentionID = freshIntention
                forcePlayID = freshIntention
                suppressPausedUntil = Date().addingTimeInterval(1.2)
                isPlaying = true
                scheduleFinalPlayEnforcer(
                    intentionID: freshIntention,
                    videoID: currentTrack.id,
                    extraRetry: false
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .aspectRatio(16/9, contentMode: .fit)
        .frame(maxHeight: 260)
        .background(Color.black.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accent.opacity(0.3), lineWidth: 0.8)
        )
        .zIndex(0)
    }

    private func scheduleFinalPlayEnforcer(
        intentionID: UUID,
        videoID: String,
        extraRetry: Bool
    ) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard Task.isCancelled == false else { return }
            guard currentPlaybackIntentionID == intentionID else { return }
            guard currentTrack.id == videoID else { return }
            if isPlaying == false {
                isPlaying = true
                forcePlayID = UUID()
            }
            if extraRetry {
                let kick = forcePlayID
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    guard Task.isCancelled == false else { return }
                    guard currentPlaybackIntentionID == intentionID else { return }
                    guard currentTrack.id == videoID else { return }
                    if isPlaying == false {
                        isPlaying = true
                        forcePlayID = UUID()
                    } else if forcePlayID == kick {
                        forcePlayID = UUID()
                    }
                }
            }
        }
    }

    private var nowPlayingRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label("Now Playing", systemImage: "play.rectangle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.pink)
                Spacer()
                Text("\(currentIndex + 1) / \(tracks.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text(currentTrack.title)
                .font(.body.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.primary)
        }
    }

    private var transportRow: some View {
        HStack(spacing: 24) {
            Button(action: previousTrack) {
                Image(systemName: "backward.end.fill")
                    .font(.title2)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(Color.pink.opacity(0.12))
                    )
                    .foregroundStyle(.pink)
                    .shadow(color: .black.opacity(0.03), radius: 1, y: 1)
            }
            .buttonStyle(.plain)
            .disabled(currentIndex == 0)
            .contentShape(Rectangle())

            Button(action: togglePlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title.weight(.bold))
                    .frame(width: 68, height: 68)
                    .background(
                        Circle()
                            .fill(Color.pink)
                    )
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            Button(action: nextTrack) {
                Image(systemName: "forward.end.fill")
                    .font(.title2)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(Color.pink.opacity(0.12))
                    )
                    .foregroundStyle(.pink)
                    .shadow(color: .black.opacity(0.03), radius: 1, y: 1)
            }
            .buttonStyle(.plain)
            .disabled(currentIndex == tracks.endIndex - 1)
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
    }

    // MARK: - Playlist

    private var playlistSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Playlist",
                          systemImage: "list.number",
                          tint: .pink)

            cardBackground {
                LazyVStack(spacing: 0) {
                    ForEach(Array(tracks.enumerated()), id: \.element.id) { (index, track) in
                        playlistRow(at: index, track: track)
                        if index < tracks.endIndex - 1 {
                            Divider().padding(.leading, 54).opacity(0.4)
                        }
                    }
                }
                .padding(10)
            }
        }
    }

    private func playlistRow(at index: Int, track: JukeboxTrack) -> some View {
        let isCurrent = index == currentIndex
        return HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isCurrent ? Color.pink.opacity(0.18) : Color.pink.opacity(0.07))
                    .frame(width: 36, height: 36)
                Image(systemName: iconName(forRow: index))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.pink)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.subheadline.weight(isCurrent ? .semibold : .regular))
                    .foregroundStyle(isCurrent ? .primary : .primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)

                Text(isCurrent ? (isPlaying ? "Playing" : "Paused") : "Track \(index + 1)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(isCurrent ? .pink : .secondary)
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isCurrent ? Color.pink.opacity(0.10) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if index == currentIndex {
                forcePlayID = UUID()
                currentPlaybackIntentionID = UUID()
                suppressPausedUntil = Date().addingTimeInterval(1.2)
                isPlaying = true
                scheduleFinalPlayEnforcer(
                    intentionID: currentPlaybackIntentionID,
                    videoID: track.id,
                    extraRetry: true
                )
            } else {
                currentIndex = index
            }
        }
    }

    private func iconName(forRow index: Int) -> String {
        let isCurrent = index == currentIndex
        if isCurrent && isPlaying { return "speaker.wave.2.fill" }
        if isCurrent { return "play.fill" }
        return "\(index + 1).circle"
    }

    // MARK: - Actions

    private var currentTrack: JukeboxTrack {
        let clamped = min(max(0, currentIndex), tracks.count - 1)
        return tracks[clamped]
    }

    private func togglePlayPause() {
        isPlaying.toggle()
    }

    private func previousTrack() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    private func nextTrack() {
        guard currentIndex < tracks.count - 1 else {
            isPlaying = false
            return
        }
        currentIndex += 1
    }

    // MARK: - Shared Section Helpers (parity with other dashboards)

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
        KierensJukeboxDashboardView()
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
    }
    .background(Color(.systemGroupedBackground))
}
