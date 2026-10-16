# Swan Native Samples

Sample native host apps for Swan's mobile web components.

## iOS: GalleryPick

`ViewController.swift` is a complete, working host for **GalleryPick**. GalleryPick builds the shopper's Muse from photos they already have: they take one selfie, then pick five photos from their own camera roll.

The component renders every screen inside a `WKWebView`. This file supplies what the web page cannot reach:

- **The photo library**, through PhotoKit, including each photo's original file.
- **On-device matching**, through Vision: face detection, face feature prints and body pose.
- **The bridge** between the page and your app (`swanBridge`).

It targets Swan mobile release **1.2.0**. The full guide is in the [GalleryPick docs](https://swan-user-photo-muse.apidocumentation.com/ios-components/ios-components/components#gallerypick).

### Requirements

- **iOS 17 or later**, and Xcode.
- **A physical iPhone.** The selfie needs a real camera, and the scan needs a real photo library.
- **Two Info.plist keys.** If either is missing, iOS stops the app on first access.
  - `NSPhotoLibraryUsageDescription`: the scan reads the photo library.
  - `NSCameraUsageDescription`: the selfie, *Take it now*, and the camera fallback.
- **Optional: the Sensitive Content Analysis capability**, to filter explicit photos out of the results. Without it, nothing is filtered.

### Setup

1. Create an iOS app in Xcode (Swift, Storyboard).
2. Replace the template's `ViewController.swift` with this file. The class name is the same, so the storyboard uses it as-is.
3. Add the two Info.plist keys above.
4. Fill in the settings at the top of the file (below).
5. Run it on an iPhone. When the page is ready, the console prints `✅ WEB_READY v1.2.0 — rendering GalleryPick`.

### Settings to fill in

| Setting | What to set |
| --- | --- |
| `userEmail` | The shopper's email. |
| `shopDomain` | Your customer shop domain, from the Swan dashboard. |
| `userGender` | `"male"` or `"female"` skips the gender screen. Any other value shows it, and the user's answer wins. |
| `userHeightCm` | Optional. A height inside 152–213 cm skips the height screen. Set it to `nil` to show it. |
| `sessionToken` | Required. A session token from `POST /auth/session` in the [Partner API](https://swan-user-photo-muse.apidocumentation.com/partner-api). Without it nothing uploads. |
| `monthsBack` | How far back the library search reaches: 1–36 months, 12 by default. *Load more photos* appears only when the user allows limited photo access. |
| `sdkURL` | Leave it on `https://swan-mobile-web-component.swan.so`, which always serves the latest release. To stay on one release, use its own address, for example `https://swan-mobile-web-component.swan.so/v1.2.0/index.html`. |

Get the session token from your own server. `POST /auth/session` needs your secret key, and a secret key must never ship inside an app.

### Before you ship

Keep these settings `false`. They ship that way.

- **`debugBridgeLogging`** prints presigned upload URLs, the user's email and links to their finished renders.
- **`debugDumpCrops`** writes face crops, which are biometric data, to the app's Documents folder.
- **`verboseLogging`** prints one line per photo scanned, which floods the console on a real library.
- **`evalMode`** is for measuring matching against a labelled album during testing.

### Versions

- **The root address always serves the latest release.** A published version never changes, so an app pinned to one keeps exactly that release.
- **The page reports its version** in the `WEB_READY` message, and this file prints it.
- **Release notes:** [Versions and Release Notes](https://swan-user-photo-muse.apidocumentation.com/ios-components/ios-components/components#gallerypick-versions).

### Documentation

- [GalleryPick guide](https://swan-user-photo-muse.apidocumentation.com/ios-components/ios-components/components#gallerypick): what the user sees, props, callbacks and the message contract.
- [Before You Ship](https://swan-user-photo-muse.apidocumentation.com/ios-components/ios-components/components#before-you-ship) and the walkthrough that follows it: why each part of this file exists.
- [Partner API](https://swan-user-photo-muse.apidocumentation.com/partner-api): session tokens and webhooks.
