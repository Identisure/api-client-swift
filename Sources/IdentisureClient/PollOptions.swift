import Foundation

public struct PollOptions: Sendable {
    public var interval: TimeInterval
    public var timeout: TimeInterval

    public init(interval: TimeInterval = 2, timeout: TimeInterval = 300) {
        self.interval = interval
        self.timeout = timeout
    }
}
