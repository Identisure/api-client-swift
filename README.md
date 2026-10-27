<img align="left" height="100" style="margin-right: 10px;" src="../img/icon.png">

# Identisure Swift Client

[![Swift Package Manager][spm-image]][spm-url]
[![MIT license][license-image]][license-url]

[spm-image]: https://img.shields.io/badge/SwiftPM-compatible-orange?style=flat-square
[spm-url]: https://swift.org/package-manager
[license-image]: https://img.shields.io/badge/license-MIT-blue?style=flat-square
[license-url]: https://opensource.org/license/mit

API client for the [Identisure](https://developers.identisure.com) REST API.

Supports iOS 15+, macOS 12+, tvOS 15+, watchOS 8+.

## Installation

Add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/identisure/idk-clients.git", from: "0.1.0")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "IdentisureClient", package: "idk-clients")
    ])
]
```

## Usage

```swift
import IdentisureClient

let client = IdentisureClientBuilder(clientId: "client_id", clientSecret: "client_secret")
    .environment(.staging)
    .build()

let session = try await client.bankIdSe.auth(BankIdSeAuthRequest())
if case .pending(let pending) = session {
    print("Session ID: \(pending.id)")

    let result = try await client.bankIdSe.waitForAuth(id: pending.id)
    switch result {
    case .completed(let done):
        print("Authenticated: \(done.name) (\(done.ssn))")
    case .failed(let failed):
        print("Failed: \(failed.error)")
    case .pending, .unknown:
        break
    }
}
```

### Verifying callbacks

Verify the `X-Signature-SHA256` header against the raw request body before parsing it:

```swift
let valid = CallbackSignature.verify(body: rawBody, signature: signatureHeader, secret: "hmac_secret")
```

## Development

### Prerequisites

- Swift 5.9+ (`swift --version`)

### Build / Test

```sh
swift build
swift test
```
