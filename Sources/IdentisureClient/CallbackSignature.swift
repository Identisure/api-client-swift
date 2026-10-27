import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

public enum CallbackSignature {
    /// Verifies the `X-Signature-SHA256` header of a callback request. Pass the raw request body as
    /// received, before parsing it.
    public static func verify(body: Data, signature: String, secret: String) -> Bool {
        guard let mac = Data(base64Encoded: signature) else {
            return false
        }

        let key = SymmetricKey(data: Data(secret.utf8))
        return HMAC<SHA256>.isValidAuthenticationCode(mac, authenticating: body, using: key)
    }
}
