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
