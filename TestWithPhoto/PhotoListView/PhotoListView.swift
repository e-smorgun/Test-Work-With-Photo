//
//  PhotoListView.swift
//  TestWithPhoto
//
//  Created by Evgeny on 14.04.23.
//


import Foundation
import SwiftUI

// MARK: -- Photo List View
struct PhotoListView: View {
    //MARK: - Properties
    @StateObject private var viewModel = PhotoListViewModel()
    @State private var isCameraShown = false
    @State private var selectedPhotoType: PhotoType?
    
    // MARK: - Body
    var body: some View {
        let networkChecker = isConnectToNetwork()
        if !networkChecker.hasInternetConnection() {
            Text("No Internet Connection")
        } else {
            NavigationView {
                List {
                    ForEach(viewModel.photoTypes) { photoType in
                        PhotoListRowView(photoType: photoType)
                            .onTapGesture {
                                isCameraShown = true
                                selectedPhotoType = photoType
                            }
                    }
                    if viewModel.photoTypes.count > 0 && viewModel.currentPage < 6 {
                        Color.clear
                            .onAppear {
                                viewModel.fetchPhotoTypes()
                            }
                    }
                }
                .listStyle(PlainListStyle())
                .sheet(isPresented: $isCameraShown, onDismiss: {
                    handlePhotoUpload()
                }) {
                    ImagePicker(selectedImage: $viewModel.selectedImage, sourceType: .camera)
                        .background(.black)
                }
                .navigationTitle("Photo Types")
            }
            .onAppear {
                viewModel.fetchPhotoTypes()
            }
        }
    }
    
    // MARK: - Methods
    private func handlePhotoUpload() {
        if let photoType = selectedPhotoType,
           let image = viewModel.selectedImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            // MARK: Отправляем POST-запрос
            viewModel.uploadPhoto(photoType: photoType, imageData: imageData, developerName: "My Name") { id, error in
                DispatchQueue.main.async {
                    if let error = error {
                        let alert = UIAlertController(title: "Error", message: "Failed to upload photo with error: \(error)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                    } else if let id = id {
                        let alert = UIAlertController(title: "Successful", message: "Successfully uploaded photo with id: \(id)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
        viewModel.selectedImage = nil
    }
}

// MARK: -- Photo List Row
struct PhotoListRowView: View {
    //MARK: - Properties
    let photoType: PhotoType
    
    //MARK: - Body
    var body: some View {
        HStack {
            image
            Text(photoType.name)
        }
    }
    
    //MARK: - Subviews
    private var image: some View {
        if photoType.image == nil {
            return AnyView(
                Rectangle()
                    .background(.gray)
                    .foregroundColor(.gray)
                    .frame(width: 50, height: 50)
            )
        } else {
            return AnyView(
                AsyncImage(url: photoType.image) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                    .frame(width: 70, height: 70)
            )
        }
    }
}

//MARK: -- Work with Photo
struct ImagePicker: UIViewControllerRepresentable {
    //MARK: - Properties
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType
    
    //MARK: - Methods
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = sourceType
        imagePickerController.delegate = context.coordinator
        return imagePickerController
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
        // Do nothing
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

//MARK: -- Preview
struct PhotoListView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoListView()
    }
}
