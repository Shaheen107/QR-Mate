//
//  ContentView.swift
//  QR-Mate
//
//  Created by Dev Reptech on 22/02/2024.
//

import SwiftUI
import AVFoundation

struct Note {
    let id = UUID()
    var content: String
}
//
//struct ScannerView: UIViewRepresentable {
//    @Binding var scannedCode: String?
//
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView()
//        let captureSession = AVCaptureSession()
//
//        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return view }
//        let videoInput: AVCaptureDeviceInput
//
//        do {
//            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
//        } catch {
//            return view
//        }
//
//        if (captureSession.canAddInput(videoInput)) {
//            captureSession.addInput(videoInput)
//        } else {
//            return view
//        }
//
//        let metadataOutput = AVCaptureMetadataOutput()
//
//        if (captureSession.canAddOutput(metadataOutput)) {
//            captureSession.addOutput(metadataOutput)
//
//            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
//            metadataOutput.metadataObjectTypes = [.qr]
//        } else {
//            return view
//        }
//
//        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        previewLayer.frame = view.layer.bounds
//        previewLayer.videoGravity = .resizeAspectFill
//        view.layer.addSublayer(previewLayer)
//
//        captureSession.startRunning()
//
//        return view
//    }
//
//    func updateUIView(_ uiView: UIView, context: Context) {}
//
//    func makeCoordinator() -> Coordinator {
//        return Coordinator(parent: self)
//    }
//
//    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
//        var parent: ScannerView
//
//        init(parent: ScannerView) {
//            self.parent = parent
//        }
//
//        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
//            if let metadataObject = metadataObjects.first {
//                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
//                guard let stringValue = readableObject.stringValue else { return }
//                parent.scannedCode = stringValue
//            }
//        }
//    }
//}


struct QRScannerView: UIViewControllerRepresentable {
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRScannerView

        init(parent: QRScannerView) {
            self.parent = parent
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                parent.didFindCode(stringValue)
            }
        }
    }

    var didFindCode: (String) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return viewController }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return viewController
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return viewController
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return viewController
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)

        captureSession.startRunning()

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}



struct ContentView: View {
    @State private var notes: [Note] = []
    @State private var isAddingNote = false
    @State private var newNoteText = ""
    @State private var isDarkMode = false
    @State private var isScannerActive = false
    @State private var scannedCode: String?

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                List {
                    ForEach(notes, id: \.id) { note in
                        HStack {
                            Image(systemName: "circle.fill")
                            Text(note.content)
                        }
                    }
                    .onDelete(perform: deleteNotes)
                }
                .navigationTitle("Your QR-Buddy Scan")
                .navigationBarItems(leading: Button(action: {
                    isDarkMode.toggle()
                }) {
                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .font(.title)
                        .padding()
                }, trailing:
                Button(action: {
                    self.isAddingNote.toggle()
                }) {
                    Image(systemName: "plus")
                })
                .padding()

                VStack {
                    Text("Now you can scan QR Code to get wifi Password and other stuff.")
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()

                    Text("Please tap the button below to scan your code.")
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Button(action: {
                    self.isScannerActive.toggle() // Toggle scanner activation
                }) {
                    Text("Scan QR Code")
                        .fontWeight(.semibold)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 50) // Ensure some spacing at the bottom
            }
            .sheet(isPresented: $isScannerActive, content: {
                VStack {
                    if let scannedCode = scannedCode {
                        QRResultView(code: scannedCode)
                    } else {
                        // QR Scanner View
                        QRScannerView { code in
                            self.scannedCode = code
                        }
                    }
                }
            })
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $isAddingNote, content: {
            AddNoteView(isAddingNote: $isAddingNote, newNoteText: $newNoteText, notes: $notes)
        })
    }

    func deleteNotes(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
    }
}


struct AddNoteView: View {
    @Binding var isAddingNote: Bool
    @Binding var newNoteText: String
    @Binding var notes: [Note]

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    self.isAddingNote.toggle()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .padding()
                        .foregroundColor(.blue)
                }
            }

            TextField("Enter your note", text: $newNoteText)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)

            Button("Add") {
                if !newNoteText.isEmpty {
                    notes.append(Note(content: newNoteText))
                    newNoteText = ""
                    isAddingNote.toggle()
                }
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(10)
            .padding(.top, 10)
            .padding(.horizontal)
        }
    }
}




struct QRResultView: View {
    let code: String

    var body: some View {
        VStack {
            Text("Scanned QR Code:")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            Text(code)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.blue) // Change the color as needed
                .padding()
        }
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
