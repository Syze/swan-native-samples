

// Swan Gallery Pick host — pairs with Swan mobile 1.1.0 and later. What changed in each
// release, and whether this file needs updating: GALLERY_PICK.md, "Versions and
// release notes".

import UIKit
import WebKit
import Photos
import PhotosUI
import Vision
import Network
import SensitiveContentAnalysis

final class ViewController: UIViewController {

    /// Where the SDK bundle is served from. Must be **https** — getUserMedia needs
    /// a secure context, so an http or file:// URL gives no camera.
    let sdkURL = URL(string: "https://swan-mobile-web-component.swan.so")!

    static let bridgeName = "swanBridge"

    // ---- Fill these in before running ----------------------------------------

    /// Who the flow is running for. `gender` is optional: "male" or "female" skips
    /// the flow's own gender screen; anything else, or nil, shows it.
    static let userEmail = "your@example.com"
    static let shopDomain = "your-customer-shop-domain"
    static let userGender = "male"        // "male" | "female"

    /// Optional. A height you already know, in centimetres.
    ///
    /// Inside 152-213 the flow skips its own ruler screen and builds with this.
    /// Outside that range, or nil, the ruler is shown and the user's answer wins —
    /// so what comes back on `onComplete` is the authoritative one and may differ
    /// from what you sent. A string is accepted too, since hosts often have one.
    ///
    /// Set to nil to see the ruler.
    static let userHeightCm: Any? = 181

    /// Session token from `POST /auth/session`. **Required — without this nothing
    /// uploads**: the scan and picker work, then Build stops with an error naming
    /// what is missing (`onError` with stage "config").
    static let sessionToken = ""   // paste a token from POST /auth/session

    /// How far back the library search reaches, in months. 1–36; the flow clamps
    /// anything outside that. "Load more photos" appears only when the user allows
    /// limited photo access. 12 is the flow's own default.
    static let monthsBack = 12

    /// Brand styling *and* wording for the flow, passed through as `config`.
    ///
    /// Two independent halves: `style` becomes CSS variables, `content` replaces
    /// text. Either can be left out entirely.
    ///
    /// Every value is optional and anything left out keeps the SDK's own default,
    /// so a brand can set two colours or all of them. The keys are the same
    /// `StyleConfig` the scan components take — `base`, `heading`, `subheading`
    /// and `button` — and each becomes a CSS variable on the flow's shadow root.
    ///
    /// Values are plain strings because they are CSS: any colour notation the
    /// browser accepts works, sizes carry their unit, and a font family is a full
    /// stack. Nothing here is validated on the way through, so a typo shows up as
    /// a property that simply has no effect.
    static let theme: [String: Any] = [
        "style": [
            "base": [
                "backgroundColor": "#FFF8F0",
                "baseTextColor": "#101828",
                "baseFontFamily": "Georgia, serif",
                "baseFontSize": "17px",
                "brandColor": "#E5006D",
                "primaryColor": "#00A37A",
                "secondaryColor": "#E3D5C8",
            ],
            "heading": [
                "headingColor": "#5B21B6",
                "headingFontFamily": "Impact, Haettenschweiler, sans-serif",
                "headingFontSize": "26px",
                "headingFontWeight": "700",
            ],
            "subheading": [
                "subheadingColor": "#0369A1",
                "subheadingFontFamily": "'Courier New', monospace",
                "subheadingFontSize": "13px",
                "subheadingFontWeight": "500",
            ],
            "button": [
                "buttonBackground": "#7C3AED",
                "buttonTextColor": "#FFFFFF",
                "buttonFontSize": "15px",
                "buttonFontFamily": "'Trebuchet MS', sans-serif",
                "buttonBorderRadius": "14px",
                "buttonDisabledBackground": "#B0A6C4",
                "buttonDisabledTextColor": "#FFF3F8",
            ],
        ],

        // Wording, grouped by the screen it appears on. Partial at both levels: a
        // group left out keeps all its defaults, and a name left out inside a
        // group keeps just that one — so a brand can change one button without
        // restating the rest.
        //
        // Every group is listed here so each screen can be checked on a device.
        // Delete whichever you do not want to change; nothing has to be present.
        // The names and what they mean are in GALLERY_PICK_TEXT_CONFIG.md.
        "content": [
            "galleryPick": [
                // Shared, so one line here proves the text reaches every screen.
                "common": [
                    "poweredBy": "Powered by Acme",
                    "privacyNote": "Nothing leaves your phone until you say so.",
                    "notUploadedNote": "Nothing has been uploaded yet.",
                    "keepAppOpenNote": "Stay on this screen while we work.",
                    "tryAgainButton": "Try once more",
                    "retryButton": "Retry",
                    "openSettingsButton": "Open Settings",
                    "cameraStartingButton": "Waking the camera…",
                ],
                "introPage": [
                    "headingTitle": "Create your Acme twin.",
                    "subHeadingTitle": "A selfie and a few photos. We measure you, build your twin, and show you anything in your size.",
                    "buttonText": "Get started",
                    "footerText": "About a minute. Nothing leaves your phone until you say so.",
                ],
                "genderPage": [
                    "headingTitle": "Where do you shop?",
                    "subHeadingTitle": "It sets the body we build your Muse from.",
                    "womensButton": "Womenswear",
                    "mensButton": "Menswear",
                    "buttonText": "Continue",
                ],
                "heightPage": [
                    "headingTitle": "How tall are you?",
                    "subHeadingTitle": "It anchors every measurement we take.",
                    "buttonText": "Next",
                ],
                "selfiePage": [
                    "headingTitle": "One quick selfie for Acme.",
                    "subHeadingTitle": "It stays on your phone, and only checks the photos you pick are you.",
                    "buttonText": "Looks good",
                    "captionText": "Line your face up",
                    "footerText": "Used only to find your photos.",
                    "permissionText": "Your phone will ask about photos next. Allow Full Access so we can find yours.",
                ],
                "searchingPage": [
                    "headingTitle": "Looking for you.",
                    "subHeadingTitle": "Searching your photos, right here on your phone.",
                ],
                // Nine names on this page. `headingTitle` is left out on purpose:
                // with no override the picker writes its own line naming the real
                // minimum, which one fixed sentence cannot.
                "pickerPage": [
                    "subHeadingTitle": "Albums › People & Pets is the quickest place to look.",
                    "buttonText": "Build my Acme twin",
                    "takePhotoButtonText": "Take one now",
                    "loadMoreButtonText": "Load more",
                    "loadingMoreButtonText": "Searching\u{2026}",
                    "scanningHeadingTitle": "Looking for you.",
                    "scanningSubHeadingTitle": "Picking opens when the search finishes.",
                    "scanningStatusText": "Still finding photos of you…",
                    "limitReachedText": "That is as many as we can take.",
                ],
                "capturePage": [
                    "headingTitle": "Three quick photos.",
                    "subHeadingTitle": "Two full-length — front and side — and one selfie. Prop your phone up and step back.",
                    "buttonText": "Ready",
                    "countingButtonText": "Get into position…",
                ],
                // `headingTitle` left out for the same reason as the picker: the
                // shipped line names the angle it actually needs.
                "topUpPage": [
                    "subHeadingTitle": "Prop your phone up and step back so we can see your feet.",
                    "subHeadingTitleSelfie": "Hold the phone up and look at the camera.",
                ],
                "buildingPage": [
                    "headingTitle": "Building your Acme twin.",
                    "subHeadingTitle": "Measurement-accurate, from the photos you picked. Stay on this screen.",
                ],
                "previewPage": [
                    "headingTitle": "Your Acme twin is ready.",
                    "subHeadingTitle": "Add something from trending, or paste a product link.",
                    "buttonText": "Finish",
                ],
                "failedPage": [
                    "pausedHeadingTitle": "Paused.",
                    "pausedSubHeadingTitle": "The upload stopped. We will pick up where it left off.",
                    "unusableText": "Some photos would not load. Different ones usually help.",
                    "failedHeadingTitle": "We could not finish.",
                    "failedSubHeadingTitle": "Something went wrong building your twin. Your photos are safe.",
                ],
                "libraryBlockedPage": [
                    "headingTitle": "We cannot see your photos.",
                    "subHeadingTitle": "Allow photo access in Settings, then try again.",
                    "bodyText": "Acme needs your photo library to find pictures of you. Nothing is uploaded — the matching happens on your phone.",
                ],
                "cameraBlockedPage": [
                    "deniedText": "Camera access is off for Acme.",
                    "busyText": "Another app is using the camera. Close it and try again.",
                    "unknownText": "We could not open the camera.",
                ],
            ]
        ]
    ]

    /// Custom scheme for serving photos straight into <img src>. Must not collide
    /// with a scheme WebKit already handles — registering "http" or "https" throws.
    static let photoScheme = "swan-photo"

    /// Held strongly here; the configuration's reference alone is not something to
    /// rely on for an object we also want to keep alive across navigations.
    let photoSchemeHandler = PhotoSchemeHandler()

    var webView: WKWebView!
    var webReadyWatchdog: DispatchWorkItem?
    var isLimitedAccess = false
    var referencePrint: VNFeaturePrintObservation?

    /// The reference again, left-right flipped. A front-camera selfie is not
    /// necessarily oriented the way the user appears in someone else's photo, and
    /// this descriptor is not mirror-invariant — the self-test put that at 0.142,
    /// which is free to reclaim by keeping both and taking the nearer one.
    var referencePrintMirrored: VNFeaturePrintObservation?

    /// The reference face pre-blurred to several source resolutions.
    ///
    /// A 120px face upscaled to 224 is soft while a 380px one downscaled is sharp,
    /// and the descriptor reads that difference as dissimilarity. Each candidate is
    /// compared against the reference rendered at its own resolution.
    var referenceScales: [ScaledReference] = []

    /// Which reference bucket the last scored photo used. Logged so the scale
    /// ladder can be judged from real data.
    var lastReferenceWidth = 0

    /// Face measurements from the last photo `matchPerson` looked at, for
    /// `ScanEval`. Only filled in eval mode — the quality number costs an extra
    /// Vision pass per photo.
    var lastFaceMetrics: FaceMetrics?

    /// Whether the last photo `matchPerson` scored had its face re-cropped from a
    /// larger render. Read by `ScanEval`, so a run shows whether it actually kicked in.
    var lastCropFullRes = false

    /// Whether the last photo `loadPhoto` returned had to be turned upright. Read by
    /// `ScanEval`, since the photo it is handed no longer shows it.
    var lastLoadRotated = false

    /// Whether the last photo `loadPhoto` returned was the phone's smaller copy of a
    /// photo whose full version is only in iCloud. Counted by the scan.
    var lastLoadLocalCopy = false

    /// Why the last `loadPhoto` came back empty, for the verbose log: whether iOS
    /// said the photo was in iCloud, and how large a copy the phone offered.
    var lastLoadNote = ""

    /// What the second head-to-toe check found, when `matchPerson` ran one — see
    /// the full-body gate there. Nil when no retry happened. Read by the scan log.
    var lastBodyRetry: (note: String, rescued: Bool)?

    /// The smallest local copy worth scanning, on its longer side. Under this the
    /// phone holds only a thumbnail, and a face read from one is blur: it would
    /// either fail the size gate or be scored against mush, so the photo is
    /// skipped as it was before, as "no image".
    static let minLocalCopyPixels = 800

    /// How long `loadPhoto` waits for the phone's copy of an iCloud photo. It is
    /// already on the phone, so this is a ceiling against a stalled callback, not
    /// a download allowance.
    static let localCopyWait: DispatchTimeInterval = .seconds(2)

    /// The copy iOS offered when the full photo was in iCloud, however small. The
    /// scan reads it only to ask one question: does this look like a selfie?
    var lastLoadThumbnail: UIImage?

    // ---- iCloud selfies ------------------------------------------------------
    //
    // The phone keeps a 120px thumbnail of a photo whose full version is in iCloud
    // — far too small to match a face, but enough to see that there *is* one face
    // filling the frame. Those, and only those, are downloaded at a small size and
    // put through the same gates as a local photo. Full-length photos stay out: at
    // 120px nothing says whose body it is, and downloading every single-person
    // photo in a library is the library.

    /// Longest side of the copy asked for. Enough for a selfie's face at the sizes
    /// the matcher is tuned for; a fraction of the original's bytes.
    static let cloudPixels: CGFloat = 1024
    /// Downloads per scan, most recent first. Whatever the filter finds beyond this
    /// stays out, so a library of strangers' selfies costs a bounded amount.
    static let cloudDownloadCap = 40
    /// Wall-clock budget for the whole iCloud pass, on top of the local scan.
    static let cloudTimeBudget: TimeInterval = 60
    /// Per-photo limit, as for sizing an original.
    static let cloudTimeout: DispatchTimeInterval = .seconds(10)

    /// Wi-Fi, not Low Data Mode, and online. The iCloud pass never spends mobile data.
    static var cloudDownloadsAllowed: Bool {
        let path = pathMonitor.currentPath
        return path.status == .satisfied && !path.isExpensive && !path.isConstrained
    }

    /// Bumped every time the flow resets. A scan loop captures the value it
    /// started with and stops as soon as they differ, which is the only way to
    /// interrupt it — a dispatched block keeps running through a page reload, and
    /// its replies would otherwise be accepted by whatever scan is live next.
    var scanGeneration = 0

    /// Reload attempts after a WebContent process crash, and the ceiling on them.
    var processReloads = 0
    static let maxProcessReloads = 3

    /// One console line per photo scanned. Useful on a small library, a flood on
    /// a real one — a 10k-photo scan prints 10k lines.
    static let verboseLogging = false

    /// Measures matching against a hand-labelled album, and prints the result at
    /// the end of every scan. **Debug only — keep it off in any build a brand sees.**
    /// The grid is unaffected either way; see `ScanEval`.
    static let evalMode = false

    /// The album a tester fills with every photo that *should* reach the grid:
    /// them, alone, head to toe — or a selfie of them. Read as the answer key.
    static let evalAlbumTitle = "Swan-Eval"

    /// How much of the grid "precision at the top" looks at. A measuring window,
    /// not a number of photos the grid has to show.
    static let evalTopN = 20

    /// Replace the saved eval selfie with the one taken this run. Set true for one
    /// run — new lighting, or a different tester on the same phone — then back.
    /// See `evalReferenceSelfie`.
    static let evalResaveSelfie = false

    /// Echoes the SDK's own API and socket trace, and the bodies of its callbacks,
    /// into the Xcode console.
    ///
    /// **Turn this off before you ship.** Those lines carry presigned S3 URLs with
    /// their signature and security token, the user's email address, and 24-hour
    /// links to their finished renders. On a device you are holding that is
    /// exactly what you want to see; inside a shipped app it is all of that going
    /// wherever your logs go.
    ///
    /// The flow is unaffected either way — this only decides whether the host
    /// prints what crosses the bridge.
    static let debugBridgeLogging = false

    /// Writes the selfie and candidate face crops to Documents. Biometric data
    /// on disk — keep false outside local debugging.
    var debugDumpCrops = false
    var debugCropsSaved = 0
    static let debugCropLimit = 12

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        // Started now rather than at the first scan: a monitor's first reading takes
        // a moment, and the scan reads it the moment a photo matches.
        _ = Self.pathMonitor
        setupWebView()
        webView.load(URLRequest(url: sdkURL))
        startWebReadyWatchdog()
    }

    deinit {
        webView?.configuration.userContentController
            .removeScriptMessageHandler(forName: Self.bridgeName)
        webReadyWatchdog?.cancel()
        print("♻️ ViewController deinit")
    }

    // MARK: - Setup

    func setupWebView() {
        let contentController = WKUserContentController()

        // Retained strongly, so passing `self` leaks the VC, the web view and a
        // content process on every presentation. The proxy points back weakly.
        contentController.add(BridgeProxy(target: self), name: Self.bridgeName)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        // Without these the scan camera opens fullscreen and the voice-over
        // guidance is silently muted.
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Lets React write <img src="swan-photo://…"> instead of moving bytes
        // through the JSON bridge. The base64 path is the fallback if it is blocked.
        configuration.setURLSchemeHandler(photoSchemeHandler, forURLScheme: Self.photoScheme)

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    /// A JS error in the bundle gives a *successful* navigation and a blank page —
    /// same white screen as a network failure, opposite cause. This log is what
    /// tells them apart.
    func startWebReadyWatchdog() {
        let work = DispatchWorkItem {
            print("⏰ No WEB_READY within 15s — the bundle probably threw. Check Web Inspector.")
        }
        webReadyWatchdog = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: work)
    }

    // MARK: - Sending to web

    /// `callAsyncJavaScript` with an arguments dictionary, not a spliced string:
    /// U+2028/U+2029 are legal in JSON but terminate a line in JS source, so a
    /// spliced payload can throw a syntax error and vanish silently.
    func sendToWeb(_ payload: [String: Any]) {
        webView.callAsyncJavaScript(
            "window.postMessage(payload, window.location.origin);",
            arguments: ["payload": payload],
            in: nil,
            in: .page
        ) { result in
            if case .failure(let error) = result {
                print("❌ sendToWeb failed: \(error)")
            }
        }
    }
}

/// Which way the person in a photo is facing.
///
/// String-backed so the raw value can cross the bridge as-is — the web side
/// stores the analysis payload whole and does not decode it, so the wire format
/// has to be readable on its own.
enum PhotoType: String {
    case front
    case side
    case selfie
    /// No face was found. Usually a back view, sometimes an unusable photo — read
    /// alongside `isFullBody` to tell those apart.
    case unknown
}

/// One reference print, built from a face crop degraded to `sourceWidth`.
struct ScaledReference {
    let sourceWidth: CGFloat
    let print: VNFeaturePrintObservation
    let mirrored: VNFeaturePrintObservation?
}

// MARK: - Receiving from web

extension ViewController: WKScriptMessageHandler {

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        // Accept both a JSON string and a dictionary — silently dropping anything
        // that isn't a String is how messages disappear without trace.
        let body: [String: Any]?
        switch message.body {
        case let string as String:
            body = (try? JSONSerialization.jsonObject(with: Data(string.utf8))) as? [String: Any]
        case let dictionary as [String: Any]:
            body = dictionary
        default:
            print("⚠️ Bridge got unsupported body: \(type(of: message.body))")
            return
        }

