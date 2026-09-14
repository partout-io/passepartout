// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

/// Represents a network connection.
public protocol Connection: AnyObject, Sendable {
    /// Publishes the ``ConnectionStatus`` of the connection.
    var statusStream: AsyncThrowingStream<ConnectionStatus, Error> { get }

    /// Starts the connection.
    ///
    /// - Postcondition: The status stream must go through `.connecting` to eventually reach `.connected` (on success), `.disconnected` (on recoverable failure) or `completion: .failure` (on unrecoverable failure).
    /// - Returns: `true` if the connection was started, `false` if status is not `.disconnected`.
    /// - Throws: If the connection could not start.
    @discardableResult
    func start() async throws -> Bool

    /// Stops the connection.
    ///
    /// - Postcondition: Status must be `.disconnected`.
    /// - Parameter timeout: The graceful period. Passing 0 will stop the connection by force.
    func stop(timeout: Int) async
}
