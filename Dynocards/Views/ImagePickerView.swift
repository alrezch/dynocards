//
//  ImagePickerView.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI
import PhotosUI

// Improved version with better button layout
@available(iOS 16.0, *)
struct ImprovedImagePickerView: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var showingCamera = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Selected Image Preview
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                    .shadow(radius: 10)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.gray)
                }
            }
            
            // Action Buttons - Stacked Vertically
            VStack(spacing: 12) {
                // Choose Photo Button
                Button(action: {
                    showingActionSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18))
                        Text("Choose Photo")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                
                // Remove Photo Button (only if image exists)
                if selectedImage != nil {
                    Button(action: {
                        selectedImage = nil
                        selectedItem = nil
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                            Text("Remove Photo")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedItem, matching: .images)
        .sheet(isPresented: $showingCamera) {
            CameraPickerView(selectedImage: $selectedImage)
        }
        .confirmationDialog("Choose Photo", isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button("Photo Library") {
                showingImagePicker = true
            }
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera") {
                    showingCamera = true
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                    }
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct ImagePickerView: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var showingCamera = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Selected Image Preview
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                    .shadow(radius: 10)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.gray)
                }
            }
            
            // Action Buttons - Stacked Vertically
            VStack(spacing: 12) {
                // Choose Photo Button
                Button(action: {
                    showingActionSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18))
                        Text("Choose Photo")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                
                // Remove Photo Button (only if image exists)
                if selectedImage != nil {
                    Button(action: {
                        selectedImage = nil
                        selectedItem = nil
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                            Text("Remove Photo")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedItem, matching: .images)
        .sheet(isPresented: $showingCamera) {
            CameraPickerView(selectedImage: $selectedImage)
        }
        .confirmationDialog("Choose Photo", isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button("Photo Library") {
                showingImagePicker = true
            }
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera") {
                    showingCamera = true
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                    }
                }
            }
        }
    }
}

// Improved legacy version with better button layout
struct ImprovedLegacyImagePickerView: View {
    @Binding var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        VStack(spacing: 20) {
            // Selected Image Preview
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                    .shadow(radius: 10)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.gray)
                }
            }
            
            // Action Buttons - Stacked Vertically
            VStack(spacing: 12) {
                // Choose Photo Button
                Button(action: {
                    showingActionSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18))
                        Text("Choose Photo")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                
                // Remove Photo Button (only if image exists)
                if selectedImage != nil {
                    Button(action: {
                        selectedImage = nil
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                            Text("Remove Photo")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showingImagePicker) {
            UIImagePickerView(sourceType: sourceType, selectedImage: $selectedImage)
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(title: Text("Choose Photo"), buttons: [
                .default(Text("Photo Library")) {
                    sourceType = .photoLibrary
                    showingImagePicker = true
                },
                UIImagePickerController.isSourceTypeAvailable(.camera) ? .default(Text("Camera")) {
                    sourceType = .camera
                    showingImagePicker = true
                } : nil,
                .cancel()
            ].compactMap { $0 })
        }
    }
}

// Fallback for iOS < 16.0
struct LegacyImagePickerView: View {
    @Binding var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        VStack(spacing: 20) {
            // Selected Image Preview
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                    .shadow(radius: 10)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.gray)
                }
            }
            
            // Action Buttons - Stacked Vertically
            VStack(spacing: 12) {
                // Choose Photo Button
                Button(action: {
                    showingActionSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 18))
                        Text("Choose Photo")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                
                // Remove Photo Button (only if image exists)
                if selectedImage != nil {
                    Button(action: {
                        selectedImage = nil
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                            Text("Remove Photo")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showingImagePicker) {
            UIImagePickerView(sourceType: sourceType, selectedImage: $selectedImage)
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(title: Text("Choose Photo"), buttons: [
                .default(Text("Photo Library")) {
                    sourceType = .photoLibrary
                    showingImagePicker = true
                },
                UIImagePickerController.isSourceTypeAvailable(.camera) ? .default(Text("Camera")) {
                    sourceType = .camera
                    showingImagePicker = true
                } : nil,
                .cancel()
            ].compactMap { $0 })
        }
    }
}

// Camera Picker View
struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        
        init(_ parent: CameraPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// UIImagePickerController wrapper for iOS < 16
struct UIImagePickerView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: UIImagePickerView
        
        init(_ parent: UIImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