        guard let payload = body, let type = payload["type"] as? String else {
            // Only under the debug flag: an undecodable body is by definition
            // unbounded and could hold a token, an email or photo bytes.
            if Self.debugBridgeLogging { print("⚠️ Bridge got undecodable message: \(message.body)") }
            return
        }

        switch type {
        case "WEB_READY":
            webReadyWatchdog?.cancel()
            // First load or a reload after the content process died — either way
            // the web side has no state, so nothing held here is still valid.
            // That includes any captures: the page holds their ids, so once it has
            // reloaded nothing can ask for them again.
            if CaptureStore.count > 0 { print("🧹 dropping \(CaptureStore.count) capture(s) — the page reloaded") }
            CaptureStore.removeAll()
            resetScanState()
            // Pages from before versioning send no version, so the line just omits it.
            let webVersion = (payload["version"] as? String).map { " v\($0)" } ?? ""
            print("✅ WEB_READY\(webVersion) — rendering GalleryPick")
            if Self.sessionToken.isEmpty {
                print("\u{26a0}\u{fe0f} No sessionToken — photos will not be uploaded and no Muse will be built.")
            }
            sendToWeb([
                "type": "RENDER_COMPONENT",
                "componentName": "GalleryPick",
                "props": [
                    "userDetails": [
                        "email": Self.userEmail,
                        "shopDomain": Self.shopDomain,
                        "gender": Self.userGender,
                        // Omitted entirely when nil, so the flow sees no height at
                        // all rather than a null it has to interpret.
                        "heightInCm": Self.userHeightCm as Any,
                    ].compactMapValues { $0 },
                    "token": Self.sessionToken,
                    "config": Self.theme,
                    "monthsBack": Self.monthsBack,
                ]
            ])

        case "GALLERY_SCAN_START":
            let filters = payload["payload"] as? [String: Any] ?? [:]

            // Redact the reference image before logging — a base64 selfie is tens
            // of thousands of characters and floods the console, hiding every
            // other line you actually need to read.
            var loggable = filters
            if let reference = loggable["referenceImage"] as? String {
                loggable["referenceImage"] = "<base64, \(reference.count) chars>"
            }
            print("🔍 GALLERY_SCAN_START \(loggable)")
            startGalleryScan(monthsBack: filters["monthsBack"] as? Int ?? 12,
                             referenceImage: filters["referenceImage"] as? String)

        case "GALLERY_THUMBNAILS":
            // Fallback path: one photo the custom scheme could not load. Asked for
            // per tile, so there is no batch to cap and nothing is fetched that the
            // user never scrolled to.
            let thumbId = (payload["payload"] as? [String: Any])?["assetId"] as? String ?? ""
            sendThumbnail(for: thumbId)

        case "GALLERY_FULL_IMAGE":
            // One photo per request, because fetch() cannot reach the custom scheme
            // (see SCHEME_TEST_RESULT below) and a whole selection in one message
            // would be several megabytes of base64 in a single JSON payload.
            let assetId = (payload["payload"] as? [String: Any])?["assetId"] as? String ?? ""
            sendFullImage(id: assetId)

        case "OPEN_SETTINGS":
            // A web page cannot navigate to the settings URL scheme, so the only way
            // to offer "Open Settings" from inside the WebView is to ask the host.
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }

        case "GALLERY_PICK_MORE":
            // Reopens iOS's limited-library picker. It shows what the user has
            // already shared and lets them add to it — nothing is re-picked from
            // scratch. The completion handler is what tells us to scan again.
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self) { [weak self] added in
                print("\u{1f5bc} limited picker closed — \(added.count) photo(s) added")
                guard let self = self, !added.isEmpty else { return }
                // The selfie is still held web-side, so re-entering the scan is
                // all that is needed — the user asked for more photos, not to be
                // sent back through the camera.
                self.sendToWeb(["type": "onGalleryPickedMore", "payload": ["added": added.count]])
            }

        case "WEB_LOG":
            // console.log inside a WKWebView only reaches Safari's Web Inspector.
            // The SDK mirrors its API and socket trace here so a device test
            // watched from Xcode can see it — request bodies and all, which is why
            // this is behind a flag. See `debugBridgeLogging`.
            if Self.debugBridgeLogging {
                print((payload["payload"] as? [String: Any])?["text"] as? String ?? "")
            }

        case "GALLERY_RESET":
            // The web layer starts a scan, or abandons the flow. Either way nothing
            // from the previous run should survive into the next one.
            resetScanState()

        case "GALLERY_ANALYSE_PHOTO":
            // Sent when the user selects a photo. See analysePhoto(id:).
            let photoId = (payload["payload"] as? [String: Any])?["assetId"] as? String ?? ""
            analysePhoto(id: photoId)

        case "GALLERY_CAPTURE_PHOTO":
            // A photo the user took inside the flow, to fill a shot the library
            // could not. Held in memory and analysed like any other photo — never
            // written to the photo library. See storeCapture(id:dataURI:).
            let capture = payload["payload"] as? [String: Any] ?? [:]
            let captureId = capture["id"] as? String ?? ""
            let captureURI = capture["dataURI"] as? String ?? ""
            print("📥 GALLERY_CAPTURE_PHOTO \(captureId) — \(captureURI.count / 1024)KB base64, shot \(capture["shot"] ?? "?")")
            storeCapture(id: captureId, dataURI: captureURI)

        case "GALLERY_CLEAR_CAPTURES":
            // Deliberately its own message rather than part of GALLERY_RESET: that
            // one is also sent at the start of every scan, and a user who takes a
            // photo and then asks for more library photos must keep it.
            print("🧹 clearing \(CaptureStore.count) held capture(s)")
            CaptureStore.removeAll()

        case "SCHEME_TEST_RESULT":
            // React reporting whether <img src="swan-photo://..."> worked.
            let ok = (payload["payload"] as? [String: Any])?["ok"] as? Bool ?? false
            // Only ever reports on <img>. fetch() against a custom scheme is
            // refused by WebKit outright, so "works" means displays, not readable.
            print(ok
                  ? "\n🧪 <img> loads from the custom scheme (display only; fetch() is still blocked).\n"
                  : "\n🧪 Custom scheme blocked for <img> too — falling back to base64 thumbnails.\n")

        case "COMPONENT_CALLBACK":
            // Everything the flow reports comes through here. Replace each print
            // with your own handling.
            let name = payload["callbackName"] as? String ?? "?"
            let result = payload["payload"] as? [String: Any] ?? [:]

            // Replace these prints with your own handling. The switch is the part
            // worth keeping; the printing is a harness, and some of it echoes
            // signed URLs and the user's email — see `debugBridgeLogging`.
            guard Self.debugBridgeLogging else { break }

            switch name {
            case "onUploadStart":
                // Photos are going up. `background` means the user is still picking
                // and this started on its own — no Muse is being built yet.
                let background = (result["background"] as? Bool ?? false) ? " (background)" : ""
                print("\u{1f4e4} upload started\(background) — \(result["photoCount"] ?? 0) photo(s)")

            case "onUploadEnd":
                // One file is up, or failed — per file, so a Live Photo's paired video
                // reports separately under the still's id plus `.mov`.
                let ok = result["uploaded"] as? Bool ?? false
                print("\u{2b06}\u{fe0f} \(result["kind"] ?? "?") \(ok ? "uploaded" : "FAILED") \(result["assetId"] ?? "?") — original \(result["original"] ?? false)\((result["background"] as? Bool ?? false) ? " (background)" : "")\(ok ? "" : " — \(result["error"] ?? "")")")

            case "onComplete":
                // The end of the flow. `photoIds` are the server's — this is what
                // POST /muse/build takes. `assetIds` are local and it does not.
                let muse = result["museId"] as? String ?? "none"
                let status = result["museStatus"] as? String ?? "not attempted"
                print("\u{2705} complete — museId \(muse), build \(status)")
                print("   photoIds \(result["photoIds"] ?? []) height \(result["heightInCm"] ?? 0)")
                // The finished Muse's rendered views, as a JSON array of URLs —
                // what the preview carousel is showing. Decode it to use them.
                print("   museImages \(result["museImages"] as? String ?? "none")")

            case "onCaptureComplete":
                // The camera fallback finished. Upload follows; onComplete closes out.
                print("\u{1f4f8} captured \(result["photoIds"] ?? [])")

            case "onImageSelect":
                // One photo tapped in the picker. `selected` false is a deselect.
                let picked = (result["selected"] as? Bool ?? false) ? "picked" : "dropped"
                print("\u{1f5b1} \(picked) \(result["assetId"] ?? "?") — \(result["count"] ?? 0) selected")

            case "onLoadMore":
                // The scan did not find enough and the user asked for more.
                // `path` is "shared_library" (the OS picker reopened) or
                // "older_photos" (the search reached further back). Worth watching:
                // it is the flow saying its own search came up short.
                print("\u{1f50e} load more — \(result["path"] ?? "?"), \(result["shown"] ?? 0) shown, \(result["selected"] ?? 0) selected")

            case "onMuseStart":
                print("\u{1f3a8} muse requested — \(result["photoIds"] ?? [])")

            case "onMuseEnd":
                // The build socket settled. Fires for a failure as well as a success —
                // onComplete never runs when the build fails, so this is the only
                // callback that tells you a Muse was attempted and did not arrive.
                // `phase` is the service's own step name (muse_completed,
                // validation_failed, muse_failed).
                print("\u{1f3c1} muse \(result["status"] ?? "?") — phase \(result["phase"] ?? "none"), museId \(result["museId"] ?? "none")")
                print("   \(result["message"] ?? "")")
                // The websocket frame in full, as JSON. `missingRoles` and
                // `rejectedPhotos` are in here and nowhere else — decode it to
                // find out what the build wants before the user tries again.
                print("   frame \(result["data"] as? String ?? "none")")

            case "onError":
                // `stage` is photos | upload | muse. The web layer already shows the
                // user a failure screen; this is for your logging and alerting.
                print("\u{274c} \(result["stage"] ?? "?") failed — \(result["message"] ?? "") (\(result["failedCount"] ?? 0) photo(s))")

            case "onRetry":
                // User pushed on the failure screen. `escalated` false = same photos
                // again, true = they gave up on that set and went back.
                print("\u{1f501} retry — \(result["kind"] ?? "?") escalated=\(result["escalated"] ?? false)")

            default:
                print("\u{1f4e9} \(name) \(result)")
            }

        default:
            print("⚠️ Unhandled message type: \(type)")
        }
    }
}

// MARK: - Camera

extension ViewController: WKUIDelegate {

    /// Required on iOS 15+ — without it the scan camera never opens.
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        // Only the camera, and only from the page we loaded. A blanket grant hands
        // any origin the web view reaches a live capture device.
        guard type == .camera, origin.host == sdkURL.host else {
            decisionHandler(.deny)
            return
        }
        decisionHandler(.grant)
    }
}

// MARK: - Load failures

extension ViewController: WKNavigationDelegate {

    /// The WebContent process was killed, usually memory pressure while backgrounded.
    ///
    /// Without this the web view stays permanently blank with no error and no
    /// recovery. Capped, because if the page is what exhausts memory, reloading
    /// reproduces the crash forever.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // Capped: if the page is what exhausts memory, reloading reproduces the
        // crash forever.
        guard processReloads < Self.maxProcessReloads else {
            print("\u{1f480} Web content process terminated again — giving up after \(processReloads) reloads")
            return
        }

        processReloads += 1
        print("\u{1f480} Web content process terminated — reloading (\(processReloads)/\(Self.maxProcessReloads))")
        startWebReadyWatchdog()
        webView.reload()
    }

    // ngrok tunnels drop and the URL rotates on restart — without these a dead
    // tunnel is a blank screen with an empty console.
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        webReadyWatchdog?.cancel()
        print("❌ Could not reach \(sdkURL): \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webReadyWatchdog?.cancel()
        print("❌ Navigation failed: \(error.localizedDescription)")
    }

    /// The CDN answers a path it does not have with a 404 page. A version folder
    /// that was never published sends that page on to the latest release; any
    /// other missing path stays a 404 and the flow never starts.
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.isForMainFrame,
           let response = navigationResponse.response as? HTTPURLResponse,
           response.statusCode >= 400 {
            print("❌ \(response.statusCode) for \(response.url?.absoluteString ?? "?") — check sdkURL")
        }
        decisionHandler(.allow)
    }

    /// A pinned version that was never published: the CDN sent the page on to the
    /// latest release, so the flow works, but not on the release this file was
    /// tested with. Only checked when `sdkURL` names a version — a bare domain has
    /// an empty path and lands on "/", which is not a redirect.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard sdkURL.path.hasPrefix("/v"), let landed = webView.url, landed.path != sdkURL.path else { return }
        print("⚠️ Asked for \(sdkURL.path), got \(landed.path) — that version is not published; the latest release loaded instead")
    }
}

// MARK: - Gallery scan

extension ViewController {

    /// Match cutoff for a full-length photo — fronts, and sides not in profile. Lower
    /// distance = more similar.
    ///
    /// Was 0.78. Measured on two libraries: strangers' full-length photos never scored
    /// under 0.762 across three runs on one phone, while the owners' good fronts
    /// scored 0.61–0.69. A head-turned front of one owner (0.779) drops; selfies and
    /// profile sides have cutoffs of their own below.
    static let matchThreshold: Float = 0.75

    /// The cutoff for a full-profile side: the body side-on **by its measured
    /// shoulders** — never by head turn alone — and the face turned past `profileYaw`.
    /// A photo whose shoulders could not be read gets `matchThreshold`: a stranger with
    /// no measurable shoulders and a turned head got in on this cutoff otherwise.
    ///
    /// A face in profile cannot look like the front-facing selfie to FeaturePrint —
    /// the tester's own profile sides scored 0.83 and 0.89 — so it gets more room.
    /// Measured on two libraries, no stranger's profile side scored between 0.78 and
    /// 0.95. Only these photos: fronts, selfies and half-turned sides keep
    /// `matchThreshold`, and every other check still applies.
    static let profileMatchThreshold: Float = 0.92

    /// How far the head must be turned, in Vision's yaw radians (about 46°), for a
    /// side's face to count as in profile.
    static let profileYaw = 0.8

    /// The cutoff for a selfie. Tighter, because a selfie's face is large and sharp, so
    /// the user's own score low and a near miss is someone who looks like them.
    /// Measured on two libraries: own selfies 0.39–0.70, strangers' selfies 0.68–0.77
    /// on one phone and over 0.93 on the other. 0.65 keeps every front-facing own
    /// selfie; a strongly head-turned one (0.70) can drop, and a Muse needs only one.
    static let selfieMatchThreshold: Float = 0.65

    /// Only consider photos containing exactly one face.
    ///
    /// Taking the minimum distance across N faces is a best-of-N draw — a group
    /// shot gets N chances to look like you — so this is a precision fix, not just
    /// a speed one.
    static let requireSingleFace = true

    /// How large a second face or body must be, against the largest one in the
    /// photo, to count as someone else in it. Below this it is a passer-by in the
    /// distance, a face on a poster or a reflection — none of which make the photo
    /// a group shot, and all of which were rejecting selfies taken anywhere public.
    /// At a quarter, a person standing beside the shopper still counts.
    static let bystanderRatio: CGFloat = 0.25

    /// A face narrower than this is skipped — measured in the best copy of the photo
    /// the phone holds, not only the scan's downsampled render. A face of 68px there
    /// can be 133px in the original, and that photo is worth keeping.
    ///
    /// Deliberately permissive: a full-body photo has a small face by construction,
    /// and the answer to a weak descriptor is more source pixels, not a higher bar.
    static let minFacePixels: CGFloat = 120

    /// Require the lower body to be visible.
    ///
    /// A headshot and a full-length outfit photo match a face matcher equally well;
    /// only body-pose detection separates them.
    static let requireFullBody = true

    /// How wide a face must be, as a fraction of the frame's **shorter** side, for a
    /// photo with no lower body to count as a selfie rather than a badly cropped
    /// body shot.
    ///
    /// Was 0.15, which let in waist-up shots, people sitting, and full-length photos
    /// with the feet cut off — all at 15–25%. Measured on three libraries: real
    /// selfies 37–70%, those 25% and under. A selfie is a close-up face; anything
    /// else has to pass as head to toe.
    ///
    /// The shorter side, not the width: against the width a landscape selfie read as
    /// half the size of the same selfie held upright, and was rejected as a body shot.
    static let selfieFaceRatio: CGFloat = 0.30

    /// A face's width against the frame's shorter side — the one number every
    /// selfie decision reads, so the scan and a tap cannot disagree about it.
    static func faceRatio(boxWidth: CGFloat, in cgImage: CGImage) -> CGFloat {
        boxWidth * CGFloat(cgImage.width) / CGFloat(min(cgImage.width, cgImage.height))
    }

    /// How far the head must be turned, in Vision's yaw radians, for a full-length
    /// photo to count as a side rather than a front.
    ///
    /// Sat at 0.35 and that is the bottom edge of the side cluster, not the gap
    /// between the two: measured on a real library, fronts came in at 0.02-0.07
    /// and sides at 0.35-0.74, so 0.35 gave sides almost no margin while fronts
    /// had five times more than they needed. Two of three sides cleared it by
    /// under 0.03. This sits between the clusters instead.
    ///
    /// Read the `🔬 FACE yaw` lines to re-judge it — every analysed photo prints one.
    static let sideYawThreshold = 0.25

    /// How sure Vision must be of a joint before it counts as seen.
    static let bodyJointConfidence: Float = 0.3

    /// Ankles a head-to-toe photo must show. One, not two: in a side photo the far
    /// ankle is routinely hidden behind the near leg, and requiring both would
    /// reject real side shots. The eval records the ankle count per photo, so if
    /// this lets strangers through, the data says so.
    ///
    /// This replaced "any 2 of {knees, ankles}", under which two knees and no
    /// ankles passed — a photo cut off at the shins counted as full length. On the
    /// first labelled library every stranger in the grid had come in that way.
    static let minAnkles = 1

    /// How much of the image height, head to lowest ankle, the person must span.
    ///
    /// Measured from the eyes and nose rather than the crown, so a person who fills
    /// the frame spans about 0.85. Rules out a head-to-toe figure small in the
    /// background of someone else's photo. A starting point — the eval records
    /// the span per photo, so tune it from there.
    ///
    /// The bar for a photo with one ankle found. With both, the lower
    /// `minBodySpanBothAnkles` applies: two ankles is firmer evidence the whole body
    /// is in frame, so a normal step-back photo at ~0.43 passes.
    static let minBodySpan: CGFloat = 0.55
    static let minBodySpanBothAnkles: CGFloat = 0.40

