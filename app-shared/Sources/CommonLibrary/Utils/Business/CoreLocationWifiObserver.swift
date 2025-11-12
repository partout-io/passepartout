// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CoreLocation
import Foundation

public actor CoreLocationWifiObserver: NSObject, WifiObserver {
    private let locationManager = CLLocationManager()

    private var pendingTask: Task<String, Error>?

    private var continuation: CheckedContinuation<String, Error>?

    public func currentSSID() async throws -> String {
#if os(macOS)
        ""
#else
        if let pendingTask {
            return try await pendingTask.value
        }
        let pendingTask = Task {
            switch locationManager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse, .denied:
                return await currentSSIDWithoutAuthorization()

            default:
                return try await withCheckedThrowingContinuation { continuation in
                    self.continuation = continuation

                    locationManager.delegate = self
                    locationManager.requestWhenInUseAuthorization()
                }
            }
        }
        self.pendingTask = pendingTask
        let result = try await pendingTask.value
        self.pendingTask = nil
        continuation = nil
        return result
#endif
    }

    private func currentSSIDWithoutAuthorization() async -> String {
        await Utils.currentWifiSSID() ?? ""
    }
}

extension CoreLocationWifiObserver: CLLocationManagerDelegate {
    public nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task {
            let ssid = await currentSSIDWithoutAuthorization()
            await continuation?.resume(returning: ssid)
        }
    }

    public nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task {
            await continuation?.resume(throwing: error)
        }
    }
}
