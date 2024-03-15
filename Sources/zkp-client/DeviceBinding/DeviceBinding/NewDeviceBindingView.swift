////
////  NewDeviceBindingView.swift
////  zkp-client
////
////  Created by Thomas Segkoulis on 06.03.24.
////
//
//import SwiftUI
//import Foundation
//import UIKit
//
//class NewDeviceBinding {
//}
//
//public struct QRCodeView: View {
//
//	public init() {}
//
//	public var body: some View {
//		if let qrCodeImage = generateQRCode(from: "Your QR Code Content") {
//			Image(uiImage: qrCodeImage)
//				.resizable()
//				.interpolation(.none)
//				.scaledToFit()
//				.frame(width: 200, height: 200)
//		} else {
//			Text("Failed to generate QR code")
//		}
//	}
//
//	func generateQRCode(from string: String) -> UIImage? {
//		let data = string.data(using: String.Encoding.ascii)
//		guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
//		filter.setValue(data, forKey: "inputMessage")
//		guard let ciImage = filter.outputImage else { return nil }
//		let transform = CGAffineTransform(scaleX: 10, y: 10)
//		let scaledCIImage = ciImage.transformed(by: transform)
//		return UIImage(ciImage: scaledCIImage)
//	}
//}
//
//struct ContentView_Previews: PreviewProvider {
//	static var previews: some View {
//		QRCodeView()
//	}
//}
