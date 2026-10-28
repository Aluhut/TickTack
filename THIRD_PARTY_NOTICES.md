# Third-party notices

TickTack has no third-party package dependencies.

- The application source, documentation, original clock logo, and icon-rendering source are distributed under the repository's MIT license.
- SwiftUI, AppKit, Foundation, the system fonts, and system symbols are provided by Apple through macOS and its SDK. They remain subject to Apple's applicable licenses; the MIT license does not relicense Apple software or symbol designs.
- The app references SF Symbols through system APIs at runtime. No SF Symbols font, exported symbol artwork, or Apple branding is bundled in this repository. The TickTack app icon is an original drawing, not an SF Symbol.
- Excel ZIP support links to the zlib library supplied by macOS. No zlib source or separate library is bundled; see the [zlib license](https://zlib.net/zlib_license.html).
- PDF output uses Apple CoreGraphics and AppKit; PDFKit is used only by the tests.
- macOS is required to build and run TickTack. Apple's developer tools are not included.

See [Apple's SF Symbols information](https://developer.apple.com/sf-symbols/) and the license agreements accompanying your installed Apple SDK.
