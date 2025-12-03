![Passepartout logo](app-apple/Passepartout/App/Assets.xcassets/Logo.imageset/Logo@2x.png)

# [Passepartout][web-home]

[![Unit Tests](https://github.com/partout-io/passepartout/actions/workflows/test.yml/badge.svg?branch=)](https://github.com/partout-io/passepartout/actions/workflows/test.yml)
[![Release](https://github.com/partout-io/passepartout/actions/workflows/release.yml/badge.svg?branch=)](https://github.com/partout-io/passepartout/actions/workflows/release.yml)

[![Discuss on GitHub](https://img.shields.io/badge/discuss-GitHub-lightgray.svg)][about-github-discussions]
[![Join Reddit](https://img.shields.io/badge/support-Reddit-orange.svg)][about-reddit]
[![Join TestFlight](https://img.shields.io/badge/beta-Testflight-blue.svg)][about-testflight]

Passepartout is your go-to app for VPN and privacy.

Passepartout runs on [iPhone, iPad, Mac, and Apple TV][appstore].

## Features

[OpenVPN®][openvpn] and [WireGuard®][wireguard] client for Apple platforms, the OpenVPN stack also implements the [Tunnelblick XOR patch][openvpn-xor-patch].

Other features:

- On-demand rules
- Override DNS and HTTP proxy
- Custom routing
- Presets for multiple providers (virtually any)

Tailored for Apple platforms:

- Apple TV
- iCloud
- Shortcuts
- No background activities
- Wise on battery

## Installation

### Requirements

- iOS 16+ / macOS 13+ / tvOS 17+
- Xcode 16+
- SwiftPM 5.9
- Git (preinstalled with the Xcode Command Line Tools)

It's highly recommended that you use the Git and Ruby packages provided by [Homebrew][dep-brew].

### Testing

Download the app codebase locally:

```
$ git clone https://github.com/partout-io/passepartout
$ git submodule update --init submodules/partout
```

then find the Xcode project in `app-apple`. For everything to work properly, you must comply with all the capabilities and entitlements in the main app and the tunnel extension target. Therefore, you must update the `Config.xcconfig` file according to your developer account.

To test the app on your Mac or iOS/tvOS Simulator:

- Open `Passepartout.xcodeproj` in Xcode
- Run the `Passepartout` target

### Binaries

All the [GitHub Releases][github-releases] come with Mac .dmg images for arm64 and x86_64, though currently limited to free features only. It's recommended that you verify the GPG signatures with [my GPG key][gpg-key], which you can also fetch from the public keyservers:

```
gpg --recv-keys 28891B14B2635EA11F438034092E0218047A5650
```

### Homebrew

You can install the Mac app with [Homebrew Cask][homebrew-cask] too:

```shell
brew install passepartout
```

## License

Copyright (c) 2025 Davide De Rosa. All rights reserved.

This project is licensed under the [GPLv3][license-content].

### Contributing

By contributing to this project you are agreeing to the terms stated in the [Contributor License Agreement (CLA)][contrib-cla]. For more details please see [CONTRIBUTING][contrib-readme].

## Blog

[Follow the blog][web-blog] for insights, real-world challenges, and lessons learned from building and maintaining Passepartout.

## Credits

- [fastlane][credits-fastlane]
- [GenericJSON][credits-genericjson]
- [SwiftGen][credits-swiftgen]
- [SwiftLint][credits-swiftlint]
- [Tejas Mehta][credits-tmthecoder] for the implementation of the [OpenVPN XOR patch][credits-tmthecoder-xor]
- [vaygr][credits-vaygr] for adding Passepartout to [Homebrew Cask][credits-vaygr-cask]

The logo is taken from the awesome Circle Icons set by Nick Roach.

### OpenSSL

This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit. ([https://www.openssl.org/][dep-openssl])

### OpenVPN

© Copyright 2025 OpenVPN | OpenVPN is a registered trademark of OpenVPN, Inc.

### WireGuard

© Copyright 2015-2025 Jason A. Donenfeld. All Rights Reserved. "WireGuard" and the "WireGuard" logo are registered trademarks of Jason A. Donenfeld.

### Community

A _huge_ credit goes to:

- My tiny group of 3 private beta testers
- The 9000+ public testers using the beta on a daily basis
- The continued support and feedback from the [Passepartout community on Reddit][about-reddit]
- The overall patience of users affected by my bugs that actively collaborate in resolving them
- All those who contributed to the amazingly high rating on the App Store

## Translations

The app is mostly translated with [ChatGPT][credits-chatgpt], but these are the acknowledgments to the original translators:

- Chinese (Simplified): [OnlyThen](https://github.com/OnlyThen)
- Dutch: [Norbert de Vreede](https://github.com/paxpacis)
- English: [Davide De Rosa](https://github.com/keeshux) (author)
- French: [Julien Laniel](https://github.com/linkjul)
- German: Christian Lederer, Philipp Reynders, Theodor Tietze
- Greek: Konstantinos Koukoulakis
- Italian: [Davide De Rosa](https://github.com/keeshux) (author)
- Polish: Piotr Książek
- Portuguese: [Helder Santana](https://github.com/heldr)
- Russian: Alexander Korobynikov
- Spanish: [Davide De Rosa](https://github.com/keeshux) (author), Elena Vivó
- Swedish: [Henry Gross-Hellsen](https://github.com/cowpod)
- Ukranian: [Dmitry Chirkin](https://github.com/josser)

## Usage

You are encouraged to read carefully both the [disclaimer][web-disclaimer] and the [privacy policy][web-privacy] before using this software.

## Contacts

Twitter: [@keeshux][about-twitter]

Website: [passepartoutvpn.app][web-home] ([FAQ][web-faq])

[appstore]: https://apps.apple.com/us/app/passepartout-vpn-client/id1433648537?mt=8

[openvpn]: https://openvpn.net/index.php/open-source/overview.html
[openvpn-xor-patch]: https://tunnelblick.net/cOpenvpn_xorpatch.html
[wireguard]: https://www.wireguard.com/

[dep-brew]: https://brew.sh/
[dep-openssl]: https://www.openssl.org/

[github-releases]: https://github.com/partout-io/passepartout/releases/latest
[gpg-key]: ci/gpg.txt
[homebrew-cask]: https://github.com/Homebrew/homebrew-cask

[license-content]: LICENSE
[contrib-cla]: CLA.rst
[contrib-readme]: CONTRIBUTING.md

[credits-chatgpt]: https://chatgpt.com/
[credits-fastlane]: https://github.com/fastlane/fastlane
[credits-genericjson]: https://github.com/iwill/generic-json-swift
[credits-swiftgen]: https://github.com/SwiftGen/SwiftGen
[credits-swiftlint]: https://github.com/realm/SwiftLint
[credits-tmthecoder]: https://github.com/tmthecoder
[credits-tmthecoder-xor]: https://github.com/partout-io/tunnelkit/pull/255
[credits-vaygr]: https://github.com/vaygr
[credits-vaygr-cask]: https://github.com/Homebrew/homebrew-cask/pull/214696

[web-home]: https://passepartoutvpn.app
[web-blog]: https://passepartoutvpn.app/blog/
[web-faq]: https://passepartoutvpn.app/faq/
[web-disclaimer]: https://passepartoutvpn.app/disclaimer/
[web-privacy]: https://passepartoutvpn.app/privacy/

[about-twitter]: https://twitter.com/keeshux
[about-github-discussions]: https://github.com/orgs/partout-io/discussions
[about-reddit]: https://www.reddit.com/r/passepartout
[about-testflight]: https://testflight.apple.com/join/dnA4CXFJ
