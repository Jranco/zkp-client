//
//  DeviceBindingView.swift
//  zkp-client
//
//  Created by Thomas Segkoulis on 08.03.24.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

public struct DeviceBindingView: View {

	// MARK: - ViewModel

	@ObservedObject var viewModel: DeviceBindingViewModel

	// MARK: - Initialization

	public init(delegate: DeviceBindingDelegate?, client: ZKPClient) {
		self.viewModel = DeviceBindingViewModel(delegate: delegate, client: client)
	}
	
	// MARK: - Body

	public var body: some View {
		ZStack {
			Text("hellooo")
				.frame(width: 200, height: 120)
				.background(Color.blue)
			switch viewModel.state {
			case .loading:
				ProgressView()
			case .loaded(let serviceID, let characteristicID):
				QRCodeView(serviceID: serviceID, characteristicID: characteristicID)
					.frame(width: 200, height: 200)
					.background(Color.blue)
			case .fail(let error):
				Text("could not load")
			}
		}.onAppear {
			viewModel.start()
		}
	}
}

public struct QRCodeView: View {
	let context = CIContext()
	let filter = CIFilter.qrCodeGenerator()
	let serviceID: String
	let characteristicID: String

	func generateQRCode(from string: String) -> UIImage {
		filter.message = Data(string.utf8)

		if let outputImage = filter.outputImage {
			if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
				return UIImage(cgImage: cgImage)
			}
		}

		return UIImage(systemName: "xmark.circle") ?? UIImage()
	}

	public var body: some View {
		Image(uiImage: generateQRCode(from: "device-binding://?serviceID=\(serviceID)&characteristicID=\(characteristicID)"))
			.interpolation(.none)
			.resizable()
			.scaledToFit()
			.frame(width: 200, height: 200)
	}
}

//private struct QRCodeView: View {
//
//	let authenticatorID: String
//
//	public var body: some View {
////		if let qrCodeImage = generateQRCode(from: "device-binding://?authenticatorID=\(authenticatorID)") {
////		if let qrCodeImage = generateQRCode(from: "hello") {
//			Image(uiImage: generateQRCode(from: "hello")!)
//				.resizable()
//				.interpolation(.none)
//				.scaledToFit()
//				.frame(width: 200, height: 200)
////		} else {
////			Text("Failed to generate QR code")
////		}
//	}
//
//	func generateQRCode(from string: String) -> UIImage? {
//		let data = string.data(using: .utf8)
//		guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
//		filter.setValue(data, forKey: "inputMessage")
//		guard let ciImage = filter.outputImage else { return nil }
//		let transform = CGAffineTransform(scaleX: 10, y: 10)
//		let scaledCIImage = ciImage.transformed(by: transform)
//		return UIImage(ciImage: scaledCIImage)
//	}
//}

//#Preview {
//	DeviceBindingView()
//}