    /// Room the photo must leave below the lowest ankle, as a fraction of the span —
    /// so the feet are in frame, not only the ankles.
    ///
    /// Vision has no toe or heel points; the ankle is the lowest joint it gives, so
    /// an ankle on the bottom edge passed with the feet cut off. Measured on one
    /// library: a photo with the toes cut had 0.05, the good full-length ones 0.14 and
    /// up — so this sits between. The eval records it per photo; retune from there.
    static let minFootRoom: CGFloat = 0.10

    /// Shoulder spread below which a full-length photo is a side.
    ///
    /// The spread is shoulder width across the photo against the torso's length —
    /// the body's own turn, which a turned head does not change. Measured on one
    /// library: sides 0.00–0.33, fronts 0.44 and up, three-quarter poses 0.44–0.60
    /// (so they count as fronts). Every photo's spread is logged; tune from there.
    ///
    /// Not Vision's 3D pose: without a depth map, which an ordinary photo does not
    /// have, it rebuilt side-on people as facing the camera and read every side as
    /// under 5°.
    static let sideShoulderSpread: CGFloat = 0.40

    /// How sure Vision must be of a joint used for the spread. Lower than
    /// `bodyJointConfidence`: in a side view the far shoulder is half hidden, and
    /// refusing it would hand exactly those photos to the head turn.
    static let spreadJointConfidence: Float = 0.1

    /// One photo's type, from values the caller already has.
    ///
    /// Shared by the scan and by `classifyPhotoType` so a photo cannot be called
    /// `side` while it is being counted and `front` when the user taps it. The scan
    /// gets all three inputs for free — the face observations, the ratio and the
    /// body check are already computed for the match gates.
    static func photoType(faceRatio: CGFloat, yaw: Double?, body: BodyCheck) -> PhotoType {
        // Not head to toe. A big face is a face photo; a small one is someone cut
        // off or too far away, which the full-body gate exists to reject.
        if !body.isHeadToToe {
            return faceRatio >= selfieFaceRatio ? .selfie : .unknown
        }
        // The body's own turn decides — see `sideShoulderSpread`. The head's turn only
        // when the shoulders could not be measured.
        if let facing = body.bodyFacing { return facing }
        guard let yaw else { return .unknown }
        return headType(yaw: yaw)
    }

    /// Front or side by the head's turn alone: the fallback above, and logged beside the
    /// body's answer so the two can be compared.
    static func headType(yaw: Double) -> PhotoType {
        abs(yaw) > sideYawThreshold ? .side : .front
    }

    /// Builds the reference face print, then asks for photo access.
    ///
    /// All of it off the main thread. Run inline it blocked long enough to stall
    /// the WebView's compositor, so React's progress screen never painted and the
    /// last camera frame stayed frozen on display.
    func startGalleryScan(monthsBack: Int, referenceImage: String?) {
        // Fail fast. Without a usable reference every photo is compared against
        // nothing and the scan reports a confident zero, which looks like the
        // feature is broken rather than the selfie being bad.
        guard let reference = referenceImage else {
            print("🚫 No reference image in payload")
            sendToWeb(["type": "onGalleryScanComplete",
                       "payload": ["assetIds": [], "error": "no-reference"]])
            return
        }

        // Whatever the web side did or did not send, a scan always begins clean.
        resetScanState()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Eval mode only: every run is matched against one saved selfie, so a
            // change in the scores comes from the code, not from a new selfie.
            let referenceURI = Self.evalReferenceSelfie(reference)

            guard let selfie = Self.image(fromDataURI: referenceURI) else {
                print("🚫 Reference image could not be decoded")
                DispatchQueue.main.async {
                    self.sendToWeb(["type": "onGalleryScanComplete",
                                    "payload": ["assetIds": [], "error": "no-reference"]])
                }
                return
            }

            guard let croppedSelfie = self.croppedFace(from: selfie),
                  let croppedCG = croppedSelfie.cgImage,
                  let print0 = self.facePrint(fromFace: croppedCG) else {
                print("🚫 No face found in the selfie")
                DispatchQueue.main.async {
                    self.sendToWeb(["type": "onGalleryScanComplete",
                                    "payload": ["assetIds": [], "error": "no-face-in-selfie"]])
                }
                return
            }

            // The reference is a *cropped face*, normalised exactly like the
            // candidates. Printing the whole selfie against cropped faces measures
            // framing rather than identity, and every distance comes out meaningless.
            self.referencePrint = print0
            self.referencePrintMirrored = self.mirrored(croppedSelfie)
                .flatMap { $0.cgImage }
                .flatMap { self.facePrint(fromFace: $0) }
            self.buildReferenceScales(from: croppedSelfie)

            // A crop under ~80px means the reference is weak and every distance
            // below is measured against mush.
            let selfiePx = selfie.cgImage.map { "\($0.width)x\($0.height)" } ?? "?"
            let cropPx = "\(croppedCG.width)x\(croppedCG.height)"
            let ladder = self.referenceScales.map { String(Int($0.sourceWidth)) }.joined(separator: "/")
            print("🤳 Reference face ready — selfie \(selfiePx), face crop \(cropPx) -> normalised \(Int(Self.faceNormalSize.width))px, scales \(ladder), FeaturePrint revision \(Self.featurePrintRevision) (Vision default \(VNGenerateImageFeaturePrintRequest.defaultRevision))")

            self.saveDebugImage(selfie, name: "00-selfie")
            self.saveDebugImage(croppedSelfie, name: "00-reference-crop")


            DispatchQueue.main.async { self.requestAccessAndScan(monthsBack: monthsBack) }
        }
    }

    private func requestAccessAndScan(monthsBack: Int) {
        // .readWrite despite never writing: PHAccessLevel offers only .addOnly
        // (write-only) and .readWrite, so this is the only level that grants reads.
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch status {
                case .authorized:
                    self.isLimitedAccess = false
                    self.scanAssets(monthsBack: monthsBack)
                case .limited:
                    // The user shared only a hand-picked subset, so the fetch below
                    // sees just those. A small result count is expected, not a bug.
                    print("⚠️ Limited photo access — scanning only the shared subset")
                    self.isLimitedAccess = true
                    self.scanAssets(monthsBack: monthsBack)
                default:
                    print("🚫 Photo access denied")
                    self.sendToWeb(["type": "onGalleryScanComplete",
                                    "payload": ["assetIds": [], "denied": true]])
                }
            }
        }
    }

    /// Watches the network for the scan's iCloud sizing. Started once and kept for
    /// the life of the app.
    static let pathMonitor: NWPathMonitor = {
        let monitor = NWPathMonitor()
        monitor.start(queue: DispatchQueue(label: "co.getswan.gallery.network"))
        return monitor
    }()

    /// The shopper has asked the phone to save data — Low Data Mode on mobile data
    /// or on this Wi-Fi network. The scan then downloads nothing to size a photo.
    static var lowDataMode: Bool { pathMonitor.currentPath.isConstrained }

    /// What sizing a matched photo's original found.
    enum OriginalCheck {
        case fits(bytes: Int, downloaded: Bool)
        case tooLarge(downloaded: Bool)
        case unavailable(Original.Unavailable)
        /// Only in iCloud, and not downloaded because Low Data Mode is on.
        case lowData
    }

    /// Sizes a matched photo's original, so the grid shows only photos that can be
    /// sent as they are.
    ///
    /// From the phone first. An original that is only in iCloud is downloaded just
    /// far enough to size it — the matched photos only, never the library — unless
    /// Low Data Mode is on. iOS may keep that copy in the Photos library, as for any
    /// app that opens one; it clears it when it needs the space, and an upload of
    /// the same photo then reads it without downloading again.
    func checkOriginal(_ asset: PHAsset) -> OriginalCheck {
        switch Original.size(for: asset, allowNetwork: false) {
        case .success(let bytes): return .fits(bytes: bytes, downloaded: false)
        case .failure(.tooLarge): return .tooLarge(downloaded: false)
        case .failure:
            guard !Self.lowDataMode else { return .lowData }
            switch Original.size(for: asset, allowNetwork: true) {
            case .success(let bytes): return .fits(bytes: bytes, downloaded: true)
            case .failure(.tooLarge): return .tooLarge(downloaded: true)
            case .failure(let reason): return .unavailable(reason)
            }
        }
    }

    /// The types the grid takes turns between, in this order.
    static let gridTurns: [PhotoType] = [.front, .side, .selfie]

    /// The order the grid is shown in once the scan ends: each type closest first,
    /// then taking turns — front, side, selfie, front, side, selfie.
    ///
    /// Not one list sorted by score: a selfie always scores closer than a full-length
    /// photo, so the fronts and sides a Muse needs two of each would sink below every
    /// selfie. Only a first scan is shown in this order — the web appends a later
    /// pass to the grid, so no tile already on screen moves.
    static func gridOrder(_ ids: [String], scores: [String: (distance: Float, type: PhotoType)]) -> [String] {
        var queues = gridTurns.map { turn in
            ids.filter { scores[$0]?.type == turn }
                .sorted { (scores[$0]?.distance ?? .infinity) < (scores[$1]?.distance ?? .infinity) }
        }
        var ordered: [String] = []
        while queues.contains(where: { !$0.isEmpty }) {
            for turn in queues.indices where !queues[turn].isEmpty {
                ordered.append(queues[turn].removeFirst())
            }
        }
        // Any other type — not expected, since the gates only pass these three —
        // keeps its date order at the end rather than being dropped.
        let placed = Set(ordered)
        return ordered + ids.filter { !placed.contains($0) }
    }

    /// How far back the search may look. The SDK clamps this before it sends it,
    /// but a host is free to call in with anything, and neither a crash nor a scan
    /// that silently matches nothing is an acceptable answer to a bad number.
    static let monthsBackRange = 1...36

    /// Scans the whole window in one pass.
    ///
    /// Every photo inside `monthsBack` is examined, and matches stream to the web
    /// layer as they are found so the grid fills while this runs. There is no
    /// cursor and no early stop: the pass ends when the window does.
    private func scanAssets(monthsBack: Int) {
        let months = min(max(monthsBack, Self.monthsBackRange.lowerBound), Self.monthsBackRange.upperBound)
        if months != monthsBack {
            print("\u{26a0}\u{fe0f} monthsBack \(monthsBack) is out of range — using \(months)")
        }

        let options = PHFetchOptions()

        // No date filter at all under limited access. PhotoKit only returns the
        // subset the user hand-picked, so the set is already bounded by their own
        // choice and a date range bounds nothing on top of that — all it does is
        // discard photos they went out of their way to hand us. Someone who shares
        // forty good shots, half of them from a holiday two years ago, would
        // otherwise have the scan look at the recent handful, match nobody, and be
        // sent to the camera with the rest never opened.
        if !isLimitedAccess {
            // Not force-unwrapped. `date(byAdding:)` answers nil rather than
            // throwing when the arithmetic leaves the calendar's representable
            // range, and a host crash is a worse failure than a scan that does not
            // run. Unreachable with a clamped value.
            guard let from = Calendar.current.date(byAdding: .month, value: -months, to: Date()) else {
                print("\u{1f6ab} Could not build the scan window")
                sendToWeb(["type": "onGalleryScanComplete",
                           "payload": ["assetIds": [], "limited": isLimitedAccess]])
                return
            }
            options.predicate = NSPredicate(format: "creationDate >= %@", from as NSDate)
        }
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        // The shopper's own library only — not shared albums, which are other
        // people's photos — and no screenshots: a screenshot of a model passes every
        // other check. Counted before the screenshot filter, so the log says how many
        // it removed.
        options.includeAssetSourceTypes = [.typeUserLibrary]
        let withScreenshots = PHAsset.fetchAssets(with: .image, options: options).count
        let noScreenshots = NSPredicate(format: "(mediaSubtypes & %d) == 0",
                                        PHAssetMediaSubtype.photoScreenshot.rawValue)
        options.predicate = options.predicate.map {
            NSCompoundPredicate(andPredicateWithSubpredicates: [$0, noScreenshots])
        } ?? noScreenshots

        let assets = PHAsset.fetchAssets(with: .image, options: options)
        let total = assets.count

        // Visible-to-us count with no date filter. If this is 0 the problem is
        // access; if it is large while `total` is 0 the problem is the date range.
        let visible = PHAsset.fetchAssets(with: .image, options: nil).count
        let window = isLimitedAccess ? "everything you shared" : "the last \(months) months"
        print("\u{1f4f8} \(total) photos in \(window) (\(visible) visible in total\(isLimitedAccess ? ", limited access" : ""), \(withScreenshots - total) screenshots skipped)")
        logSensitivityPolicy()

        guard total > 0 else {
            sendToWeb(["type": "onGalleryScanComplete",
                       "payload": ["assetIds": [], "limited": isLimitedAccess]])
            return
        }

        let startedAt = Date()

        // Captured once. Anything that resets the flow — a reload, a new scan,
        // starting over — moves scanGeneration past this and ends the loop below.
        let generation = scanGeneration

        // A no-op unless eval mode is on and the answer-key album exists.
        let evalLabels = loadEvalLabels()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var matchedIds: [String] = []
            // Score and type per match, for the order the grid ends up in — see `gridOrder`.
            var matchScores: [String: (distance: Float, type: PhotoType)] = [:]
            var eval = ScanEval(labels: evalLabels)
            var lastReport = Date.distantPast

            // Per-gate tallies — which stage a disappointing result came from.
            var noImage = 0
            // Scanned from the phone's smaller copy, the full photo being in iCloud.
            var localCopies = 0
            var noFace = 0
            var noMatch = 0
            var groupSkipped = 0
            var tooSmall = 0
            var notFullBody = 0
            var otherPeople = 0
            var sensitiveSkipped = 0
            // Originals sized after a match — see `checkOriginal`.
            var tooLargeSkipped = 0
            var noOriginal = 0
            var lowDataSkipped = 0
            var sized = 0
            var downloadedToSize = 0
            var sizingSeconds = 0.0

            // What the matches cover, for the summary below. Internal: none of it
            // reaches the web layer, which derives the coverage row from what the
            // user has actually selected.
            var found: [PhotoType: Int] = [:]
            var examined = 0

            // Photos whose full version is in iCloud and whose thumbnail looks like a
            // selfie, with their scan position. Downloaded and examined after the
            // local pass, most recent first — see `cloudDownloadCap`.
            var cloudCandidates: [(asset: PHAsset, n: Int)] = []
            var cloudOnly = 0
            // Second head-to-toe checks at the larger render — see `lastBodyRetry`.
            var bodyRetried = 0
            var bodyRescued = 0

            // One loaded photo through every gate. Shared by the local pass and the
            // iCloud pass, so a downloaded photo faces exactly the same checks.
            func examine(_ asset: PHAsset, _ image: UIImage, n: Int) {
                    // Read before anything else loads: the photo is already upright.
                    let wasRotated = self?.lastLoadRotated ?? false
                    if self?.lastLoadLocalCopy == true { localCopies += 1 }

                    // Delivered dimensions, not the requested targetSize — PHImageManager
                    // treats that as a hint.
                    let px = image.cgImage.map { "\($0.width)x\($0.height)" } ?? "?"
                    let orient = Self.orientationName(image.imageOrientation)

                    guard let outcome = self?.matchPerson(in: image, asset: asset) else { return }
                    let metrics = self?.lastFaceMetrics
                    if let retry = self?.lastBodyRetry {
                        bodyRetried += 1
                        if retry.rescued { bodyRescued += 1 }
                        if Self.verboseLogging { print("  🦶 [\(n)] \(retry.note) — \(retry.rescued ? "rescued" : "still not head to toe")") }
                    }
                    // Set by the size check when a match's original fits.
                    var originalBytes: Int?

                    switch outcome {
                    case .noFace:
                        noFace += 1
                        eval.note(asset, image: image, rotated: wasRotated, gate: .noFace)
                        if Self.verboseLogging { print("  ○  [\(n)] no face             \(px) \(orient)") }

                    case .group(let faceCount):
                        groupSkipped += 1
                        eval.note(asset, image: image, rotated: wasRotated, gate: .group)
                        if Self.verboseLogging { print("  \u{1f465} [\(n)] group (\(faceCount) faces) — skipped   \(px) \(orient)") }

                    case .faceTooSmall(let pixels):
                        tooSmall += 1
                        eval.note(asset, image: image, rotated: wasRotated, gate: .faceTooSmall, metrics: metrics)
                        if Self.verboseLogging { print("  \u{1f50e} [\(n)] face too small (\(pixels)px)   \(px) \(orient)") }

                    case .otherPeople(let body):
                        otherPeople += 1
                        eval.note(asset, image: image, rotated: wasRotated, gate: .otherPeople, body: body, metrics: metrics)
                        if Self.verboseLogging { print("  \u{1f465} [\(n)] \(body.people) people — skipped   \(px) \(orient)") }

                    case .notFullBody(let body):
                        notFullBody += 1
                        eval.note(asset, image: image, rotated: wasRotated, gate: .notFullBody, body: body, metrics: metrics)
                        if Self.verboseLogging { print("  \u{1f9cd} [\(n)] not head to toe (head \(body.headSeen), ankles \(body.ankles), span \(String(format: "%.2f", body.span)), feet room \(String(format: "%.3f", body.footRoom)))   \(px) \(orient)") }

                    case .scored(let distances, let facePixels, let body, let type, let profile):
                        // A list, not a value, so turning off the single-face gate
                        // does not silently change what is logged.
                        let scores = distances.sorted()
                            .map { String(format: "%.3f", $0) }
                            .joined(separator: " ")
                        let distance = distances.min()!

                        // A face in profile against a front-facing selfie gets more room; a
                        // selfie, whose own matches score low, gets less.
                        let cutoff = profile ? Self.profileMatchThreshold
                            : type == .selfie ? Self.selfieMatchThreshold
                            : Self.matchThreshold

                        if distance >= cutoff {
                            noMatch += 1
                            eval.note(asset, image: image, rotated: wasRotated, gate: .noMatch, distance: distance,
                                      type: type, body: body, metrics: metrics,
                                      fullRes: self?.lastCropFullRes)
                            if Self.verboseLogging { print("  ·  [\(n)] no match  d=\(String(format: "%.3f", distance)) cut=\(String(format: "%.2f", cutoff))  \(px) \(orient)  face=\(facePixels)px ref=\(self?.lastReferenceWidth ?? 0) joints=\(body.lowerJoints)  [\(scores)]") }
                        } else if self?.isSensitiveContent(image) == true {
                            sensitiveSkipped += 1
                            eval.note(asset, image: image, rotated: wasRotated, gate: .sensitive, distance: distance,
                                      type: type, body: body, metrics: metrics,
                                      fullRes: self?.lastCropFullRes)
                            if Self.verboseLogging { print("  \u{1f6ab} [\(n)] sensitive content — skipped   \(px) \(orient)") }
                        } else if let hidden = { () -> (gate: EvalGate, why: String)? in
                            // Sized before the grid sees it: a photo whose original
                            // cannot be sent as it is never reaches the shopper.
                            let sizingStarted = Date()
                            let check = self?.checkOriginal(asset) ?? .unavailable(.unreadable)
                            sizingSeconds += Date().timeIntervalSince(sizingStarted)
                            sized += 1
                            switch check {
                            case .fits(let bytes, let downloaded):
                                if downloaded { downloadedToSize += 1 }
                                originalBytes = bytes
                                return nil
                            case .tooLarge(let downloaded):
                                if downloaded { downloadedToSize += 1 }
                                tooLargeSkipped += 1
                                return (.tooLarge, "original over \(Original.byteCap / 1_048_576)MB")
                            case .unavailable(let reason):
                                downloadedToSize += 1
                                noOriginal += 1
                                return (.noOriginal, "original \(reason.rawValue)")
                            case .lowData:
                                lowDataSkipped += 1
                                return (.noOriginal, "only in iCloud, Low Data Mode")
                            }
                        }() {
                            eval.note(asset, image: image, rotated: wasRotated, gate: hidden.gate, distance: distance,
                                      type: type, body: body, metrics: metrics,
                                      fullRes: self?.lastCropFullRes)
                            if Self.verboseLogging { print("  \u{1f4cf} [\(n)] hidden — \(hidden.why)  d=\(String(format: "%.3f", distance)) type=\(type.rawValue)  \(px) \(orient)") }
                        } else {
                            matchedIds.append(asset.localIdentifier)
                            matchScores[asset.localIdentifier] = (distance, type)
                            eval.note(asset, image: image, rotated: wasRotated, gate: .grid, distance: distance,
                                      type: type, body: body, metrics: metrics,
                                      fullRes: self?.lastCropFullRes, originalBytes: originalBytes)

                            // Kept so the tap that follows does not reload the photo
                            // and re-run pose detection for answers already in hand.
                            ScanAnalysisStore.store(ScanAnalysis(type: type, body: body),
                                                    id: asset.localIdentifier)
                            found[type, default: 0] += 1

                            // Streamed as found so the grid fills during the scan.
                            // Only the id travels; the page fetches its own pixels.
                            let matchedId = asset.localIdentifier
                            // The verdict rides along with the match. It is already
                            // worked out — the gates above computed the face ratio,
                            // the body check and the yaw — and sending it is what lets
                            // the picker choose one of each type for the user
                            // without tapping every photo to find out what it is.
                            let matchedType = type.rawValue
                            let matchedFullBody = body.isHeadToToe
                            DispatchQueue.main.async {
                                self?.sendToWeb(["type": "onGalleryMatchFound",
                                                 "payload": ["assetId": matchedId,
                                                             "type": matchedType,
                                                             "isFullBody": matchedFullBody,
                                                             "done": n,
                                                             "total": total]])
                            }
                            if Self.verboseLogging { print("  ✅ [\(n)] MATCH     d=\(String(format: "%.3f", distance)) cut=\(String(format: "%.2f", cutoff))  \(px) \(orient)  face=\(facePixels)px ref=\(self?.lastReferenceWidth ?? 0) joints=\(body.lowerJoints) type=\(type.rawValue) shoulders=\(body.shoulderSpread.map { String(format: "%.2f", $0) } ?? "–") original=\((originalBytes ?? 0) / 1024)KB  [\(scores)]") }
                        }
                    }

            }

            for index in 0..<total {
                // Returning here abandons the whole scan: no further matches, no
                // progress, and no completion message. A superseded scan that still
                // reported its result would overwrite the live one.
                guard self?.scanGeneration == generation else {
                    print("\u{1f6d1} Scan superseded — stopping at \(index) of \(total)")
                    return
                }

                autoreleasepool {
                    let asset = assets.object(at: index)
                    let n = index + 1

                    examined += 1

                    guard let image = self?.loadPhoto(asset: asset) else {
                        let note = self?.lastLoadNote ?? ""
                        if note.hasPrefix("in iCloud") { cloudOnly += 1 }
                        // A selfie-shaped thumbnail is worth a small download; the
                        // verdict waits for the iCloud pass. Anything else is skipped.
                        if let thumb = self?.lastLoadThumbnail, self?.isSelfieShaped(thumb) == true {
                            cloudCandidates.append((asset, n))
                            if Self.verboseLogging { print("  ☁️  [\(n)] in iCloud — looks like a selfie, queued for download") }
                            return
                        }
                        noImage += 1
                        eval.note(asset, image: nil, gate: .noImage)
                        if Self.verboseLogging { print("  ⃠  [\(n)] no local image — \(note)") }
                        return
                    }
                    examine(asset, image, n: n)

                    // Throttled by time, not photo count: per-photo cost varies too
                    // much for "every Nth" to give a predictable update rate.
                    if Date().timeIntervalSince(lastReport) > 0.25 || n == total {
                        lastReport = Date()
                        DispatchQueue.main.async {
                            self?.sendToWeb(["type": "onGalleryScanProgress",
                                             "payload": ["done": n, "total": total]])
                        }
                    }
                }
            }

            // ---- iCloud pass -------------------------------------------------
            // The selfie-shaped thumbnails, downloaded small and examined like any
            // other photo. Bounded three ways: Wi-Fi only, `cloudDownloadCap`
            // photos, `cloudTimeBudget` seconds. The rest stay out, as every
            // iCloud-only photo did before.
            var cloudDownloaded = 0
            var cloudFailed = 0
            var cloudLeft = 0
            var cloudSeconds = 0.0
            let cloudAllowed = Self.cloudDownloadsAllowed
            let cloudStarted = Date()
            if !cloudCandidates.isEmpty && !cloudAllowed {
                print("☁️  \(cloudCandidates.count) iCloud selfie(s) not downloaded — not on Wi-Fi, or Low Data Mode is on")
            }
            for candidate in cloudCandidates {
                guard self?.scanGeneration == generation else {
                    print("\u{1f6d1} Scan superseded — stopping in the iCloud pass")
                    return
                }
                let withinBudget = Date().timeIntervalSince(cloudStarted) < Self.cloudTimeBudget
                guard cloudAllowed, withinBudget, cloudDownloaded + cloudFailed < Self.cloudDownloadCap else {
                    cloudLeft += 1
                    noImage += 1
                    eval.note(candidate.asset, image: nil, gate: .noImage)
                    continue
                }
                autoreleasepool {
                    let started = Date()
                    let image = self?.loadFromCloud(asset: candidate.asset, pixels: Self.cloudPixels, timeout: Self.cloudTimeout)
                    cloudSeconds += Date().timeIntervalSince(started)
                    guard let image else {
                        cloudFailed += 1
                        noImage += 1
                        eval.note(candidate.asset, image: nil, gate: .noImage)
                        if Self.verboseLogging { print("  ☁️  [\(candidate.n)] \(self?.lastLoadNote ?? "iCloud download failed")") }
                        return
                    }
                    cloudDownloaded += 1
                    if Self.verboseLogging, let cg = image.cgImage { print("  ☁️  [\(candidate.n)] downloaded \(cg.width)x\(cg.height) in \(String(format: "%.1f", Date().timeIntervalSince(started)))s") }
                    examine(candidate.asset, image, n: candidate.n)
                    // Keeps the page's stall timer quiet while this pass runs; the
                    // bar is already full, so only the message matters.
                    DispatchQueue.main.async {
                        self?.sendToWeb(["type": "onGalleryScanProgress",
                                         "payload": ["done": total, "total": total]])
                    }
                }
            }

            let elapsed = Date().timeIntervalSince(startedAt)
            let rate = Double(examined) / max(elapsed, 0.001)

            // Matches streamed in date order; the finished list goes back best-first.
            // Tiles are locked while the first scan runs, so the one re-order lands
            // before a finger can be on one.
            let ordered = Self.gridOrder(matchedIds, scores: matchScores)

            // Built here, off the main thread. The grid is passed in the order the
            // web will show it, because that order is what "the top" means.
            let evalReport = eval.finish(grid: ordered)

            DispatchQueue.main.async {
                guard self?.scanGeneration == generation else { return }

                print("""

                ==============================
                SCAN COMPLETE
                ==============================
                examined    \(examined) of \(total) in window
                no image    \(noImage)   (in iCloud with no usable copy on the phone, or unreadable)
                local copy  \(localCopies)   (in iCloud, scanned from the phone's smaller copy)
                iCloud      \(cloudOnly) only in iCloud; \(cloudCandidates.count) looked like selfies; \(cloudDownloaded) downloaded in \(String(format: "%.1f", cloudSeconds))s, \(cloudFailed) failed, \(cloudLeft) left (cap \(Self.cloudDownloadCap), \(Int(Self.cloudTimeBudget))s, Wi-Fi only\(cloudAllowed ? "" : " — was not on Wi-Fi"))
                no face     \(noFace)
                group       \(groupSkipped)   (skipped: more than one face)
                others      \(otherPeople)   (skipped: someone else in the photo)
                face small  \(tooSmall)   (under \(Int(Self.minFacePixels))px, even in the original)
                not full body \(notFullBody)   (not head to toe: head, \(Self.minAnkles)+ ankle, \(Int(Self.minBodySpan * 100))% span or \(Int(Self.minBodySpanBothAnkles * 100))% with both ankles, feet in frame)
                body retry  \(bodyRetried) re-checked at \(Int(Self.fullResPixels))px after a face match, \(bodyRescued) rescued
                no match    \(noMatch)
                sensitive   \(sensitiveSkipped)   (matched, then filtered)
                too large   \(tooLargeSkipped)   (original over \(Original.byteCap / 1_048_576)MB — hidden, nothing is sent compressed)
                no original \(noOriginal)   (original unreadable or not downloaded in time)
                low data    \(lowDataSkipped)   (only in iCloud, not downloaded — Low Data Mode is on)
                sized       \(sized) original(s), \(downloadedToSize) from iCloud, \(String(format: "%.1f", sizingSeconds))s
                MATCHED     \(matchedIds.count)   (selfie \(found[.selfie, default: 0]), front \(found[.front, default: 0]), side \(found[.side, default: 0]))
                elapsed     \(String(format: "%.1f", elapsed))s  (\(String(format: "%.0f", rate))/s)
                ==============================

                """)
                if let evalReport { print(evalReport) }

                self?.sendToWeb(["type": "onGalleryScanComplete",
                                 "payload": ["assetIds": ordered,
                                             "limited": self?.isLimitedAccess ?? false,
                                             // What the scan could not look at, for
                                             // analytics — the page shows none of it.
                                             "skipped": ["inCloud": cloudOnly,
                                                         "cloudSelfies": cloudCandidates.count,
                                                         "cloudDownloaded": cloudDownloaded,
                                                         "cloudLeft": cloudLeft,
                                                         "noImage": noImage]]])
            }
        }
    }

    /// The answer-key album's photo ids, or nil when eval mode is off or there is
    /// no such album. Nil switches `ScanEval` off entirely.
    /// The selfie to match against: the saved one in eval mode, otherwise the one
    /// just taken.
    ///
    /// Each scan's fresh selfie *is* the reference, so a slightly different angle or
    /// light moves every score — by about as much as the fixes being measured. The
    /// first eval run saves its selfie; later runs match against that. Only the
    /// host's reference is pinned: the web still uploads the selfie just taken.
    ///
    /// A face photo on disk, so it exists only in eval mode, is written with
    /// complete file protection, and is named so a reset does not delete it.
    static func evalReferenceSelfie(_ fresh: String) -> String {
        guard evalMode,
              let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return fresh }
        let url = dir.appendingPathComponent("swan-eval-selfie.jpg")

        if !evalResaveSelfie, let saved = try? Data(contentsOf: url) {
            let when = (try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate]) as? Date
            let stamp = DateFormatter()
            stamp.dateFormat = "d MMM HH:mm"
            print("\u{1f9ea} matching against the saved eval selfie (from \(when.map(stamp.string) ?? "?"))")
            return "data:image/jpeg;base64," + saved.base64EncodedString()
        }

        guard let comma = fresh.firstIndex(of: ","),
              let data = Data(base64Encoded: String(fresh[fresh.index(after: comma)...])) else { return fresh }
        do {
            try data.write(to: url, options: .completeFileProtection)
            print("\u{1f9ea} saved this selfie as the eval reference — later runs will match against it")
        } catch {
            print("\u{1f9ea} could not save the eval selfie: \(error) — matching against this run's only")
        }
        return fresh
    }

    func loadEvalLabels() -> Set<String>? {
        guard Self.evalMode else { return nil }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title == %@", Self.evalAlbumTitle)
        guard let album = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any,
                                                                 options: options).firstObject else {
            print("\u{1f9ea} eval mode is on, but there is no album named \"\(Self.evalAlbumTitle)\" — nothing will be measured")
            return nil
        }

        var ids = Set<String>()
        PHAsset.fetchAssets(in: album, options: nil).enumerateObjects { asset, _, _ in
            ids.insert(asset.localIdentifier)
        }
        print("\u{1f9ea} eval mode: \(ids.count) labelled photo(s) in \"\(Self.evalAlbumTitle)\"")
        // Limited access hides most of the library — the album included — so the
        // numbers would describe only what the tester happened to share.
        if isLimitedAccess { print("\u{1f9ea} limited photo access — grant Full Access, or these numbers mean little") }
        return ids
    }
}

