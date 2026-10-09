import SwiftUI
import WebKit

@MainActor
struct YTJukeboxPlayerView: UIViewRepresentable {
    let videoID: String
    let isPlaying: Bool
    let forcePlayID: UUID
    let onReady: () -> Void
    let onStateChange: (Int) -> Void
    let onEnded: () -> Void
    let onError: (Int) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let userContent = WKUserContentController()
        userContent.add(context.coordinator, name: "ytEvent")
        context.coordinator.userContentController = userContent

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContent
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        context.coordinator.webView = { [weak webView] in return webView }
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.setContentHuggingPriority(.required, for: .vertical)
        webView.setContentCompressionResistancePriority(.required, for: .vertical)
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
        return webView
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: WKWebView, context: Context) -> CGSize? {
        let width = proposal.width ?? 320
        let height = (width * 9) / 16
        return CGSize(width: width, height: height)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let cleanID = Self.sanitizeVideoID(videoID)
        let coord = context.coordinator

        coord.onReady = onReady
        coord.onStateChange = onStateChange
        coord.onEnded = onEnded
        coord.onError = onError

        if coord.needsInitialHTML {
            coord.needsInitialHTML = false
            coord.lastLoadedID = cleanID
            coord.lastIsPlaying = isPlaying
            coord.lastForcePlayID = forcePlayID
            coord.suppressAllStateChangeForVideoID = cleanID
            let html = Self.playerHTML(initialVideoID: cleanID, autoplay: false)
            webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com")!)
            return
        }

        let idChanged = coord.lastLoadedID != cleanID
        let playChanged = coord.lastIsPlaying != isPlaying
        let forcePlayTriggered = coord.lastForcePlayID != forcePlayID
        let needsAction = idChanged || playChanged || forcePlayTriggered
        guard needsAction else { return }

        let isFirstPlayEver = !coord.didEverPlay && (isPlaying || forcePlayTriggered)
        let mustActuallyPlay = isPlaying || forcePlayTriggered

        let js: String
        if mustActuallyPlay {
            if idChanged || isFirstPlayEver || forcePlayTriggered {
                coord.suppressAllStateChangeForVideoID = cleanID
                js = "if (typeof player !== 'undefined' && player && player.loadVideoById) { player.loadVideoById('\(cleanID)', 0, 'hd720'); }"
                coord.didEverPlay = true
                coord.suppressNextPausedStateChange = true
                coord.awaitingPlayingConfirmationID = cleanID
                coord.schedulePlayRetry(videoID: cleanID)
            } else {
                js = "if (typeof player !== 'undefined' && player && player.playVideo) { player.playVideo(); }"
            }
        } else {
            if idChanged {
                coord.suppressAllStateChangeForVideoID = cleanID
                js = "if (typeof player !== 'undefined' && player && player.cueVideoById) { player.cueVideoById('\(cleanID)', 0, 'hd720'); }"
            } else {
                js = "if (typeof player !== 'undefined' && player && player.pauseVideo) { player.pauseVideo(); }"
            }
        }

        coord.lastLoadedID = cleanID
        coord.lastIsPlaying = isPlaying
        coord.lastForcePlayID = forcePlayID
        Task { @MainActor in
            _ = try? await webView.evaluateJavaScript(js)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onReady: onReady,
            onStateChange: onStateChange,
            onEnded: onEnded,
            onError: onError
        )
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var onReady: () -> Void
        var onStateChange: (Int) -> Void
        var onEnded: () -> Void
        var onError: (Int) -> Void
        var lastLoadedID: String = ""
        var lastIsPlaying: Bool = false
        var lastForcePlayID: UUID = UUID()
        var needsInitialHTML: Bool = true
        var didEverPlay: Bool = false
        var suppressNextPausedStateChange: Bool = false
        var suppressAllStateChangeForVideoID: String = ""
        var awaitingPlayingConfirmationID: String = ""
        var webView: () -> WKWebView?
        private var playRetryTask: Any? = nil
        weak var userContentController: WKUserContentController?

        init(onReady: @escaping () -> Void,
             onStateChange: @escaping (Int) -> Void,
             onEnded: @escaping () -> Void,
             onError: @escaping (Int) -> Void) {
            self.onReady = onReady
            self.onStateChange = onStateChange
            self.onEnded = onEnded
            self.onError = onError
            self.webView = { nil }
        }

        deinit {
            Task { @MainActor [userContentController] in
                userContentController?.removeScriptMessageHandler(forName: "ytEvent")
            }
        }

        nonisolated func userContentController(_ userContentController: WKUserContentController,
                                                didReceive message: WKScriptMessage) {
            Task { @MainActor [weak self] in
                self?.handle(message: message)
            }
        }

        private func handle(message: WKScriptMessage) {
            guard message.name == "ytEvent" else { return }
            guard let body = message.body as? [String: Any] else { return }
            guard let event = body["event"] as? String else { return }

            switch event {
            case "ready":
                onReady()
            case "stateChange":
                    guard let code = body["code"] as? Int else { return }
                    // Drop any state change that matches video we just fired load/cue on — until we
                    // explicitly see code==1 Playing for that video, we don't update SwiftUI
                    // about its transitional -1 / 2 / 3 noise during that load.
                    if !suppressAllStateChangeForVideoID.isEmpty {
                        if code != 1 && code != 0 {
                            return
                        }
                        if code == 1 || code == 0 {
                            suppressAllStateChangeForVideoID = ""
                        }
                    }
                    if suppressNextPausedStateChange {
                        if code == 2 || code == -1 {
                            suppressNextPausedStateChange = false
                            return
                        }
                        if code == 1 || code == 0 {
                            suppressNextPausedStateChange = false
                        }
                    }
                    if code == 1 {
                        awaitingPlayingConfirmationID = ""
                        self.cancelPlayRetry()
                    }
                    onStateChange(code)
                    if code == 0 {
                        onEnded()
                    }
                case "error":
                    guard let code = body["code"] as? Int else { return }
                    onError(code)
                default:
                    break
                }
        }

        @MainActor
        func schedulePlayRetry(videoID: String) {
            self.cancelPlayRetry()
            let task = Task { @MainActor [weak self, weak webView = self.webView()] in
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard Task.isCancelled == false else { return }
                guard let self = self,
                      self.awaitingPlayingConfirmationID == videoID,
                      self.lastIsPlaying == true,
                      self.lastLoadedID == videoID else { return }
                let retryJS = """
                (function(){
                  try {
                    if (typeof player === 'undefined' || !player || !player.playVideo) return false;
                    var st = player.getPlayerState && player.getPlayerState();
                    if (st === 1) return true;
                    if (st === -1 || st === 5) {
                      if (player.loadVideoById) { player.loadVideoById('\(videoID)', 0, 'hd720'); }
                    } else {
                      player.playVideo();
                    }
                    return true;
                  } catch(e) { return false; }
                })();
                """
                Task { @MainActor in
                    _ = try? await webView?.evaluateJavaScript(retryJS)
                }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    guard Task.isCancelled == false else { return }
                    if self.awaitingPlayingConfirmationID == videoID, self.lastIsPlaying == true {
                        let finalJS = "if (typeof player !== 'undefined' && player && player.playVideo) { player.playVideo(); }"
                        _ = try? await webView?.evaluateJavaScript(finalJS)
                    }
                }
            }
            self.playRetryTask = task
        }

        @MainActor
        func cancelPlayRetry() {
            if let t = playRetryTask as? Task<Void, Never> {
                t.cancel()
            }
            playRetryTask = nil
        }
    }

    private static func sanitizeVideoID(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if let direct = YouTubePlayerView.extractVideoID(from: trimmed), !direct.isEmpty {
            let legal = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
            let filtered = String(direct.unicodeScalars.filter { legal.contains($0) })
            return String(filtered.prefix(11))
        }
        let legal = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        let filtered = String(trimmed.unicodeScalars.filter { legal.contains($0) })
        return String(filtered.prefix(11))
    }

    private static func playerHTML(initialVideoID: String, autoplay: Bool) -> String {
        let autoplayFlag = autoplay ? "1" : "0"
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <style>
                html, body { margin:0; padding:0; background:#000; height:100%; width:100%; overflow:hidden; }
                #player { position:absolute; top:0; left:0; width:100%; height:100%; }
            </style>
            <script>
                var player;
                function onYouTubeIframeAPIReady() {
                    player = new YT.Player('player', {
                        height: '100%',
                        width: '100%',
                        videoId: '\(initialVideoID)',
                        playerVars: {
                            playsinline: 1,
                            rel: 0,
                            modestbranding: 1,
                            fs: 1,
                            controls: 1,
                            disablekb: 0,
                            iv_load_policy: 3,
                            cc_load_policy: 0,
                            cc_lang_pref: 'en',
                            hl: 'en',
                            autoplay: \(autoplayFlag)
                        },
                        events: {
                            'onReady': function(e) {
                                window.webkit.messageHandlers.ytEvent.postMessage({event:'ready'});
                            },
                            'onStateChange': function(e) {
                                window.webkit.messageHandlers.ytEvent.postMessage({event:'stateChange', code:e.data});
                            },
                            'onError': function(e) {
                                window.webkit.messageHandlers.ytEvent.postMessage({event:'error', code:e.data});
                            }
                        }
                    });
                }
            </script>
            <script src="https://www.youtube.com/iframe_api"></script>
        </head>
        <body>
            <div id="player"></div>
        </body>
        </html>
        """
    }
}
