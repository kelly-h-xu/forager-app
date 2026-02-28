//
//  CameraManager.swift
//  Forager
//
//  Created by Kelly Xu on 2/27/26.
//

import AVFoundation
import SwiftUI
import Combine

class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var capturedImage: IdentifiableImage?
    @Published var isSessionRunning = false
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var zoomFactor: CGFloat = 1.0
        private let minZoomFactor: CGFloat = 1.0
        private let maxZoomFactor: CGFloat = 5.0
  
    // AVFoundation components
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    
    // Queue for session configuration (off main thread)
    private let sessionQueue = DispatchQueue(label: "com.customcamera.sessionQueue")
    
    override init() {
        super.init()
    }
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Already authorized, setup session
            authorizationStatus = .authorized
            setupSession()
            
        case .notDetermined:
            // Request permission
            authorizationStatus = .notDetermined
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationStatus = granted ? .authorized : .denied
                    if granted {
                        self?.setupSession()
                    }
                }
            }
            
        case .denied, .restricted:
            authorizationStatus = .denied
            
        @unknown default:
            authorizationStatus = .denied
        }
    }
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Set session preset for quality
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            
            // Add camera input
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                print("Failed to access camera")
                self.session.commitConfiguration()
                return
            }
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.currentInput = input
            }
            
            // Add photo output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                // Configure photo output settings
                self.photoOutput.maxPhotoQualityPrioritization = .quality
            }
            
            self.session.commitConfiguration()
            
            // Start the session
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
    
    func capturePhoto() {
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                
                // Configure photo settings
                let settings = AVCapturePhotoSettings()
                
                // Request photo capture
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                         didFinishProcessingPhoto photo: AVCapturePhoto,
                         error: Error?) {
            
            if let error = error {
                print("Photo capture error: \(error.localizedDescription)")
                return
            }
            
            // Extract image data
            guard let imageData = photo.fileDataRepresentation(),
                  let uiImage = UIImage(data: imageData) else {
                print("Failed to convert photo to image")
                return
            }
            
            // Update UI on main thread
            DispatchQueue.main.async { [weak self] in
                self?.capturedImage = IdentifiableImage(image: uiImage)
            }
        }
    
    func zoom(factor: CGFloat) {
            sessionQueue.async { [weak self] in
                guard let self = self,
                      let device = self.currentInput?.device else { return }
                
                do {
                    try device.lockForConfiguration()
                    
                    // Clamp zoom to device limits
                    let clampedZoom = max(self.minZoomFactor,
                                          min(factor,
                                              min(self.maxZoomFactor, device.activeFormat.videoMaxZoomFactor)))
                    
                    device.videoZoomFactor = clampedZoom
                    
                    DispatchQueue.main.async {
                        self.zoomFactor = clampedZoom
                    }
                    
                    device.unlockForConfiguration()
                } catch {
                    print("Zoom error: \(error.localizedDescription)")
                }
            }
        }
        
}


struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

