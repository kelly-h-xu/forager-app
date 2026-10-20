import SwiftUI
import PhotosUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()

    @State private var selectedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?

    var body: some View {
        ZStack {

            //  Camera Preview
            if cameraManager.authorizationStatus == .authorized {
                CameraPreview(
                    session: cameraManager.session,
                    cameraManager: cameraManager
                )
                .ignoresSafeArea()
            } else {
                permissionView
            }

            // Bottom Controls
            VStack {
                Spacer()

                HStack {
                    // Photo library (left)
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images
                    ) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    // Shutter (center)
                    Button {
                        cameraManager.capturePhoto()
                    } label: {
                        Circle()
                            .strokeBorder(.white, lineWidth: 3)
                            .frame(width: 70, height: 70)
                            .overlay {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 60, height: 60)
                            }
                    }

                    Spacer()

                    // Switch camera (right)
                    Button {
                        cameraManager.switchCamera()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(
                    Color("CoachGreen")
                        .opacity(0.5)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .onAppear {
            cameraManager.checkAuthorization()
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    pickedImage = image
                }
            }
        }
        .sheet(item: $cameraManager.capturedImage) { image in
            PhotoPreviewView(item: image) {
                cameraManager.capturedImage = nil
            }
        }
        .sheet(item: pickedImageIdentifiable) { image in
            PhotoPreviewView(item: image) {
                pickedImage = nil
            }
        }
    }

    // Helpers
    private var pickedImageIdentifiable: Binding<IdentifiableImage?> {
        Binding(
            get: { pickedImage.map { IdentifiableImage(image: $0) } },
            set: { _ in }
        )
    }

    private var permissionView: some View {
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

//struct PhotoPreviewView: View {
//    let item: IdentifiableImage
//    let onDismiss: () -> Void
//    var body: some View {
//        VStack(spacing: 0) {
//            HStack {
//                Button("Retake") {
//                    onDismiss()
//                }
//                .padding()
//                
//                Spacer()
//                
//                Button("Save") {
//                    UIImageWriteToSavedPhotosAlbum(item.image, nil, nil, nil) //maybe not save to photos
//                    onDismiss()
//                }
//                .padding()
//            }
//            .background(.ultraThinMaterial)
//            
//            Image(uiImage: item.image)
//                .resizable()
//                .scaledToFit()
//            Spacer()
//        }
//    }
//}


struct PhotoPreviewView: View {
    let item: IdentifiableImage
    let onDismiss: () -> Void

    @StateObject private var viewModel = PhotoPreviewViewModel()

    var body: some View {
        ZStack {
            if viewModel.isShowingResult {
                classificationResultView
            } else {
                photoPreviewView
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Photo Preview
    private var photoPreviewView: some View {
        VStack(spacing: 0) {

            topBar(
                leading: "Back",
                leadingAction: onDismiss,
                trailing: "Next",
                trailingAction: {
                    viewModel.isShowingResult = true
                }
            )

            Image(uiImage: item.image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: .infinity)
                .background(Color.black)

            classifyButton
                .padding(.bottom, 30)
        }
    }

    // MARK: - Classification Result
    private var classificationResultView: some View {
        VStack(spacing: 24) {

            topBar(
                leading: "Back",
                leadingAction: {
                    viewModel.isShowingResult = false
                },
                trailing: "Done",
                trailingAction: onDismiss
            )

            Spacer()

            if viewModel.isClassifying {
                ProgressView("Classifying…")
                    .progressViewStyle(.circular)
            } else if let result = viewModel.classificationResult {
                VStack(spacing: 12) {
                    Text(result.label)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Confidence: \(Int(result.confidence * 100))%")
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No classification yet")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Classify Button
    private var classifyButton: some View {
        Button {
            viewModel.classify(image: item.image)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Classify")
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color("CoachGreen"))
            .foregroundStyle(.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .disabled(viewModel.isClassifying)
    }

    // MARK: - Top Bar
    private func topBar(
        leading: String,
        leadingAction: @escaping () -> Void,
        trailing: String,
        trailingAction: @escaping () -> Void
    ) -> some View {
        HStack {
            Button(leading, action: leadingAction)
            Spacer()
            Button(trailing, action: trailingAction)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
