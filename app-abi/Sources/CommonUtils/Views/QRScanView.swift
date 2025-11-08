// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS)

import AVFoundation
import SwiftUI
import UIKit
import Vision

public struct QRScanView: UIViewControllerRepresentable {
    public final class Coordinator: NSObject {

        @Binding
        private var isAvailable: Bool

        fileprivate init(_ view: QRScanView) {
            _isAvailable = view._isAvailable
        }

        fileprivate func didLoad(withError error: Error?) {
            isAvailable = error == nil
        }
    }

    @Binding
    private var isAvailable: Bool

    private let onLoad: (Error?) -> Void

    private let onDetect: (String) -> Void

    public init(
        isAvailable: Binding<Bool>,
        onLoad: @escaping (Error?) -> Void,
        onDetect: @escaping (String) -> Void
    ) {
        _isAvailable = isAvailable
        self.onLoad = onLoad
        self.onDetect = onDetect
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        let vc = QRScanViewController(
            onLoad: {
                context.coordinator.didLoad(withError: $0)
                onLoad($0)
            },
            onDetect: onDetect
        )
        return vc
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

final class QRScanViewController: UIViewController {
    private struct QRScanError: Error {
    }

    private let queue = DispatchQueue(label: "QRScanViewController")

    private let session = AVCaptureSession()

    private let onLoad: ((Error?) -> Void)?

    private var onDetect: ((String) -> Void)?

    private var didLoad = false

    private var isPaused = false

    required init?(coder: NSCoder) {
        fatalError()
    }

    init(
        onLoad: ((Error?) -> Void)? = nil,
        onDetect: @escaping (String) -> Void
    ) {
        self.onLoad = onLoad
        self.onDetect = onDetect
        super.init(nibName: nil, bundle: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        isPaused = false
        guard !didLoad else {
            return
        }
        didLoad = true

        let input: AVCaptureDeviceInput
        do {
            guard let device = AVCaptureDevice.default(for: .video) else {
                NSLog("QR: Unable to get video device")
                throw QRScanError()
            }
            input = try AVCaptureDeviceInput(device: device)
            session.beginConfiguration()
            session.sessionPreset = .high
            session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: queue)
            session.addOutput(output)

            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            session.commitConfiguration()
            queue.async { [weak self] in
                self?.session.startRunning()
            }
            onLoad?(nil)
        } catch {
            onLoad?(error)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isPaused = true
    }
}

extension QRScanViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            NSLog("QR: Unable to get image buffer")
            return
        }
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            if let error {
                NSLog("QR: Unable to detect: \(error)")
                return
            }
            guard let results = request.results as? [VNBarcodeObservation] else {
                NSLog("QR: Unable to get results as [VNBarcodeObservation]")
                return
            }
            for result in results where result.symbology == .qr {
                guard let payload = result.payloadStringValue else {
                    NSLog("QR: Missing payload")
                    continue
                }
                DispatchQueue.main.sync { [weak self] in
                    guard let self, !isPaused else {
                        return
                    }
                    onDetect?(payload)
                }
            }
        }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            NSLog("QR: Unable to perform image request: \(error)")
        }
    }
}

#Preview {
    QRScanView(
        isAvailable: .constant(true),
        onLoad: { _ in },
        onDetect: { _ in }
    )
}

#endif