// MARK: - Matching evaluation (debug only)
//
// Answers one question with numbers rather than by eye: are the photos reaching the
// grid actually of the user? A tester puts every photo that *should* reach it into an
// album, and each scan is scored against that album. Nothing here changes what the
// grid shows, and nothing leaves the phone.

/// Face numbers that no gate uses yet, recorded so the next gate can be chosen
/// from data rather than guessed.
struct FaceMetrics {
    /// Face width as a fraction of the frame's width — the raw Vision box, not the
    /// shorter-side ratio the selfie gate reads.
    let ratio: CGFloat
    let yaw: Double?
    /// Nil when Vision cannot tell.
    let pitch: Double?
    /// Vision's 0–1 capture quality. Apple positions it for comparing captures of
    /// the *same* person, so read it as a ranking hint, not an absolute bar.
    let quality: Float?

    /// One extra Vision pass — the quality request — on a handler that already
    /// holds the image, so the photo is not decoded a second time.
    init(_ face: VNFaceObservation, handler: VNImageRequestHandler) {
        let request = VNDetectFaceCaptureQualityRequest()
        request.inputFaceObservations = [face]
        try? handler.perform([request])

        ratio = face.boundingBox.width
        yaw = face.yaw?.doubleValue
        pitch = face.pitch?.doubleValue
        quality = request.results?.first?.faceCaptureQuality
    }
}

/// What decided one photo, in the order the scan applies them.
enum EvalGate: String, CaseIterable {
    case noImage, noFace, group, faceTooSmall, otherPeople, notFullBody, noMatch, sensitive
    /// Matched, but its original is over the cap, or could not be read or sized.
    case tooLarge, noOriginal
    /// Passed everything and was shown to the user.
    case grid
}

/// One photo's fate in one scan.
struct EvalRecord {
    let id: String
    let gate: EvalGate
    let distance: Float?
    let type: PhotoType?
    /// Nil for a photo that never reached the body check.
    let body: BodyCheck?
    let metrics: FaceMetrics?
    /// Face re-cropped from a larger render. Nil for a photo never scored.
    let fullRes: Bool?
    let rotated: Bool
    let screenshot: Bool
    /// In the answer-key album — a photo that *should* reach the grid.
    let labelled: Bool
    /// When it was taken, so a tester can find it in Photos — the id cannot be
    /// searched for.
    let taken: Date?
    /// The original's own size, from its metadata — nothing is loaded to get it.
    /// Beside `renderWidth`, it says whether a larger crop was even possible.
    let originalSize: String
    /// Width of the render the scan actually worked on.
    let renderWidth: Int?
    /// The original file's size, for a photo that reached the grid.
    let originalBytes: Int?
}

/// Scores one scan against the answer-key album.
///
/// A value, not a class: the scan loop owns one per run and hands a finished copy
/// to the main thread, so nothing is shared between threads.
struct ScanEval {

    /// The album's ids. Nil when eval mode is off or the album is missing, which
    /// makes every method below a no-op — so the scan loop needs no `if` of its own.
    let labels: Set<String>?
    private(set) var records: [EvalRecord] = []

    /// What a Muse needs. Mirrors `COVERAGE` in galleryConstants.ts — keep in step.
    static let coverageNeed: [(PhotoType, Int)] = [(.selfie, 1), (.front, 2), (.side, 2)]

    init(labels: Set<String>?) { self.labels = labels }

