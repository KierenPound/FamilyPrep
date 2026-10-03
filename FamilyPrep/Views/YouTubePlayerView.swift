import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String
    let allowFullscreen: Bool = true

    func makeUIView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        webConfiguration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let cleanID = sanitizeVideoID(videoID)
        guard !cleanID.isEmpty else {
            webView.loadHTMLString(emptyPlaceholderHTML, baseURL: nil)
            context.coordinator.lastLoadedID = ""
            return
        }
        if context.coordinator.lastLoadedID == cleanID { return }
        context.coordinator.lastLoadedID = cleanID
        let html = embedHTML(for: cleanID)
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com")!)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastLoadedID: String = ""
    }

    private func sanitizeVideoID(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if let direct = Self.extractVideoID(from: trimmed), !direct.isEmpty {
            let legal = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
            let filtered = String(trimmed.unicodeScalars.filter { legal.contains($0) })
            return String(filtered.prefix(11))
        }
        let legal = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        let filtered = String(trimmed.unicodeScalars.filter { legal.contains($0) })
        return String(filtered.prefix(11))
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

    private func embedHTML(for cleanID: String) -> String {
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
                        src="https://www.youtube-nocookie.com/embed/\(cleanID)?rel=0&playsinline=1&modestbranding=1&origin=https://www.youtube-nocookie.com&widget_referrer=1&iv_load_policy=3&fs=1"
                        frameborder="0"
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share; fullscreen"
                        referrerpolicy="no-referrer-when-downgrade"
                        allowpaymentrequest="false"
                        \(fs)>
                </iframe>
            </div>
        </body>
        </html>
        """
    }
}

extension YouTubePlayerView {
    static func extractVideoID(from urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.count == 11, !trimmed.contains("/"), !trimmed.contains(" ") {
            return trimmed
        }
        guard let url = URL(string: trimmed) else { return nil }
        let host = (url.host ?? "").lowercased()

        if host.contains("youtu.be") {
            let id = url.lastPathComponent
            return id.isEmpty ? nil : id
        }

        if host.contains("youtube.com") || host.contains("youtube-nocookie.com") || host.contains("m.youtube.com") {
            if let comps = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                for query in comps.queryItems ?? [] where query.name == "v" {
                    if let v = query.value, !v.isEmpty { return v }
                }
                let pc = url.pathComponents
                if pc.count >= 3, pc[1] == "embed" { return pc[2] }
                if pc.count >= 3, pc[1] == "shorts" { return pc[2] }
                if pc.count >= 3, pc[1] == "live" { return pc[2] }
            }
        }

        return nil
    }
}
