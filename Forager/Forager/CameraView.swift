//
//  CameraView.swift
//  Forager
//
//  Created by Kelly Xu on 2/27/26.
//

import SwiftUI
import AVFoundation
import AVKit

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    var body: some View {
        ZStack {
            // Camera preview fills entire screen
            if cameraManager.authorizationStatus == .authorized {
                CameraPreview(session: cameraManager.session, cameraManager: cameraManager)
                    .ignoresSafeArea()
            }
            else {
                // Permission not granted
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.gray)
                    
                    Text("Camera Access Required")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if cameraManager.authorizationStatus == .denied {
                        Text("Please enable camera access in Settings")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Open Settings") {
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsURL)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .onAppear{
            cameraManager.checkAuthorization()
        }
    }
}


#Preview {
    CameraView()
}