    /// How a date reads in the printed report — how Photos shows it.
    static let shownDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy HH:mm"
        return formatter
    }()

    /// How a date sits in the CSV — sortable.
    static let csvDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    mutating func note(_ asset: PHAsset, image: UIImage?, rotated: Bool = false, gate: EvalGate,
                       distance: Float? = nil, type: PhotoType? = nil,
                       body: BodyCheck? = nil, metrics: FaceMetrics? = nil,
                       fullRes: Bool? = nil, originalBytes: Int? = nil) {
        guard let labels else { return }
        records.append(EvalRecord(
            id: asset.localIdentifier,
            gate: gate,
            distance: distance,
            type: type,
            body: body,
            metrics: metrics,
            fullRes: fullRes,
            rotated: rotated,
            screenshot: asset.mediaSubtypes.contains(.photoScreenshot),
            labelled: labels.contains(asset.localIdentifier),
            taken: asset.creationDate,
            originalSize: "\(asset.pixelWidth)x\(asset.pixelHeight)",
            renderWidth: image?.cgImage?.width,
            originalBytes: originalBytes
        ))
    }

    /// Builds the printed summary and writes the CSV. Nil when eval mode is off.
    ///
    /// `grid` is the order the shopper will see, because that order is what "the
    /// top" means — so this stays right once the grid is sorted.
    func finish(grid: [String]) -> String? {
        guard let labels else { return nil }

        let byId = Dictionary(records.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let labelledInWindow = records.filter(\.labelled).count
        let outsideWindow = labels.count - labelledInWindow

        // The matcher alone: every photo that reached scoring, whatever the
        // threshold then decided. Gates are excluded on purpose — they are
        // measured separately, per gate, below.
        let scored = records.filter { $0.distance != nil }
        let correctDistances = scored.filter(\.labelled).compactMap(\.distance)
        let wrongDistances = scored.filter { !$0.labelled }.compactMap(\.distance)
        let auc = Self.auc(correct: correctDistances, wrong: wrongDistances)

        // Split by kind, because the two behave nothing alike: a close-up selfie
        // against the selfie reference is easy, a small full-length face is not —
        // and one combined number lets the easy half hide the hard one.
        func splitAUC(_ types: Set<PhotoType>) -> (auc: Double?, correct: Int, wrong: Int) {
            let group = scored.filter { $0.type.map(types.contains) ?? false }
            let correct = group.filter(\.labelled).compactMap(\.distance)
            let wrong = group.filter { !$0.labelled }.compactMap(\.distance)
            return (Self.auc(correct: correct, wrong: wrong), correct.count, wrong.count)
        }
        let selfieAUC = splitAUC([.selfie])
        let fullBodyAUC = splitAUC([.front, .side])
        let aucText = { (value: Double?) in value.map { String(format: "%.3f", $0) } ?? "n/a" }

        let top = grid.prefix(ViewController.evalTopN)
        let topCorrect = top.filter { labels.contains($0) }.count
        let gridCorrect = grid.filter { labels.contains($0) }.count

        // Whether the correct photos alone could complete a Muse. Precision can be
        // bought by showing nothing; this is what catches that.
        var have: [PhotoType: Int] = [:]
        for id in grid where labels.contains(id) {
            if let type = byId[id]?.type { have[type, default: 0] += 1 }
        }
        let fillable = Self.coverageNeed.allSatisfy { have[$0.0, default: 0] >= $0.1 }
        let coverage = Self.coverageNeed
            .map { "\($0.0.rawValue) \(have[$0.0, default: 0])/\($0.1)" }
            .joined(separator: ", ")

        // Per gate: what it rightly kept out, and what it wrongly threw away.
        let gates = EvalGate.allCases.filter { $0 != .grid }.map { gate -> String in
            let here = records.filter { $0.gate == gate }
            let lost = here.filter(\.labelled).count
            let name = gate.rawValue.padding(toLength: 14, withPad: " ", startingAt: 0)
            return "  \(name)\(here.count - lost) wrong caught, \(lost) correct lost"
        }.joined(separator: "\n")

        let screenshots = records.filter(\.screenshot)
        let rank = Dictionary(grid.enumerated().map { ($1, $0 + 1) }, uniquingKeysWith: { first, _ in first })
        let csv = writeCSV(rank: rank)

        func ratio(_ part: Int, _ whole: Int) -> String {
            whole == 0 ? "n/a" : String(format: "%.2f", Double(part) / Double(whole))
        }

        // Every photo worth looking at, in terms a tester can find in Photos: the
        // grid tile by tile, and each of theirs that never reached it. Original size
        // beside scan width says whether a sharper crop was possible at all.
        func where_(_ r: EvalRecord) -> String {
            let taken = r.taken.map(Self.shownDate.string(from:)) ?? "no date"
            return "\(taken)   \(r.originalSize), scanned at \(r.renderWidth.map(String.init) ?? "–")px"
        }
        let gridLines = grid.prefix(ViewController.evalTopN).enumerated().compactMap { index, id -> String? in
            guard let r = byId[id] else { return nil }
            let who = r.labelled ? "YOU" : "no "
            let score = r.distance.map { String(format: "%.3f", $0) } ?? "?"
            let kind = (r.type?.rawValue ?? "?").padding(toLength: 6, withPad: " ", startingAt: 0)
            let bodySays = r.type == .front || r.type == .side
                ? "sh \((r.body?.shoulderSpread.map { String(format: "%.2f", $0) } ?? "?").padding(toLength: 7, withPad: " ", startingAt: 0))"
                : "          "
            return "  tile \(String(index + 1).padding(toLength: 3, withPad: " ", startingAt: 0)) \(who)  \(kind) d \(score)  \(bodySays)  \(r.fullRes == true ? "re-cropped" : "          ")  \(where_(r))"
        }
        // The shoulders decide the type; the head turn is logged beside them to see how
        // often it would have disagreed. Only full-length photos that reached scoring.
        let fullLength = scored.filter { $0.type == .front || $0.type == .side }
        let typeCompared = fullLength.filter { $0.body?.shoulderSpread != nil }
        let typeDisagree = typeCompared.filter { r in
            r.metrics?.yaw.map { ViewController.headType(yaw: $0) != r.type } ?? false
        }

        let missedLines = records.filter { $0.labelled && $0.gate != .grid }.map { r in
            "  \(r.gate.rawValue.padding(toLength: 13, withPad: " ", startingAt: 0)) \(where_(r))"
        }
        let gridBlock = (["grid        in the order shown"] + gridLines).joined(separator: "\n")
        let missedBlock = missedLines.isEmpty
            ? "missed      none"
            : (["missed      \(missedLines.count) of yours never reached the grid"] + missedLines).joined(separator: "\n")

        return """

        ==============================
        MATCHING EVAL — "\(ViewController.evalAlbumTitle)"
        ==============================
        settings    threshold \(String(format: "%.2f", ViewController.matchThreshold)) (\(String(format: "%.2f", ViewController.profileMatchThreshold)) profile side, \(String(format: "%.2f", ViewController.selfieMatchThreshold)) selfie), face padding \(String(format: "%.2f", ViewController.facePadding)), body span \(String(format: "%.2f", ViewController.minBodySpan)) (\(String(format: "%.2f", ViewController.minBodySpanBothAnkles)) with both ankles), feet room \(String(format: "%.2f", ViewController.minFootRoom))×span, ankles \(ViewController.minAnkles)+
        labelled    \(labelledInWindow) in the window\(outsideWindow > 0 ? ", \(outsideWindow) outside it (ignored)" : "")
        AUC         \(aucText(auc))   (matcher only: \(correctDistances.count) correct vs \(wrongDistances.count) wrong, of photos that reached scoring)
          selfies     \(aucText(selfieAUC.auc))   (\(selfieAUC.correct) correct vs \(selfieAUC.wrong) wrong)
          full body   \(aucText(fullBodyAUC.auc))   (\(fullBodyAUC.correct) correct vs \(fullBodyAUC.wrong) wrong — front and side)
        top \(ViewController.evalTopN)      precision \(ratio(topCorrect, top.count))   (\(topCorrect) of \(top.count) correct; grid has \(grid.count))
        recall      \(ratio(gridCorrect, labelledInWindow))   (\(gridCorrect) of \(labelledInWindow) correct photos reached the grid)
        coverage    \(fillable ? "fillable" : "NOT fillable")   (correct photos only: \(coverage))
        in grid     \(gridCorrect) correct, \(grid.count - gridCorrect) wrong
        by gate
        \(gates)
        rotated     \(records.filter(\.rotated).count) photo(s) arrived rotated (turned upright)
        type check  \(typeCompared.count) of \(fullLength.count) full-length photo(s) typed by shoulders (side under \(String(format: "%.2f", ViewController.sideShoulderSpread))), \(fullLength.count - typeCompared.count) by head turn (shoulders not measured); head turn would have differed on \(typeDisagree.count)\(typeDisagree.isEmpty ? "" : " — " + typeDisagree.map { "\($0.type?.rawValue ?? "?") at \(String(format: "%.2f", $0.body?.shoulderSpread ?? 0))" }.joined(separator: "; "))
        full-res    \(records.filter { $0.fullRes == true }.count) of \(scored.count) scored photo(s) re-cropped from a larger render
        screenshots \(screenshots.count) in the window, \(screenshots.filter { $0.gate == .grid }.count) reached the grid
        \(gridBlock)
        \(missedBlock)
        csv         \(csv ?? "not written")
        note        eval mode adds a face-quality pass per photo — compare scan rates with it on both times
        ==============================

        """
    }

    /// The chance a correct photo scores closer than a wrong one, ties counting
    /// half: 0.5 is a coin toss, 1.0 separates them perfectly. Pairwise, because at
    /// a few thousand scored photos the plain loop is fast enough and easy to check.
    static func auc(correct: [Float], wrong: [Float]) -> Double? {
        guard !correct.isEmpty, !wrong.isEmpty else { return nil }
        var wins = 0.0
        for c in correct {
            for w in wrong { wins += c < w ? 1 : (c == w ? 0.5 : 0) }
        }
        return wins / Double(correct.count * wrong.count)
    }

    /// Ids and numbers only — no pixels — into Documents, named so a reset does not
    /// delete it the way it does the debug crops. Pull it off the device the same
    /// way: Xcode > Window > Devices and Simulators > Download Container.
    private func writeCSV(rank: [String: Int]) -> String? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }

        let stamp = DateFormatter()
        stamp.dateFormat = "yyyyMMdd-HHmmss"
        let name = "swan-eval-\(stamp.string(from: Date())).csv"

        let number = { (value: Double?) in value.map { String(format: "%.4f", $0) } ?? "" }
        var lines = ["id,gate,labelled,gridRank,distance,type,joints,ankles,headSeen,span,footRoom,people,shoulders,hips,headSays,faceRatio,yaw,pitch,quality,rotated,screenshot,fullRes,taken,original,renderWidth,originalKB"]
        for record in records {
            // Typed, and in three parts: one literal this long is more than Swift's
            // type-checker will solve in reasonable time.
            let body = record.body
            let identity: [String] = [
                record.id,
                record.gate.rawValue,
                "\(record.labelled)",
                rank[record.id].map(String.init) ?? "",
                number(record.distance.map { Double($0) }),
                record.type?.rawValue ?? "",
            ]
            let bodyFields: [String] = [
                body.map { String($0.lowerJoints) } ?? "",
                body.map { String($0.ankles) } ?? "",
                body.map { String($0.headSeen) } ?? "",
                number(body.map { Double($0.span) }),
                number(body.map { Double($0.footRoom) }),
                body.map { String($0.people) } ?? "",
                number(body?.shoulderSpread.map { Double($0) }),
                number(body?.hipSpread.map { Double($0) }),
                record.metrics?.yaw.map { ViewController.headType(yaw: $0).rawValue } ?? "",
            ]
            let faceFields: [String] = [
                number(record.metrics.map { Double($0.ratio) }),
                number(record.metrics?.yaw),
                number(record.metrics?.pitch),
                number(record.metrics?.quality.map { Double($0) }),
                "\(record.rotated)",
                "\(record.screenshot)",
                record.fullRes.map { String($0) } ?? "",
                record.taken.map(Self.csvDate.string(from:)) ?? "",
                record.originalSize,
                record.renderWidth.map(String.init) ?? "",
                record.originalBytes.map { String($0 / 1024) } ?? "",
            ]
            lines.append((identity + bodyFields + faceFields).joined(separator: ","))
        }

        do {
            try lines.joined(separator: "\n")
                .write(to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
            return name
        } catch {
            print("\u{1f9ea} eval CSV not written: \(error)")
            return nil
        }
    }
}

/// Carries one answer out of the Task above.
///
/// A captured `var` cannot be mutated from a `@Sendable` closure, so the result
/// travels by reference instead. Unchecked is honest here rather than a shrug:
/// the semaphore establishes the ordering — the write happens before `signal`,
/// the read after `wait` — so there is no concurrent access to check.
private final class SensitivityResult: @unchecked Sendable {
    var value = false
}

// MARK: - Sensitive content
//
// Best-effort nudity filtering with Apple's on-device classifier. Everything
// here is written around one fact: the check usually cannot run.

extension ViewController {

    /// Prints whether the filter will actually do anything this scan.
    ///
    /// Not optional logging. A scan with no "sensitive" lines has two completely
    /// different explanations — a clean library, or a filter that never ran — and
    /// nothing else in the console tells them apart. Read this alongside the
    /// `sensitive` tally in the summary.
    func logSensitivityPolicy() {
        let policy = SCSensitivityAnalyzer().analysisPolicy
        print(policy == .disabled
              ? "\u{1f6ab} sensitivity filter: OFF — no entitlement, or Sensitive Content Warning is off in Settings"
              : "\u{1f6ab} sensitivity filter: on (\(policy))")
    }

    /// Whether Apple's classifier says this photo is sensitive.
    ///
    /// Opt-in per device (Settings > Privacy > Sensitive Content Warning) and off
    /// by default, so this usually returns false and costs nothing. Runs last,
    /// only on photos that already matched.
    func isSensitiveContent(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }

        let analyzer = SCSensitivityAnalyzer()

        // Apple's contract: check the policy and respect it. Analysing anyway is
        // not a supported path — this is a consent mechanism, not a feature flag.
        guard analyzer.analysisPolicy != .disabled else { return false }

        let semaphore = DispatchSemaphore(value: 0)
        let result = SensitivityResult()

        Task {
            defer { semaphore.signal() }
            do {
                result.value = try await analyzer.analyzeImage(cgImage).isSensitive
            } catch {
                // Shown rather than skipped. An analysis that failed says nothing
                // about the photo, and treating "we could not tell" as "it is
                // sensitive" would hide the user's own photos from them.
                print("\u{26a0}\u{fe0f} Sensitive content analysis failed: \(error)")
            }
        }

        semaphore.wait()
        return result.value
    }
}

// MARK: - Captured photos

/// Photos the user took inside the flow, held for the life of the flow.
///
/// **Nothing here is written to the photo library.** The web layer takes a shot,
/// hands the bytes over once, and then refers to it only by id — so the id has to
/// resolve to bytes somewhere, and this is that somewhere.
///
/// It exists for memory. A 1600px capture is ~1.3MB as a JavaScript string and
/// ~10MB once decoded for display; a dozen of those in a grid is enough for iOS to
/// kill the WebContent process, which is the blank-screen crash
/// `webViewWebContentProcessDidTerminate` exists to recover from. Held here as
/// `Data` in the app process it is ~5MB total, and the web layer holds nothing but
/// a URL per photo.
///
/// File scope, beside `Thumbnail`, because both the view controller and
/// `PhotoSchemeHandler` — which holds no reference to it — have to reach it.
/// What the scan worked out about one photo, kept so it need not be worked out
/// twice.
struct ScanAnalysis {
    let type: PhotoType
    let body: BodyCheck
}

/// What pose detection found of one person's body, and the one verdict drawn from it.
///
/// A value rather than a joint count, so the scan, the tap and what the web is
/// told as `isFullBody` all read the same rule — a count compared at three call
/// sites is how they drift apart.
struct BodyCheck {
    /// Knees and ankles seen, 0–4. What the old gate counted, and still what the web
    /// receives as `lowerBodyJoints`.
    let lowerJoints: Int
    let ankles: Int
    /// Any of the nose, eyes or ears.
    let headSeen: Bool
    /// Highest head point to lowest ankle, as a fraction of the image height.
    let span: CGFloat
    /// Lowest ankle to the bottom edge, as a fraction of the image height. Zero with
    /// no ankle seen.
    let footRoom: CGFloat
    /// People Vision's person detector finds in the whole photo, faces or not.
    let people: Int

    /// Someone besides the shopper is in the photo. One rule for the scan gate and
    /// what the web is told as `otherPeople`, so a photo cannot pass one and fail the other.
    var hasOthers: Bool { people > 1 }

    /// Shoulder and hip width across the photo against the torso's length: about 0.6
    /// facing the camera, under 0.35 side-on. Nil when the joints were not found.
    let shoulderSpread: CGFloat?
    let hipSpread: CGFloat?

    /// Which way the body faces, by the shoulders. Decides front or side whatever the
    /// head is doing; the head's turn is used only when this is nil.
    var bodyFacing: PhotoType? {
        shoulderSpread.map { $0 < ViewController.sideShoulderSpread ? .side : .front }
    }

    static let none = BodyCheck(lowerJoints: 0, ankles: 0, headSeen: false, span: 0, footRoom: 0, people: 0,
                                shoulderSpread: nil, hipSpread: nil)

    /// Head to toe: the head in frame, enough ankles, a body tall enough in the frame
    /// to be the subject rather than someone in the background, and room below the
    /// ankles for the feet.
    var isHeadToToe: Bool {
        let needed = ankles >= 2 ? ViewController.minBodySpanBothAnkles : ViewController.minBodySpan
        return headSeen && ankles >= ViewController.minAnkles && span >= needed
            && footRoom >= ViewController.minFootRoom * span
    }
}

/// Analyses produced during the scan, by asset id.
///
/// The scan computes type and joints for every photo it matches, then throws them
/// away — and `analysePhoto` reloads the photo and re-runs pose detection to get
/// the same answers back when the user taps. Keeping them turns that tap into a
/// dictionary lookup, and guarantees the two agree: a photo counted as `side`
/// while deciding when to stop cannot report `front` a moment later.
///
/// Locked for the same reason as `CaptureStore` — written on the scan's queue,
/// read on the analysis queue.
enum ScanAnalysisStore {
    private static var held: [String: ScanAnalysis] = [:]
    private static let lock = NSLock()

    static func store(_ analysis: ScanAnalysis, id: String) {
        lock.lock(); defer { lock.unlock() }
        held[id] = analysis
    }

    static func analysis(for id: String) -> ScanAnalysis? {
        lock.lock(); defer { lock.unlock() }
        return held[id]
    }

    static func removeAll() {
        lock.lock(); defer { lock.unlock() }
        held.removeAll()
    }
}

enum CaptureStore {

    /// How many photos the flow will hold. Generous for five slots with retakes,
    /// low enough that the store stays a rounding error against the app's budget.
    static let limit = 12

    /// Original capture JPEGs by id. `Data`, never `UIImage`: a decoded
    /// 1600x1600 is ~10MB, so twelve decoded would be 120MB — the exact problem
    /// this store exists to avoid.
    private static var held: [String: Data] = [:]
    private static var order: [String] = []

    /// Reads arrive on two background queues and writes on main, so this is not a
    /// place to follow the rest of the file's unsynchronised habit: a torn `Int`
    /// like `scanGeneration` is harmless, a Dictionary mutated during a concurrent
    /// read corrupts the heap. Held only across the dictionary access — `Data` is
    /// a value type, so decoding happens outside.
    private static let lock = NSLock()

