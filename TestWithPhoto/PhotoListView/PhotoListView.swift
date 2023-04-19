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
                .listStyle(.plain)
                .sheet(isPresented: $isCameraShown, onDismiss: {
                    handlePhotoUpload()
                }) {
                    ImagePicker(selectedImage: $viewModel.selectedImage, sourceType: .camera)
                        .background(.black)
                }
                .navigationBarItems(trailing:
                    Button(action: {
                    alertWithSwitch()
                }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                )
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
    
    private func alertWithSwitch() {
        let alert = UIAlertController(title: "Show Photos", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Show All", style: .default, handler: { _ in
            viewModel.selectedPhotoType = .allPhoto
            viewModel.changePhotoType()
        }))
        
        alert.addAction(UIAlertAction(title: "Show With Images", style: .default, handler: { _ in
            viewModel.selectedPhotoType = .withPhoto
            viewModel.changePhotoType()
        }))
        
        alert.addAction(UIAlertAction(title: "Show Without Images", style: .default, handler: { _ in
            viewModel.selectedPhotoType = .withoutPhoto
            viewModel.changePhotoType()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}


// MARK: -- Photo List Row
struct PhotoListRowView: View {
    //MARK: - Properties
    let photoType: PhotoType
    //MARK: - Body
    var body: some View {
        image
        .frame(maxWidth: .infinity)
        .listRowSeparator(.hidden)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    //MARK: - Subviews
    private var image: some View {
        if photoType.image == nil {
            return AnyView(
                VStack(spacing: 10) {
                    missingPictureView
                    photoTypeNameView
                }
            )
        } else {
            return AnyView(
                ZStack(alignment: .bottom) {
                    asyncImageView
                    photoTypeOverlayView
                }
            )
        }
    }
    
    private var missingPictureView: some View {
        Text("The picture is missing. Tap here to take a photo")
            .font(.system(size: 32))
            .multilineTextAlignment(.center)
            .padding(.top, 10)
    }
    
    private var photoTypeNameView: some View {
        Text(photoType.name)
            .font(.system(size: 20))
            .fontWeight(.medium)
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            .background(Color.green.opacity(0.2))
            .foregroundColor(.black)
            .cornerRadius(20)
            .frame(alignment: .bottom)
            .padding(.bottom, 10)
    }
    
    private var asyncImageView: some View {
        AsyncImage(url: photoType.image) { image in
            image.resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ProgressView()
        }
        .frame(width: 300, height: 300)
        .zIndex(0)
    }
    
    private var photoTypeOverlayView: some View {
        Rectangle()
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, maxHeight: 40, alignment: .bottom)
            .opacity(0.6)
            .zIndex(1)
            .overlay {
                Text(photoType.name)
                    .font(.system(size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
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
        imagePickerController.cameraDevice = .rear
        return imagePickerController
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {

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
