import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String
    let allowFullscreen: Bool = true

    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard !videoID.isEmpty else {
            webView.loadHTMLString(emptyPlaceholderHTML, baseURL: nil)
            return
        }
        if context.coordinator.lastLoadedID == videoID { return }
        context.coordinator.lastLoadedID = videoID
        let html = embedHTML(for: videoID)
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com")!)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastLoadedID: String = ""
    }

    private var emptyPlaceholderHTML: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <style>
                html, body { margin:0; padding:0; background:transparent; height:100%; display:flex; align-items:center; justify-content:center; font-family: -apple-system, system-ui; }
                .wrap { text-align: center; color: #999; padding: 24px; }
                .icon { font-size: 42px; margin-bottom: 10px; }
            </style>
        </head>
        <body>
            <div class="wrap">
                <div class="icon">🎬</div>
                <div>No video link set for this section.</div>
                <div style="font-size:13px; margin-top:6px;">Paste a YouTube URL above to play it here.</div>
            </div>
        </body>
        </html>
        """
    }

    private func embedHTML(for videoID: String) -> String {
        let fs = allowFullscreen ? "allowfullscreen" : ""
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <style>
                html, body { margin:0; padding:0; background:#000; height:100%; }
                .player { position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; }
                iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
            </style>
        </head>
        <body>
            <div class="player">
                <iframe id="ytplayer"
                        type="text/html"
                        src="https://www.youtube.com/embed/\(videoID)?rel=0&playsinline=1&modestbranding=1"
                        frameborder="0"
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                        \(fs)>
                </iframe>
            </div>
        </body>
        </html>
        """
    }
}

extension YouTubePlayerView {
    static func extractVideoID(from urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return "" }
        let host = url.host?.lowercased() ?? ""

        if host.contains("youtu.be") {
            let id = url.lastPathComponent
            return id.isEmpty ? "" : id
        }

        if host.contains("youtube.com") || host.contains("youtube-nocookie.com") || host.contains("m.youtube.com") {
            if let comps = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                for query in comps.queryItems ?? [] where query.name == "v" {
                    return query.value ?? ""
                }
                if url.pathComponents.count >= 3, url.pathComponents[1] == "embed" {
                    return url.pathComponents[2]
                }
                if url.pathComponents.count >= 3, url.pathComponents[1] == "shorts" {
                    return url.pathComponents[2]
                }
            }
        }

        if trimmed.count == 11, !trimmed.contains("/"), !trimmed.contains(" ") {
            return trimmed
        }
        return ""
    }
}