    /// False when the store is full. Refusing beats evicting: an evicted photo is
    /// still on screen looking selectable, and the user finds out when the tile
    /// breaks.
    static func store(_ data: Data, id: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard held[id] != nil || held.count < limit else { return false }
        if held[id] == nil { order.append(id) }
        held[id] = data
        return true
    }

    static func data(for id: String) -> Data? {
        lock.lock(); defer { lock.unlock() }
        return held[id]
    }

    static func removeAll() {
        lock.lock(); defer { lock.unlock() }
        held.removeAll()
        order.removeAll()
    }

    static var count: Int {
        lock.lock(); defer { lock.unlock() }
        return held.count
    }

    /// The held bytes at a requested size.
    ///
    /// Returns them untouched when nothing needs shrinking — a capture already
    /// arrives at upload size, so the upload path costs no decode and loses no
    /// quality to a second JPEG pass. Only the grid tile actually resizes.
    static func render(_ data: Data, maxPixel: CGFloat, quality: CGFloat) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        guard longest > maxPixel else { return data }

        let scale = maxPixel / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}

// MARK: - Thumbnails

/// Shared by both delivery paths so a photo looks identical however it arrives.
enum Thumbnail {

    /// Grid tiles. Small and fast — dozens are requested at once.
    static let gridPixels: CGFloat = 256
    static let gridQuality: CGFloat = 0.7

    /// A large render, for the `?size=full` display path and for photos taken in the
    /// flow. Library photos are uploaded as their original file — see `Original`.
    static let fullPixels: CGFloat = 1600
    static let fullQuality: CGFloat = 0.85

    /// JPEG bytes for an id, or nil if it cannot be read.
    ///
    /// The id is a `PHAsset.localIdentifier`, or one of the ids `CaptureStore`
    /// holds for a photo taken inside the flow. Both resolve here rather than at
    /// the three call sites, so the scheme handler, the base64 fallback and the
    /// upload fetch all gain captures at once — miss one and photos would work on
    /// most devices and be invisible on exactly the ones already falling back.
    ///
    /// Routing is by key, not by id shape: a localIdentifier is never in the
    /// store, so there is no prefix to parse and no new way to be wrong.
    ///
    /// `allowNetwork` is the iCloud split: grid tiles pass true (~20KB, display
    /// only), full-size renders never do. Asking PhotoKit for the size we want
    /// means the 12MP original is never decoded, and `jpegData` returns sRGB with
    /// rotation applied and metadata — including GPS — dropped.
    static func jpeg(for localIdentifier: String,
                     maxPixel: CGFloat,
                     quality: CGFloat,
                     allowNetwork: Bool = false) -> Data? {
        if let held = CaptureStore.data(for: localIdentifier) {
            let rendered = CaptureStore.render(held, maxPixel: maxPixel, quality: quality)
            // Logged for every size, unlike the PhotoKit path below: captures are at
            // most a dozen so this cannot flood, and a capture that will not render
            // is the failure this whole store is most likely to produce.
            print(rendered == nil
                  ? "  ❌ capture render FAILED \(localIdentifier) at \(Int(maxPixel))px"
                  : "  🖼 served capture \(localIdentifier) — \(rendered!.count / 1024)KB at \(Int(maxPixel))px")
            return rendered
        }

        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier],
                                              options: nil).firstObject else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = allowNetwork
        options.isSynchronous = true

        var data: Data?
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: maxPixel, height: maxPixel),
            // `.aspectFit` at every size, grid tiles included. `.aspectFill` used
            // to square them off, which cost the sides of a portrait — and the web
            // layer then cropped the result a second time. On a full-length photo
            // that removed the legs, so a thumbnail could not be told apart from a
            // waist-up shot until the user tapped it and was refused.
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            data = image?.jpegData(compressionQuality: quality)
        }
        return data
    }
}

/// One streamed read, from the two queues that touch it.
///
/// `requestData` delivers chunks and its completion on PhotoKit's own queue
/// while the caller waits on a semaphore — and the caller can walk away on a
/// timeout while chunks are still arriving. A `Data` appended from one thread
/// and read from another is a corrupted heap, not a torn value, so this is not a
/// place to leave unsynchronised.
///
/// `done` is what makes a walked-away read harmless: once it is set, later
/// chunks are dropped on the floor instead of growing a buffer nobody will read.
private final class ReadState {
    private var collected = Data()
    private var counted = 0
    private var overCap = false
    private var failed = false
    private var done = false
    private let lock = NSLock()

    /// Counts the chunk, and keeps it only when `keep` is set — the scan sizes an
    /// original without holding any of it. True once past the cap, so the read can
    /// stop there rather than download the rest.
    func append(_ chunk: Data, cap: Int, keep: Bool) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard !done, !overCap else { return overCap }
        counted += chunk.count
        if counted > cap {
            // Dropped rather than kept: past the cap these bytes are never going
            // to be sent, so holding them is pure cost.
            overCap = true
            collected.removeAll(keepingCapacity: false)
            return true
        }
        if keep { collected.append(chunk) }
        return false
    }

    func finish(failed didFail: Bool) {
        lock.lock(); defer { lock.unlock() }
        guard !done else { return }
        done = true
        failed = didFail
        if didFail { collected.removeAll(keepingCapacity: false) }
    }

    func result() -> (data: Data, count: Int, overCap: Bool, failed: Bool) {
        lock.lock(); defer { lock.unlock() }
        return (collected, counted, overCap, failed)
    }
}

/// The photo's own file, as the camera wrote it.
///
/// `Thumbnail.jpeg` goes through `requestImage`, which hands back a *decoded
/// bitmap* — so the file container is gone, and with it EXIF, GPS and any depth
/// auxiliary data, before any resizing happens. `PHAssetResource` is the only way
/// to the bytes themselves.
///
/// There is no rendered fallback. A photo is sent as its original or not at all:
/// the scan hides any photo whose original is over the cap or cannot be read, and
/// an upload that still meets one reports the reason as a failure.
enum Original {

    /// How much of one file we will carry.
    ///
    /// The number that matters is what it costs in the page: at the cap a file is
    /// 13.3MB as base64 crossing the bridge, plus a ~10MB Blob while that string is
    /// still alive. The web uploads one photo at a time, which is what keeps it to
    /// one. Each half of a Live Photo is measured separately, well under the
    /// server's 25MB per register request.
    static let byteCap = 10 * 1024 * 1024

    /// How long an upload waits for one file. Comfortably inside the web layer's own
    /// 30s deadline for a photo, so a stalled iCloud download is answered by us
    /// rather than by the page giving up.
    static let readTimeout: DispatchTimeInterval = .seconds(20)

    /// How long the scan waits to size one iCloud-only original. Shorter than an
    /// upload: the shopper is waiting on the scan, and a photo that cannot be sized
    /// in time is simply hidden.
    static let sizeTimeout: DispatchTimeInterval = .seconds(10)

    /// What marks the paired half of a Live Photo, appended to the asset id.
    ///
    /// The two halves travel as two uploads sharing a base id, and the service
    /// pairs them by stripping this. It marks the *role*, not the format.
    static let videoSuffix = ".mov"

    /// Why an original cannot be sent. Reported to the web layer, which counts the
    /// photo as failed — there is nothing else to send.
    enum Unavailable: String, Error {
        /// The file is larger than we will carry.
        case tooLarge
        /// No resource, or the read failed — including an iCloud download that
        /// could not complete.
        case unreadable
        /// The read did not finish in time — almost always an iCloud download on
        /// a poor connection.
        case tooSlow
    }

    struct Bytes {
        let data: Data
        /// From the resource's UTI — `image/heic` for most modern photos. The
        /// presigned PUT signs for whatever this says, so it has to be right.
        let mime: String
    }

    /// The resource's bytes, for upload. `allowNetwork` fetches an iCloud-offloaded
    /// original: the handful of photos the shopper picked are worth the download.
    static func bytes(for asset: PHAsset,
                      allowNetwork: Bool,
                      type: PHAssetResourceType = .photo) -> Result<Bytes, Unavailable> {
        read(asset, allowNetwork: allowNetwork, type: type, keep: true, timeout: readTimeout)
            .map { Bytes(data: $0.data, mime: $0.mime) }
    }

    /// The original's size in bytes, counted as it streams and kept nowhere — no
    /// memory held, nothing written by us. Stops the moment it passes the cap, so an
    /// iCloud photo is downloaded no further than that.
    static func size(for asset: PHAsset, allowNetwork: Bool) -> Result<Int, Unavailable> {
        read(asset, allowNetwork: allowNetwork, type: .photo, keep: false, timeout: sizeTimeout)
            .map { $0.count }
    }

    /// One streamed read of the resource, **abandoned the moment the running total
    /// crosses the cap** — so a 75MB ProRAW costs `byteCap` at most and never the
    /// file. `PHAssetResource` does not publicly expose a size, so counting as it
    /// arrives is the only way to know without private API.
    private static func read(_ asset: PHAsset,
                             allowNetwork: Bool,
                             type: PHAssetResourceType,
                             keep: Bool,
                             timeout: DispatchTimeInterval) -> Result<(data: Data, count: Int, mime: String), Unavailable> {
        let resources = PHAssetResource.assetResources(for: asset)
        // `.fullSizePhoto`/`.fullSizePairedVideo` exist once a photo has been
        // edited, and are the version the user actually sees — preferred for that
        // reason, with the untouched original after it.
        let edited: PHAssetResourceType = type == .photo ? .fullSizePhoto : .fullSizePairedVideo
        guard let resource = resources.first(where: { $0.type == edited })
                ?? resources.first(where: { $0.type == type }) else { return .failure(.unreadable) }

        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = allowNetwork

        let state = ReadState()
        let done = DispatchSemaphore(value: 0)

        let request = PHAssetResourceManager.default().requestData(
            for: resource,
            options: options,
            // Past the cap the waiting thread is woken at once, and cancels.
            dataReceivedHandler: { chunk in
                if state.append(chunk, cap: byteCap, keep: keep) { done.signal() }
            },
            completionHandler: { error in
                state.finish(failed: error != nil)
                done.signal()
            }
        )

        let waited = done.wait(timeout: .now() + timeout)
        let (collected, count, overCap, failed) = state.result()

        if overCap {
            PHAssetResourceManager.default().cancelDataRequest(request)
            state.finish(failed: true)
            return .failure(.tooLarge)
        }
        if waited == .timedOut {
            PHAssetResourceManager.default().cancelDataRequest(request)
            state.finish(failed: true)
            return .failure(.tooSlow)
        }
        // With network access off this is an asset that lives only in iCloud;
        // with it on, a download that did not complete.
        if failed || count == 0 { return .failure(.unreadable) }

        return .success((collected, count, mime(for: resource)))
    }

    /// The resource's UTI as a MIME type. Falls back to JPEG rather than guessing
    /// wrong: a declared type the bytes do not match breaks the presigned PUT.
    static func mime(for resource: PHAssetResource) -> String {
        switch resource.uniformTypeIdentifier.lowercased() {
        case "public.heic", "public.heif": return "image/heic"
        case "public.png": return "image/png"
        case "com.compuserve.gif": return "image/gif"
        case "com.apple.quicktime-movie": return "video/quicktime"
        case "public.mpeg-4": return "video/mp4"
        default: return "image/jpeg"
        }
    }
}

extension ViewController {

    /// Sends one photo to the web layer as a data URI, for upload.
    ///
    /// `fetch("swan-photo://…")` is refused by WebKit before the scheme handler
    /// runs, so the bytes have to cross the bridge. One photo per message keeps
    /// the peak bounded however many were chosen.
    ///
    /// Always the **original file**, never a re-encode: the build service reads
    /// depth and detail out of it. A Live Photo says so with `hasVideo`, and its
    /// paired video is asked for next under the same id plus `.mov`.
    func sendFullImage(id: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            func reply(_ payload: [String: Any]) {
                DispatchQueue.main.async {
                    self?.sendToWeb(["type": "onGalleryFullImage", "payload": payload])
                }
            }
            let startedAt = Date()
            func ms() -> Int { Int(Date().timeIntervalSince(startedAt) * 1000) }

            // The paired half of a Live Photo, asked for under the still's id with
            // a suffix. Best effort: a failure here means the still goes up alone.
            let wantsVideo = id.hasSuffix(Original.videoSuffix)
            let assetId = wantsVideo ? String(id.dropLast(Original.videoSuffix.count)) : id

            // A photo taken inside the flow has no asset and no original — it is
            // already a capture at upload size, sent as held.
            if !wantsVideo, CaptureStore.data(for: assetId) != nil {
                guard let data = Thumbnail.jpeg(for: id,
                                                maxPixel: Thumbnail.fullPixels,
                                                quality: Thumbnail.fullQuality) else {
                    print("  \u{274c} capture FAILED \(id)")
                    reply(["id": id, "error": "unavailable"])
                    return
                }
                reply(["id": id, "dataURI": "data:image/jpeg;base64," + data.base64EncodedString(), "original": false])
                return
            }

            guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject else {
                print("  \u{274c} no photo for \(assetId)")
                reply(["id": id, "error": "unavailable"])
                return
            }

            if wantsVideo {
                guard asset.mediaSubtypes.contains(.photoLive) else {
                    print("  \u{274c} no paired video for \(assetId)")
                    reply(["id": id, "error": "unavailable"])
                    return
                }
                switch Original.bytes(for: asset, allowNetwork: true, type: .pairedVideo) {
                case .success(let video):
                    print("  \u{1f3ac} paired video \(id) — \(video.data.count / 1024)KB \(video.mime) (\(ms())ms)")
                    reply(["id": id,
                           "dataURI": "data:\(video.mime);base64," + video.data.base64EncodedString(),
                           "original": true])
                case .failure(let reason):
                    print("  \u{2935} paired video \(assetId) — \(reason.rawValue), the still goes alone")
                    reply(["id": id, "error": reason.rawValue])
                }
                return
            }

            let isLive = asset.mediaSubtypes.contains(.photoLive)
            switch Original.bytes(for: asset, allowNetwork: true) {
            case .success(let original):
                print("  \u{1f4e6} original \(id) — \(isLive ? "live" : "still"), \(original.data.count / 1024)KB \(original.mime) (\(ms())ms)")
                reply(["id": id,
                       "dataURI": "data:\(original.mime);base64," + original.data.base64EncodedString(),
                       "original": true,
                       "hasVideo": isLive])
            case .failure(let reason):
                // Not rendered instead: a photo goes as its original or not at all.
                print("  \u{274c} original FAILED \(id) — \(reason.rawValue), not sent (\(ms())ms)")
                reply(["id": id, "error": reason.rawValue])
            }
        }
    }

    /// Reports how the person is positioned in one photo.
    ///
    /// Both fields are required by the web layer: a reply missing `type` or
    /// `isFullBody` has every photo rejected and the build button never enables.
    func analysePhoto(id: String) {
        // The scan already worked this out on the way past. Answering from the
        // store skips a PhotoKit load and two Vision passes, and — the real point —
        // guarantees the verdict matches the one used to decide the scan had found
        // enough. Recomputing risks a photo counted as `side` coming back `front`.
        if let cached = ScanAnalysisStore.analysis(for: id) {
            sendAnalysis(id: id, captured: false, body: cached.body, type: cached.type, cached: true)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in

            guard let self = self else { return }

            // The only PhotoKit part. Everything past it works on a decoded image,
            // which is what lets a photo taken in the flow share the same analysis.
            guard
                let asset = PHAsset.fetchAssets(
                    withLocalIdentifiers: [id],
                    options: nil
                ).firstObject,
                let image = self.loadPhoto(asset: asset)
            else {
                print("❌ analyse FAILED \(id)")

                DispatchQueue.main.async {
                    self.sendToWeb([
                        "type": "onGalleryPhotoAnalysis",
                        "payload": [
                            "assetId": id,
                            "error": "unavailable"
                        ]
                    ])
                }

                return
            }

            self.analyse(image: image, id: id, captured: false)
        }
    }

    /// The analysis itself, for a photo from anywhere.
    ///
    /// Must be called off the main thread — Vision runs two detection passes here.
    /// `captured` rides along so the web layer can tell a photo it just took from
    /// one the user picked, without a second message type.
    func analyse(image: UIImage, id: String, captured: Bool) {
        guard let cgImage = image.cgImage else {
            print("❌ analyse FAILED \(id) — no bitmap")
            DispatchQueue.main.async {
                self.sendToWeb([
                    "type": "onGalleryPhotoAnalysis",
                    "payload": ["assetId": id, "captured": captured, "error": "unavailable"]
                ])
            }
            return
        }

        let orientation = Self.cgOrientation(image.imageOrientation)

        // The same face-to-body tie as the scan, so a tapped or captured photo is
        // judged on the body under its own face.
        let face = self.largestFace(in: cgImage, orientation: orientation)
        let body = self.bodyCheck(in: cgImage, orientation: orientation, face: face?.boundingBox)

        // Front / Side classification
        let type = self.classifyPhotoType(in: image, body: body)

        // A captured photo is analysed once, here, and stored so the tap that
        // follows takes the same path as a scanned one.
        if captured { ScanAnalysisStore.store(ScanAnalysis(type: type, body: body), id: id) }

        sendAnalysis(id: id, captured: captured, body: body, type: type, cached: false)
    }

    /// The one place `onGalleryPhotoAnalysis` is built, so a cached verdict and a
    /// freshly computed one cannot describe themselves differently.
    func sendAnalysis(id: String, captured: Bool, body: BodyCheck, type: PhotoType, cached: Bool) {
        // Not optional metadata: the web layer rejects any photo `isFullBody`
        // reports false for, whatever `type` says. The same head-to-toe rule as the
        // scan gate, so a photo the scan let through is not refused on tap.
        let isFullBody = body.isHeadToToe

        print("""
        📸 PHOTO ANALYSIS\(captured ? " (captured)" : "")\(cached ? " (cached)" : "")
           ID: \(id)
           TYPE: \(type.rawValue)
           Full Body: \(isFullBody)
           Joints: \(body.lowerJoints)/4, ankles \(body.ankles), head \(body.headSeen), span \(String(format: "%.2f", body.span)), feet room \(String(format: "%.3f", body.footRoom)), people \(body.people)
           Shoulders: \(body.shoulderSpread.map { String(format: "%.2f", $0) } ?? "not measured"), hips \(body.hipSpread.map { String(format: "%.2f", $0) } ?? "–") — type by \(body.bodyFacing == nil ? "head turn" : "shoulders")
        """)

        let analysis: [String: Any] = [
            "assetId": id,
            "captured": captured,
            "lowerBodyJoints": body.lowerJoints,
            "isFullBody": isFullBody,
            // The web refuses the photo on this — the only way a photo from the flow's
            // own camera, which never passes the scan gate, is held to the same rule.
            "otherPeople": body.hasOthers,
            "type": type.rawValue
        ]

        DispatchQueue.main.async {
            self.sendToWeb([
                "type": "onGalleryPhotoAnalysis",
                "payload": analysis
            ])
        }
    }

    /// Takes one photo the user shot in the flow, then analyses it.
    ///
    /// The bytes are held in memory only — see `CaptureStore`. The reply is the
    /// ordinary analysis message, so the web layer needs no new handler: it stores
    /// the verdict, rejects the photo if it is unusable, and otherwise shows it in
    /// the grid served straight back out of the store.
    func storeCapture(id: String, dataURI: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            func fail(_ reason: String) {
                print("❌ capture FAILED \(id) — \(reason)")
                DispatchQueue.main.async {
                    self.sendToWeb([
                        "type": "onGalleryPhotoAnalysis",
                        "payload": ["assetId": id, "captured": true, "error": reason]
                    ])
                }
            }

            guard !id.isEmpty, let image = Self.image(fromDataURI: dataURI) else {
                fail("unreadable")
                return
            }

            // The bytes as sent, not a re-encode: the web side already captured at
            // upload size and quality, so anything else here loses a generation.
            guard let comma = dataURI.firstIndex(of: ","),
                  let data = Data(base64Encoded: String(dataURI[dataURI.index(after: comma)...])) else {
                fail("unreadable")
                return
            }

            guard CaptureStore.store(data, id: id) else {
                fail("store-full")
                return
            }

            print("📷 stored capture \(id) — \(data.count / 1024)KB, \(CaptureStore.count)/\(CaptureStore.limit) held")
            self.analyse(image: image, id: id, captured: true)
        }
    }


    /// Which way the person is facing.
    ///
    /// `unknown` is not a failure — Vision finds no face in a back view. Read it
    /// alongside `isFullBody` rather than expecting a fourth case.
    /// What a photo can be used as.
    ///
    /// A selfie is recognised by shape rather than by which lens took it: a large
    /// face with no lower body in frame. EXIF says which camera was used, but that
    /// metadata is stripped by every messaging app, so a selfie a friend sent would
    /// not be recognised — and a back-camera head-and-shoulders portrait serves the
    /// same purpose anyway.
    ///
    /// Full body is checked first, so a head-to-toe shot is always classified by
    /// yaw whichever camera took it.
    func classifyPhotoType(in image: UIImage, body: BodyCheck) -> PhotoType {
        guard let cgImage = image.cgImage else { return .unknown }

        let faceRequest = VNDetectFaceRectanglesRequest()

        // The image's real orientation, the same as every other Vision call here.
        // At `.up` a rotated portrait is analysed sideways and no face is found,
        // which reports `unknown` — and the web layer rejects that, so a photo the
        // scan had matched un-selected itself the moment the user tapped it.
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: Self.cgOrientation(image.imageOrientation),
            options: [:]
        )
        try? handler.perform([faceRequest])

        guard let face = faceRequest.results?.first else { return .unknown }

        let ratio = Self.faceRatio(boxWidth: face.boundingBox.width, in: cgImage)

        // Yaw is read once and logged on both branches. A selfie is accepted at any
        // angle — it is a face reference, not a pose — but without the number in
        // the log there is no way to tell a head-on selfie from a sharply turned
        // one, which is the difference between a good reference and a poor one.
        let yaw = face.yaw?.doubleValue

        let turn = yaw.map { String(format: "%.3f", $0) } ?? "n/a"
        print("🔬 FACE \(String(format: "%.2f", ratio)) of frame, yaw \(turn), joints \(body.lowerJoints)/4, head to toe \(body.isHeadToToe)")

        // The decision itself lives in one place, shared with the scan.
        return Self.photoType(faceRatio: ratio, yaw: yaw, body: body)
    }

    /// Base64 fallback for one photo the custom scheme could not load.
    ///
    /// One per request, not a batch: a cap silently truncated large result sets.
    /// A failure replies with an error rather than staying silent, because the
    /// web layer drops the photo entirely on that reply.
    ///
    /// Serial: the web asks per tile, so a grid of sixty fires sixty blocking
    /// PhotoKit requests at once, and analysis — which has a 15s deadline on the
    /// web side — ends up queued behind them.
    static let thumbnailQueue = DispatchQueue(label: "co.getswan.gallery.thumbnails")

    func sendThumbnail(for id: String) {
        guard !id.isEmpty else { return }

        Self.thumbnailQueue.async { [weak self] in
            // iCloud allowed: a grid tile is ~20KB and only ever displayed.
            // The *scan* never downloads — walking a library over someone's
            // cellular data would be ruinous — but a tile the user is looking at,
            // and the handful of photos they finally pick, are worth fetching.
            guard let data = Thumbnail.jpeg(for: id,
                                            maxPixel: Thumbnail.gridPixels,
                                            quality: Thumbnail.gridQuality,
                                            allowNetwork: true) else {
                print("  \u{274c} thumbnail FAILED  \(id)")
                // Reported, not dropped: the web layer asked because the <img>
                // already failed, so silence leaves a broken tile with no second
                // signal. It removes the photo entirely on this reply.
                DispatchQueue.main.async {
                    self?.sendToWeb(["type": "onGalleryThumbnails",
                                     "payload": ["thumbs": [["id": id, "error": "unavailable"]]]])
                }
                return
            }

            DispatchQueue.main.async {
                // Sent in the same `thumbs` array shape as before, so the web side has
                // one code path whether one arrives or many.
                self?.sendToWeb(["type": "onGalleryThumbnails",
                                 "payload": ["thumbs": [["id": id,
                                                         "dataURI": "data:image/jpeg;base64," + data.base64EncodedString()]]]])
            }
        }
    }

    /// Drops everything held for one run of the flow. Called on GALLERY_RESET and
    /// at the top of every scan, so a second scan inherits nothing from the first.
    func resetScanState() {
        scanGeneration += 1
        referencePrint = nil
        referencePrintMirrored = nil
        referenceScales = []
        lastReferenceWidth = 0
        isLimitedAccess = false
        debugCropsSaved = 0
        // Tied to the reference face being cleared above: every verdict in here was
        // reached against that face, so keeping them across a new selfie would serve
        // answers about a different person's match run.
        ScanAnalysisStore.removeAll()
        clearDebugImages()
    }

    /// Removes the PNGs from the previous run. They are written to Documents and
    /// nothing else ever deletes them, so without this the folder accumulates
    /// crops from every scan the app has ever done and it stops being obvious
    /// which run produced which file.
    func clearDebugImages() {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return }

        for name in names where name.hasPrefix("swan-debug-") {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(name))
        }
    }
}

// MARK: - Custom scheme handler

/// Serves `swan-photo://thumb?id=<percent-encoded localIdentifier>`.
///
/// A localIdentifier contains slashes ("ABC.../L0/001"), so it travels as a query
/// parameter rather than a path component.
final class PhotoSchemeHandler: NSObject, WKURLSchemeHandler {

    /// WebKit calls `stop` when a load is cancelled — an <img> removed from the DOM,
    /// a navigation away — and messaging a stopped task raises an exception that
    /// takes the app down. Tracking live tasks is not optional here.
    private var live = Set<ObjectIdentifier>()
    private let lock = NSLock()

    private func isLive(_ task: WKURLSchemeTask) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return live.contains(ObjectIdentifier(task))
    }

    private func retire(_ task: WKURLSchemeTask) {
        lock.lock(); defer { lock.unlock() }
        live.remove(ObjectIdentifier(task))
    }

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        lock.lock(); live.insert(ObjectIdentifier(task)); lock.unlock()

        guard let url = task.request.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let id = components.queryItems?.first(where: { $0.name == "id" })?.value else {
            finish(task, with: nil)
            return
        }

        // ?size=full is the large display render; anything else is a grid tile.
        let wantsFull = components.queryItems?
            .first(where: { $0.name == "size" })?.value == "full"

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let startedAt = Date()
            // Same split as the base64 fallback: a grid tile may be fetched from
            // iCloud, a full-size render may not. This is the primary path, so
            // getting it right here is what stops the fallback being needed at all.
            let data = Thumbnail.jpeg(
                for: id,
                maxPixel: wantsFull ? Thumbnail.fullPixels : Thumbnail.gridPixels,
                quality: wantsFull ? Thumbnail.fullQuality : Thumbnail.gridQuality,
                allowNetwork: !wantsFull
            )
            let ms = Int(Date().timeIntervalSince(startedAt) * 1000)

            if wantsFull {
                // Only logged for full renders — grid tiles arrive by the dozen and
                // would drown everything else.
                print(data == nil
                      ? "  \u{274c} serve FAILED  \(id)  (\(ms)ms)"
                      : "  \u{2705} served \(data!.count / 1024)KB  \(id)  (\(ms)ms)")
            }

            DispatchQueue.main.async { self?.finish(task, with: data, url: url) }
        }
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {
        retire(task)
    }

    private func finish(_ task: WKURLSchemeTask, with data: Data?, url: URL? = nil) {
        guard isLive(task) else { return }
        retire(task)

        guard let data = data, let url = url ?? task.request.url else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        // Access-Control-Allow-Origin because the page is https and this response
        // is a different origin; without it the load is rejected before the bytes
        // are ever looked at.
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "image/jpeg",
                           "Content-Length": "\(data.count)",
                           "Access-Control-Allow-Origin": "*",
                           "Cache-Control": "max-age=300"]
        )!

        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }
}

// MARK: - Debug image dump

extension ViewController {

    /// Saves a PNG into Documents. Pull the folder off the device with
    /// Xcode > Window > Devices and Simulators > select app > Download Container,
    /// then look inside AppData/Documents.
    func saveDebugImage(_ image: UIImage, name: String) {
        guard debugDumpCrops,
              let data = image.pngData(),
              let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return }
        let url = dir.appendingPathComponent("swan-debug-\(name).png")
        try? data.write(to: url)
    }

    /// EXIF orientation as a readable name. If photos arrive as anything other than
    /// `up`, face boxes are being computed in a rotated space while the crop runs
    /// on unrotated pixels — which silently crops the wrong region.
    static func orientationName(_ o: UIImage.Orientation) -> String {
        switch o {
        case .up: return "up"
        case .down: return "down"
        case .left: return "left"
        case .right: return "right"
        case .upMirrored: return "upMirror"
        case .downMirrored: return "downMirror"
        case .leftMirrored: return "leftMirror"
        case .rightMirrored: return "rightMirror"
        @unknown default: return "?"
        }
    }
}

// MARK: - Image helpers

extension ViewController {

    /// UIGraphicsImageRenderer rather than the older stack-based API: this runs on
    /// the scan's background queue, where per-thread context state is easy to get
    /// wrong.
    func resized(_ image: UIImage, to size: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// A front-camera selfie is not necessarily oriented the way the user appears
    /// in someone else's photo, and the descriptor is not mirror-invariant — so the
    /// reference is kept both ways and the nearer one wins.
    func mirrored(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.translateBy(x: size.width, y: 0)
        ctx.scaleBy(x: -1, y: 1)
        image.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - Vision helpers

extension ViewController {

    /// Decodes a `data:image/jpeg;base64,...` string.
    static func image(fromDataURI uri: String) -> UIImage? {
        guard let comma = uri.firstIndex(of: ","),
              let data = Data(base64Encoded: String(uri[uri.index(after: comma)...]))
        else { return nil }
        return UIImage(data: data).map(upright)
    }

    /// The photo redrawn so its pixels are the right way up.
    ///
    /// Vision is told the orientation and returns boxes for the upright picture, but
    /// `crop` cuts the raw pixels — so for a photo stored sideways the face was cut
    /// from the wrong region. Redrawn once here, everything after works on `.up`.
    static func upright(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    /// Render size for every photo in the scan. `minFacePixels` is expressed in
    /// these pixels, so the two must be changed together.
    static let loadPixels: CGFloat = 2048

    /// A face narrower than this, in pixels of the scan's render, is re-cropped from
    /// a larger render before it is printed. It is `faceNormalSize`: below it the crop
    /// is upscaled to 224 and reads as soft, which the descriptor scores as a
    /// different face; at or above it, extra pixels are thrown away by the resize.
    /// So in practice this is full-length photos, never selfies.
    static let fullResFaceBelow: CGFloat = 224

    /// The size of that second render. Capped rather than the whole original: a 48MP
    /// photo decoded in full is about 190MB, and this happens in the middle of a scan.
    static let fullResPixels: CGFloat = 4096

    /// Loads a photo big enough to crop a usable face from, at `loadPixels`.
    ///
    /// `.highQualityFormat` and `.exact` matter: `.fastFormat`/`.fast` hand back
    /// whatever is cached, often a tiny thumbnail, and the descriptor then reads
    /// blur rather than a face. Network stays off — this flow never downloads
    /// from iCloud.
    ///
    /// When the full photo is only in iCloud, the first request answers nil. The
    /// phone usually still holds a smaller copy — "Optimise iPhone Storage" keeps a
    /// screen-sized one — and a second, opportunistic request hands that back. One
    /// tester's library was a quarter iCloud-only, and every one of those photos was
    /// skipped; the local copy is plenty for a selfie's face. A copy under
    /// `minLocalCopyPixels` is refused, so a real thumbnail still counts as `noImage`,
    /// and `lastLoadNote` says which of these happened.
    func loadPhoto(asset: PHAsset, pixels: CGFloat = ViewController.loadPixels) -> UIImage? {
        lastLoadLocalCopy = false
        lastLoadThumbnail = nil
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = false
        options.isSynchronous = true

        // 2048, not 1024: a full-body photo has a small face by construction,
        // and more source pixels buy more accuracy than any threshold change.
        let target = CGSize(width: pixels, height: pixels)
        var result: UIImage?
        var inCloud = false
        PHImageManager.default().requestImage(for: asset, targetSize: target, contentMode: .aspectFit, options: options) { image, info in
            result = image
            inCloud = info?[PHImageResultIsInCloudKey] as? Bool ?? false
        }

        if result == nil {
            lastLoadNote = inCloud ? "in iCloud, no copy on the phone" : "not flagged as iCloud"
        }
        if result == nil && inCloud {
            // A synchronous request treats every delivery mode as high quality, so
            // the phone's copy has to be asked for asynchronously, in `.opportunistic`
            // — the mode the Photos app uses to show what it has while the full
            // image downloads. It may answer more than once, each copy better than
            // the last; the largest is kept, and the wait ends on the final answer
            // or after `localCopyWait`.
            let local = PHImageRequestOptions()
            local.deliveryMode = .opportunistic
            local.resizeMode = .exact
            local.isNetworkAccessAllowed = false
            local.isSynchronous = false
            let done = DispatchSemaphore(value: 0)
            var best: UIImage?
            PHImageManager.default().requestImage(for: asset, targetSize: target, contentMode: .aspectFit, options: local) { image, info in
                if let image, let cg = image.cgImage,
                   max(cg.width, cg.height) > (best?.cgImage.map { max($0.width, $0.height) } ?? 0) {
                    best = image
                }
                let degraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                let cancelled = info?[PHImageCancelledKey] as? Bool ?? false
                let failed = info?[PHImageErrorKey] != nil
                // The degraded answer is followed by another; anything else is final.
                if !degraded || cancelled || failed { done.signal() }
            }
            _ = done.wait(timeout: .now() + Self.localCopyWait)

            if let best, let cg = best.cgImage {
                let longest = max(cg.width, cg.height)
                if longest >= Self.minLocalCopyPixels {
                    result = best
                    lastLoadLocalCopy = true
                } else {
                    lastLoadNote = "in iCloud, phone copy only \(longest)px — under \(Self.minLocalCopyPixels)"
                    lastLoadThumbnail = best
                }
            }
        }

        lastLoadRotated = result.map { $0.imageOrientation != .up } ?? false
        return result.map(Self.upright)
    }

    /// Downloads a reduced copy of a photo whose full version is in iCloud.
    ///
    /// Only the iCloud pass calls this, for the few photos its thumbnail filter
    /// picked. Asynchronous so the wait can be bounded: a synchronous request with
    /// network on blocks for as long as iCloud takes.
    func loadFromCloud(asset: PHAsset, pixels: CGFloat, timeout: DispatchTimeInterval) -> UIImage? {
        lastLoadLocalCopy = false
        lastLoadThumbnail = nil
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        let done = DispatchSemaphore(value: 0)
        var result: UIImage?
        let request = PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: pixels, height: pixels),
                                                            contentMode: .aspectFit, options: options) { image, info in
            // High quality delivers once, when it is final.
            if info?[PHImageResultIsDegradedKey] as? Bool != true {
                result = image
                done.signal()
            }
        }
        if done.wait(timeout: .now() + timeout) == .timedOut {
            PHImageManager.default().cancelImageRequest(request)
            lastLoadNote = "iCloud download timed out"
            return nil
        }
        if result == nil { lastLoadNote = "iCloud download failed" }
        lastLoadRotated = result.map { $0.imageOrientation != .up } ?? false
        return result.map(Self.upright)
    }

    /// Whether a thumbnail shows one face filling the frame — the shape of a selfie,
    /// readable even at 120px. The same two rules the real selfie gate applies,
    /// `bystanderRatio` and `selfieFaceRatio`, so the filter cannot pick a photo the
    /// gate would then refuse for its shape.
    func isSelfieShaped(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        let request = VNDetectFaceRectanglesRequest()
        try? VNImageRequestHandler(cgImage: cgImage, orientation: Self.cgOrientation(image.imageOrientation), options: [:])
            .perform([request])
        guard let faces = request.results, !faces.isEmpty else { return false }
        let mainWidth = faces.map(\.boundingBox.width).max() ?? 0
        let company = faces.filter { $0.boundingBox.width >= mainWidth * Self.bystanderRatio }
        return company.count == 1 && Self.faceRatio(boxWidth: mainWidth, in: cgImage) >= Self.selfieFaceRatio
    }

    /// The largest face Vision finds, or nil.
    func largestFace(in cgImage: CGImage, orientation: CGImagePropertyOrientation) -> VNFaceObservation? {
        let request = VNDetectFaceRectanglesRequest()
        try? VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:]).perform([request])
        return request.results?.max {
            $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height
        }
    }

    /// Largest face in the image, cropped with padding.
    func croppedFace(from image: UIImage, padding: CGFloat = ViewController.facePadding) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: Self.cgOrientation(image.imageOrientation),
            options: [:]
        )
        try? handler.perform([request])

        guard let face = request.results?.max(by: {
            $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height
        }), let cropped = crop(cgImage, to: face.boundingBox, padding: padding) else { return nil }

        return UIImage(cgImage: cropped)
    }

    /// Why a photo did or did not produce a score.
    ///
    /// An enum rather than a tuple of optionals because these outcomes are mutually
    /// exclusive and each needs its own tally — collapsing them into "no result"
    /// is what makes a disappointing scan impossible to explain.
    enum PhotoOutcome {
        case noFace
        case group(faceCount: Int)
        case faceTooSmall(pixels: Int)
        case otherPeople(body: BodyCheck)
        case notFullBody(body: BodyCheck)
        /// `profile`: a side with the face turned away, matched against
        /// `profileMatchThreshold` instead of `matchThreshold`.
        case scored(distances: [Float], facePixels: Int, body: BodyCheck, type: PhotoType, profile: Bool)
    }

    /// Applies the eligibility gates, then compares the surviving face against the
    /// reference.
    ///
    /// The gates run *before* any feature print is computed, so a rejected photo
    /// costs one face-detection pass and nothing more.
    func matchPerson(in image: UIImage, asset: PHAsset) -> PhotoOutcome {
        lastFaceMetrics = nil
        lastCropFullRes = false
        // Cleared first, not after the body check: a photo that leaves early — no
        // face, a group — must not carry the previous photo's retry into the log.
        lastBodyRetry = nil
        guard referencePrint != nil, let cgImage = image.cgImage else { return .noFace }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: Self.cgOrientation(image.imageOrientation),
            options: [:]
        )
        try? handler.perform([request])

        guard let allFaces = request.results, !allFaces.isEmpty else { return .noFace }

        // Faces too small beside the largest are bystanders, not company — see
        // `bystanderRatio`. They are also dropped from the matching below, so a tiny
        // face in the background neither rejects the photo nor gets a turn at
        // looking like the shopper.
        let mainFaceWidth = allFaces.map(\.boundingBox.width).max() ?? 0
        let faces = allFaces.filter { $0.boundingBox.width >= mainFaceWidth * Self.bystanderRatio }

        if Self.requireSingleFace && faces.count > 1 {
            return .group(faceCount: faces.count)
        }

        // Vision boxes are normalised, so this is the face's width in real pixels of
        // the render we loaded.
        let widest = faces.map { $0.boundingBox.width * CGFloat(cgImage.width) }.max() ?? 0

        // Recorded for `ScanEval`, not used by any gate yet: which of these separate
        // good matches from bad is what the evaluation is there to find out.
        if Self.evalMode, let face = faces.first {
            lastFaceMetrics = FaceMetrics(face, handler: handler)
        }

        // A larger render of the same photo, loaded at most once and only if asked
        // for: by the size gate below, or by the re-crop further down. Network off —
        // the scan never downloads, so with no larger copy on the phone this is nil.
        var largerLoaded = false
        var largerCache: CGImage?
        func largerRender() -> CGImage? {
            if !largerLoaded {
                largerLoaded = true
                largerCache = loadPhoto(asset: asset, pixels: Self.fullResPixels)?.cgImage
                    .flatMap { $0.width > cgImage.width ? $0 : nil }
            }
            return largerCache
        }

        // Too small here is not too small everywhere. Only when the original is big
        // enough to clear the floor is the larger render worth loading — so a photo
        // that is small in every copy costs nothing extra.
        let widestRatio = faces.map(\.boundingBox.width).max() ?? 0
        if widest < Self.minFacePixels {
            guard widestRatio * CGFloat(asset.pixelWidth) >= Self.minFacePixels,
                  let larger = largerRender(),
                  widestRatio * CGFloat(larger.width) >= Self.minFacePixels
            else { return .faceTooSmall(pixels: Int(widest)) }
        }

        // Ordered after the face gates deliberately — pose detection is the most
        // expensive request here, and this way it only runs on photos that already
        // have one usable face.
        var body = bodyCheck(in: cgImage, orientation: Self.cgOrientation(image.imageOrientation),
                             face: faces.first?.boundingBox)

        // Distances of every face in `source` to the reference nearest its size.
        // Nil when nothing could be printed. Defined here so the full-body gate
        // below can ask "is this the shopper?" before spending a larger render.
        func score(from source: CGImage) -> (distances: [Float], faceWidth: CGFloat, referenceWidth: CGFloat)? {
            let faceWidth = faces.map { $0.boundingBox.width * CGFloat(source.width) }.max() ?? widest

            // Compare like with like: a soft 120px face is measured against a reference
            // degraded to 120px, not against the sharp original. Sized from the crop
            // actually printed, so a re-cropped face meets a sharper reference too.
            guard let reference = nearestReference(for: faceWidth) else { return nil }

            var distances: [Float] = []
            for face in faces {
                guard let cropped = crop(source, to: face.boundingBox),
                      let candidate = facePrint(fromFace: cropped) else { continue }

                // Nearer of the reference and its mirror — see referencePrintMirrored.
                var distance: Float = 0
                guard (try? reference.print.computeDistance(&distance, to: candidate)) != nil else { continue }
                if let mirrored = reference.mirrored {
                    var mirroredDistance: Float = 0
                    if (try? mirrored.computeDistance(&mirroredDistance, to: candidate)) != nil {
                        distance = min(distance, mirroredDistance)
                    }
                }
                distances.append(distance)

                // Distance is in the filename, so the closest crops can be found and
                // eyeballed without cross-referencing the console.
                if debugCropsSaved < Self.debugCropLimit {
                    debugCropsSaved += 1
                    saveDebugImage(UIImage(cgImage: cropped),
                                   name: String(format: "%02d-d%.3f", debugCropsSaved, distance))
                }
            }
            guard !distances.isEmpty else { return nil }
            return (distances, faceWidth, reference.sourceWidth)
        }

        // A selfie has no lower body to find, so the full-body gate would reject
        // every one and none would reach the picker. Recognised by the same shape
        // the classifier uses — a face filling enough of the frame — from numbers
        // already in hand, so this costs nothing.
        // Only the shopper in the photo. The face gate cannot see someone with their
        // back to the camera; the person detector can, and anyone it finds counts.
        if body.hasOthers {
            return .otherPeople(body: body)
        }

        let faceRatio = Self.faceRatio(boxWidth: faces.map(\.boundingBox.width).max() ?? 0, in: cgImage)
        let isSelfie = faceRatio >= Self.selfieFaceRatio
        if Self.requireFullBody && !isSelfie && !body.isHeadToToe {
            // Legs seen but not enough of them: the feet may just be small or dark
            // at the scan's size. One more look at the larger render — but only when
            // the face already matches, so the hundred strangers who fail this gate
            // on a big library cost nothing extra. A tester's own photo failed here
            // with a knee found and no ankle, at 1536px from a 5712px original.
            guard body.headSeen, body.lowerJoints >= 1,
                  let quick = score(from: cgImage), (quick.distances.min() ?? 1) < Self.matchThreshold,
                  let larger = largerRender()
            else { return .notFullBody(body: body) }
            let again = bodyCheck(in: larger, orientation: .up, face: faces.first?.boundingBox)
            let f = { (v: CGFloat) in String(format: "%.2f", v) }
            lastBodyRetry = ("re-checked at \(larger.width)x\(larger.height) after a face match (d \(String(format: "%.3f", quick.distances.min() ?? 1))): ankles \(body.ankles)→\(again.ankles), span \(f(body.span))→\(f(again.span)), feet room \(f(body.footRoom))→\(f(again.footRoom))",
                             again.isHeadToToe)
            if again.hasOthers { return .otherPeople(body: again) }
            guard again.isHeadToToe else { return .notFullBody(body: body) }
            body = again
        }

        // Free: the ratio and the body check are already above, and `yaw` rides on
        // the observations this function detected for the match. `classifyPhotoType`
        // gets the same three numbers by running a second face pass over the same
        // photo — here there is nothing left to compute.
        let yaw = faces.first?.yaw?.doubleValue
        let type = Self.photoType(faceRatio: faceRatio, yaw: yaw, body: body)
        // The shoulders must have said side — a side by head turn alone does not count.
        let profile = type == .side && body.bodyFacing == .side && abs(yaw ?? 0) > Self.profileYaw

        // A small face is re-cropped from the larger render. Only photos that passed
        // every gate get here, so it is a handful per scan, and one rescued by the
        // size gate reuses the render already loaded. The face box is normalised, so
        // it fits the larger render unchanged.
        var source = cgImage
        if widest < Self.fullResFaceBelow, let larger = largerRender() {
            source = larger
            lastCropFullRes = true
        }
        guard let scored = score(from: source) else { return .noFace }
        lastReferenceWidth = Int(scored.referenceWidth)
        return .scored(distances: scored.distances, facePixels: Int(scored.faceWidth), body: body, type: type, profile: profile)
    }

    /// How far outside the face box a body's head points may sit and still make it
    /// that face's body, as a fraction of the box. Generous: the ears sit on the box
    /// edge, and a turned head moves the nose.
    static let bodyFaceMargin: CGFloat = 0.5

    /// What pose detection finds of the body: the head, the knees and ankles, and
    /// how much of the frame they span.
    ///
    /// With `face`, only the body whose head sits on that face is read — a photo with
    /// someone else in it must not be judged on their legs — and `.none` when no body
    /// does. Without it, the first body Vision returns.
    func bodyCheck(in cgImage: CGImage, orientation: CGImagePropertyOrientation,
                   face: CGRect? = nil) -> BodyCheck {
        let request = VNDetectHumanBodyPoseRequest()
        // Counted in the same pass, so the photo is not decoded twice. Whole bodies,
        // not just upper halves, so someone standing beside the shopper is found.
        let peopleRequest = VNDetectHumanRectanglesRequest()
        peopleRequest.upperBodyOnly = false
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        try? handler.perform([request, peopleRequest])

        // Bodies well under the largest are in the distance — see `bystanderRatio`.
        // Heights, not areas: a person side-on is narrow but no shorter.
        let tallest = peopleRequest.results?.map(\.boundingBox.height).max() ?? 0
        let people = peopleRequest.results?.filter { $0.boundingBox.height >= tallest * Self.bystanderRatio }.count ?? 0
        let nobody = BodyCheck(lowerJoints: 0, ankles: 0, headSeen: false, span: 0, footRoom: 0, people: people,
                               shoulderSpread: nil, hipSpread: nil)
        guard let bodies = request.results, !bodies.isEmpty else { return nobody }

        func seen(_ joints: [VNHumanBodyPoseObservation.JointName],
                  of body: VNHumanBodyPoseObservation) -> [VNRecognizedPoint] {
            joints.compactMap { try? body.recognizedPoint($0) }
                .filter { $0.confidence >= Self.bodyJointConfidence }
        }
        let headJoints: [VNHumanBodyPoseObservation.JointName] = [.nose, .leftEye, .rightEye, .leftEar, .rightEar]

        // Face boxes and joints share Vision's normalised space, so the test is direct.
        var observation = bodies[0]
        if let face {
            let zone = face.insetBy(dx: -face.width * Self.bodyFaceMargin,
                                    dy: -face.height * Self.bodyFaceMargin)
            let onFace = { (body: VNHumanBodyPoseObservation) in
                seen(headJoints, of: body).filter { zone.contains($0.location) }.count
            }
            guard let best = bodies.max(by: { onFace($0) < onFace($1) }), onFace(best) > 0
            else { return nobody }
            observation = best
        }

        let knees = seen([.leftKnee, .rightKnee], of: observation)
        let ankles = seen([.leftAnkle, .rightAnkle], of: observation)
        let head = seen(headJoints, of: observation)

        // Vision's y runs bottom to top, so the span is the highest head point less
        // the lowest ankle — and zero when either end is missing.
        var span: CGFloat = 0
        if let top = head.map(\.location.y).max(), let bottom = ankles.map(\.location.y).min() {
            span = max(0, top - bottom)
        }

        // The body's own turn: shoulders and hips across the photo, against the torso's
        // length. In pixels, because Vision normalises x and y to different sides.
        let sideways: Set<CGImagePropertyOrientation> = [.left, .right, .leftMirrored, .rightMirrored]
        let w = CGFloat(sideways.contains(orientation) ? cgImage.height : cgImage.width)
        let h = CGFloat(sideways.contains(orientation) ? cgImage.width : cgImage.height)
        func pixel(_ joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
            guard let p = try? observation.recognizedPoint(joint),
                  p.confidence >= Self.spreadJointConfidence else { return nil }
            return CGPoint(x: p.location.x * w, y: p.location.y * h)
        }
        let torso: CGFloat? = {
            guard let neck = pixel(.neck), let root = pixel(.root) else { return nil }
            let length = hypot(neck.x - root.x, neck.y - root.y)
            return length > 1 ? length : nil
        }()
        func spread(_ a: VNHumanBodyPoseObservation.JointName,
                    _ b: VNHumanBodyPoseObservation.JointName) -> CGFloat? {
            guard let torso, let pa = pixel(a), let pb = pixel(b) else { return nil }
            return abs(pa.x - pb.x) / torso
        }

        return BodyCheck(lowerJoints: knees.count + ankles.count,
                         ankles: ankles.count,
                         headSeen: !head.isEmpty,
                         span: span,
                         footRoom: ankles.map(\.location.y).min() ?? 0,
                         people: people,
                         shoulderSpread: spread(.leftShoulder, .rightShoulder),
                         hipSpread: spread(.leftHip, .rightHip))
    }

    /// Face widths the reference is pre-degraded to, in pixels of the loaded render.
    /// Chosen to bracket what the gates actually let through: the floor is
    /// `minFacePixels`, the top is a close-up portrait.
    static let referenceScaleWidths: [CGFloat] = [120, 160, 210, 280, 380]

    /// Renders the reference face down to each ladder width and back up, so it
    /// carries the same loss a candidate of that size does.
    func buildReferenceScales(from faceCrop: UIImage) {
        let flipped = mirrored(faceCrop)

        referenceScales = Self.referenceScaleWidths.compactMap { width -> ScaledReference? in
            let size = CGSize(width: width, height: width)

            guard let degraded = resized(faceCrop, to: size),
                  let cg = degraded.cgImage,
                  let print0 = facePrint(fromFace: cg) else { return nil }

            let mirroredPrint = flipped
                .flatMap { resized($0, to: size) }
                .flatMap { $0.cgImage }
                .flatMap { facePrint(fromFace: $0) }

            return ScaledReference(sourceWidth: width, print: print0, mirrored: mirroredPrint)
        }
    }

    /// The reference whose resolution is closest to this candidate's.
    func nearestReference(for faceWidth: CGFloat) -> ScaledReference? {
        referenceScales.min {
            abs($0.sourceWidth - faceWidth) < abs($1.sourceWidth - faceWidth)
        }
    }

    /// Every face crop is squared off to this before printing.
    ///
    /// Unnormalised, the same face at half size scored 0.595 against ~1.05 for a
    /// different person — most of the range was going on size rather than identity.
    static let faceNormalSize = CGSize(width: 224, height: 224)

    /// Margin around the face box before it is printed, as a fraction of the box.
    ///
    /// Was 0.25. FeaturePrint encodes background as readily as the face, and in a
    /// full-length photo most of that margin is background — so a stranger standing
    /// somewhere like where you stand scores closer than they should. Too little cuts
    /// off the jaw and hairline. The reference and every candidate use this one
    /// value: cropped differently, the distance would measure the crop.
    static let facePadding: CGFloat = 0.1

    /// Which FeaturePrint model every print uses. Pinned rather than left to Vision's
    /// default, so an OS or SDK update cannot quietly swap the model between the
    /// reference and the candidates — prints from different revisions cannot be
    /// compared, and every threshold here was measured on revision 2 (iOS 17+).
    static let featurePrintRevision = VNGenerateImageFeaturePrintRequestRevision2

    /// The only way a face should ever be printed. Both the reference and every
    /// candidate go through here, so they cannot drift apart.
    func facePrint(fromFace cgImage: CGImage) -> VNFeaturePrintObservation? {
        guard let normalised = resized(UIImage(cgImage: cgImage), to: Self.faceNormalSize)
        else { return nil }
        return featurePrint(from: normalised)
    }

    /// NOTE: this is a general *image similarity* descriptor, not a face-identity
    /// embedding — it partly encodes lighting, hair and background. Prefer
    /// `facePrint(fromFace:)` for faces; this is the raw call underneath it.
    func featurePrint(from image: UIImage) -> VNFeaturePrintObservation? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNGenerateImageFeaturePrintRequest()
        request.revision = Self.featurePrintRevision
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try? handler.perform([request])
        return request.results?.first
    }

    /// Vision boxes are normalised with a bottom-left origin; CGImage is top-left.
    /// `padding` is a fraction of the face box. More padding keeps hair and chin;
    /// it also drags in background, which this descriptor happily encodes — the
    /// self-test measures exactly what that trade costs.
    func crop(_ image: CGImage, to boundingBox: CGRect, padding: CGFloat = ViewController.facePadding) -> CGImage? {
        let w = CGFloat(image.width)
        let h = CGFloat(image.height)

        let rect = CGRect(x: boundingBox.origin.x * w,
                          y: (1 - boundingBox.origin.y - boundingBox.height) * h,
                          width: boundingBox.width * w,
                          height: boundingBox.height * h)

        let padded = rect.insetBy(dx: -rect.width * padding, dy: -rect.height * padding)
        let clamped = padded.intersection(CGRect(x: 0, y: 0, width: w, height: h))
        guard clamped.width > 1, clamped.height > 1 else { return nil }

        return image.cropping(to: clamped)
    }

    /// Vision needs the EXIF orientation — without it a portrait photo is analysed
    /// sideways and no face is found.
    static func cgOrientation(_ orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

// MARK: - Weak bridge proxy

/// Breaks the retain cycle described in `setupWebView`.
final class BridgeProxy: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?

    init(target: WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(controller, didReceive: message)
    }
}
